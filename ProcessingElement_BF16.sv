module ProcessingElement_BF16 (
    input  logic clk,
    input  logic rst_n,
    input  logic valid,
    input  logic clear,
    input  logic [15:0] input_A,
    input  logic [15:0] input_B,
    output logic [15:0] output_A,
    output logic [15:0] output_B,
    output logic [31:0] acc_out
);
    import bf16_pkg::*;
    logic [31:0] accumulator_next;

    bf16_mac mac_unit (
        .input_A(input_A),
        .input_B(input_B),
        .accumulator_in(acc_out),
        .accumulator_next(accumulator_next)
    );

    // Each valid cycle performs one BF16 multiply/FP32 accumulate and moves
    // A right and B down by one processing element.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_out <= FP32_POS_ZERO;
            output_A <= BF16_POS_ZERO;
            output_B <= BF16_POS_ZERO;
        end else if (clear) begin
            acc_out <= FP32_POS_ZERO;
            output_A <= BF16_POS_ZERO;
            output_B <= BF16_POS_ZERO;
        end else if (valid) begin
            acc_out <= accumulator_next;
            output_A <= input_A;
            output_B <= input_B;
        end
    end
endmodule
