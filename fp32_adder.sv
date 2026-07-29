/*
1. Extract sign, exponent, mantissa
2. Handle special cases: NaN, infinity, zero
3. Pick the larger-magnitude operand
4. Align the smaller operand's mantissa
5. Add or subtract significands
6. Normalize result
7. Round to nearest, ties-even
8. Pack sign/exponent/fraction back into FP32
*/
module fp32_adder (
    input  logic [31:0] input_A,
    input  logic [31:0] input_B,
    output logic [31:0] sum
);
    import bf16_pkg::*;

    logic sign_A;
    logic sign_B;
    logic sign_large;
    logic sign_result;
    logic [7:0] exponent_A;
    logic [7:0] exponent_B;
    logic [7:0] exponent_large;
    logic [7:0] exponent_small;
    logic [23:0] mantissa_A;
    logic [23:0] mantissa_B;

    logic [23:0] mantissa_large;
    logic [23:0] mantissa_small;
    logic [26:0] significand_large;
    logic [26:0] significand_small;
    logic [26:0] significand_aligned;
    logic [27:0] significand_result;
    logic [26:0] normalized_result;
    logic [23:0] rounded_mantissa;
    logic [24:0] rounding_result;
    logic round_increment;
    integer exponent_result;
    integer exponent_difference;
    integer normalize_index;

    function automatic logic [26:0] shift_right_jam(
        input logic [26:0] value,
        input integer shift_amount
    );
        logic [26:0] shifted;
        logic sticky;
        integer bit_index;
        begin
            shifted = 27'b0;
            sticky = 1'b0;
            if (shift_amount <= 0) begin
                shifted = value;
            end else if (shift_amount >= 27) begin
                shifted[0] = |value; // reduction OR
            end else begin
                shifted = value >> shift_amount;
                for (bit_index = 0; bit_index < 27; bit_index = bit_index + 1) begin
                    if (bit_index < shift_amount) begin
                        sticky = sticky | value[bit_index];
                    end
                end
                shifted[0] = shifted[0] | sticky;
            end
            return shifted;
        end
    endfunction

    // Combinational IEEE-754 FP32 addition with round-to-nearest, ties-even.
    // The extra three low bits are guard, round, and sticky bits.
    always_comb begin
        sum = FP32_POS_ZERO;
        sign_A = input_A[31];
        sign_B = input_B[31];
        exponent_A = input_A[30:23];
        exponent_B = input_B[30:23];
        // 0 if exponent is zero
        mantissa_A = {(exponent_A != 0), input_A[22:0]};
        mantissa_B = {(exponent_B != 0), input_B[22:0]};

        sign_large = 1'b0;
        sign_result = 1'b0;
        exponent_large = 8'b0;
        exponent_small = 8'b0;
        mantissa_large = 24'b0;
        mantissa_small = 24'b0;
        significand_large = 27'b0;
        significand_small = 27'b0;
        significand_aligned = 27'b0;
        significand_result = 28'b0;
        normalized_result = 27'b0;
        rounded_mantissa = 24'b0;
        rounding_result = 25'b0;
        round_increment = 1'b0;
        exponent_result = 0;
        exponent_difference = 0;

        if (fp32_is_nan(input_A) || fp32_is_nan(input_B)) begin
            sum = FP32_QNAN;
        end else if (fp32_is_inf(input_A) && fp32_is_inf(input_B) && (sign_A != sign_B)) begin
            sum = FP32_QNAN;
        end else if (fp32_is_inf(input_A)) begin
            sum = {sign_A, FP32_POS_INF[30:0]};
        end else if (fp32_is_inf(input_B)) begin
            sum = {sign_B, FP32_POS_INF[30:0]};
        end else if (fp32_is_zero(input_A) && fp32_is_zero(input_B)) begin
            sum = {sign_A & sign_B, 31'b0};
        end else if (fp32_is_zero(input_A)) begin
            sum = input_B;
        end else if (fp32_is_zero(input_B)) begin
            sum = input_A;
        end else begin
            // Subnormal numbers use an effective exponent of one during alignment even though their encoded exponent is zero.
            if ({(exponent_A == 0) ? 8'h01 : exponent_A, mantissa_A} >= {(exponent_B == 0) ? 8'h01 : exponent_B, mantissa_B}) begin
                exponent_large = (exponent_A == 0) ? 8'h01 : exponent_A;
                exponent_small = (exponent_B == 0) ? 8'h01 : exponent_B;
                mantissa_large = mantissa_A;
                mantissa_small = mantissa_B;
                sign_large = sign_A;
            end else begin
                exponent_large = (exponent_B == 0) ? 8'h01 : exponent_B;
                exponent_small = (exponent_A == 0) ? 8'h01 : exponent_A;
                mantissa_large = mantissa_B;
                mantissa_small = mantissa_A;
                sign_large = sign_B;
            end

            sign_result = sign_large;
            exponent_result = integer'(exponent_large);
            exponent_difference = integer'(exponent_large) - integer'(exponent_small);
            significand_large = {mantissa_large, 3'b000};
            significand_small = {mantissa_small, 3'b000};
            significand_aligned = shift_right_jam(significand_small, exponent_difference);

            if (sign_A == sign_B) begin
                significand_result = {1'b0, significand_large} + {1'b0, significand_aligned};
                if (significand_result[27]) begin
                    normalized_result = significand_result[27:1];
                    normalized_result[0] = normalized_result[0] | significand_result[0];
                    exponent_result = exponent_result + 1;
                end else begin
                    normalized_result = significand_result[26:0];
                end
            end else begin
                significand_result = {1'b0, significand_large} - {1'b0, significand_aligned};
                normalized_result = significand_result[26:0];

                // Cancellation moves the leading one left. This bounded loop synthesizes as a priority-normalization network.
                for (normalize_index = 0; normalize_index < 26; normalize_index = normalize_index + 1) begin
                    if (!normalized_result[26] && (normalized_result != 0) && (exponent_result > 1)) begin
                        normalized_result = normalized_result << 1;
                        exponent_result = exponent_result - 1;
                    end
                end
            end

            if (normalized_result == 0) begin
                sum = FP32_POS_ZERO;
            end else begin
                rounded_mantissa = normalized_result[26:3];
                round_increment = normalized_result[2] && (normalized_result[1] || normalized_result[0] || rounded_mantissa[0]);
                rounding_result = {1'b0, rounded_mantissa} + round_increment;

                if (rounding_result[24]) begin
                    rounded_mantissa = rounding_result[24:1];
                    exponent_result = exponent_result + 1;
                end else begin
                    rounded_mantissa = rounding_result[23:0];
                end

                if (exponent_result >= 255) begin
                    sum = {sign_result, FP32_POS_INF[30:0]};
                end else if ((exponent_result == 1) && !rounded_mantissa[23]) begin
                    sum = {sign_result, 8'h00, rounded_mantissa[22:0]};
                end else begin
                    sum = {sign_result, exponent_result[7:0], rounded_mantissa[22:0]};
                end
            end
        end
    end
endmodule
