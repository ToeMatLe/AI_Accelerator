module bf16_multiplier (
    input  logic [15:0] input_A, // BF16 input
    input  logic [15:0] input_B, // BF16 input
    output logic [31:0] product  // FP32 product
);
    import bf16_pkg::*;

    // 1 bit sign, 8 bits exponent, 7 bits mantissa for BF16
    logic sign_result;
    logic [7:0] exponent_A;
    logic [7:0] exponent_B;
    // 1 implicit leading bit + 7 stored fraction bits
    logic [7:0] mantissa_A; 
    logic [7:0] mantissa_B; 
    logic [15:0] mantissa_product;
    logic [23:0] normalized_significand;

    logic [23:0] subnormal_value;
    logic [23:0] subnormal_rounded;
    logic guard_bit;
    logic sticky_bit;
    integer exponent_result;
    integer subnormal_shift;
    integer index;

    // BF16 is sign/exponent/fraction = 1/8/7
    // The product is expanded to FP32 so it can be accumulated without immediately losing bits
    always_comb begin
        product = FP32_POS_ZERO;
        sign_result = input_A[15] ^ input_B[15]; //XOR the sign bits

        exponent_A = input_A[14:7];
        exponent_A_unbiased = 0;
        mantissa_A = 8'b0;

        exponent_B = input_B[14:7];
        exponent_B_unbiased = 0;
        mantissa_B = 8'b0;

        // FP32 is sign/exponent/fraction = 1/8/23
        mantissa_product = 16'b0;
        normalized_significand = 24'b0;
        subnormal_value = 24'b0;
        subnormal_rounded = 24'b0;
        guard_bit = 1'b0;
        sticky_bit = 1'b0;
        
        exponent_result = 0;
        subnormal_shift = 0;

        // Special Floating Point Encodings
        if (bf16_is_nan(input_A) || bf16_is_nan(input_B)) begin 
            product = FP32_QNAN;
        end else if ((bf16_is_inf(input_A) && (exponent_B == 8'b0)) || (bf16_is_inf(input_B) && (exponent_A == 8'b0))) begin
            product = FP32_QNAN;
        end else if (bf16_is_inf(input_A) || bf16_is_inf(input_B)) begin
            product = {sign_result, FP32_POS_INF[30:0]};
        end else if ((exponent_A == 8'b0) || (exponent_B == 8'b0)) begin
            // TPU-style behavior: zero and BF16 subnormal operands are flushed to signed zero before multiplication.
            product = {sign_result, 31'b0};
        end else begin
            
            mantissa_A = {1'b1, input_A[6:0]};
            mantissa_B = {1'b1, input_B[6:0]};

            mantissa_product = mantissa_A * mantissa_B;
            exponent_result = integer'(exponent_A) + integer'(exponent_B) - 127;

            // Range [1, 4) -> [1,2)
            // Shift products >= 2 right once and increase the exponent
            if (mantissa_product[15]) begin
                normalized_significand = {1'b1, mantissa_product[14:0], 8'b0};
                exponent_result = exponent_result + 1;
            end else begin
                normalized_significand = {1'b1, mantissa_product[13:0], 9'b0};
            end
            
            if (exponent_result >= 255) begin
                // Overflow -> Infinity
                product = {sign_result, FP32_POS_INF[30:0]};
            end else if (exponent_result > 0) begin
                // FP32 Result
                product = {sign_result, exponent_result[7:0], normalized_significand[22:0]};
            end else begin
                // Produce an FP32 subnormal and round it to nearest, ties-even.
                // exponent_result <= 0
                subnormal_shift = 1 - exponent_result;
                if (subnormal_shift <= 24) begin
                    subnormal_value = normalized_significand >> subnormal_shift;
                    guard_bit = normalized_significand[subnormal_shift-1];
                    sticky_bit = 1'b0; // Exactly half?
                    for (index = 0; index < 24; index = index + 1) begin
                        if (index < (subnormal_shift - 1)) begin
                            sticky_bit = sticky_bit | normalized_significand[index];
                        end
                    end
                    // Tie to even to prevent upward bias
                    subnormal_rounded = subnormal_value + (guard_bit && (sticky_bit || subnormal_value[0]));

                    // Rounding can promote the largest subnormal or smallest FP32 number 
                    if (subnormal_rounded[23]) begin
                        product = {sign_result, 8'h01, 23'b0};
                    end else begin
                        product = {sign_result, 8'h00, subnormal_rounded[22:0]};
                    end
                end else begin
                    // Too small
                    product = {sign_result, 31'b0};
                end
            end
        end
    end
endmodule
