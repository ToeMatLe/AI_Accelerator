module bf16_mac (
    input  logic [15:0] input_A,
    input  logic [15:0] input_B,
    input  logic [31:0] accumulator_in,
    output logic [31:0] accumulator_next
);
    logic [31:0] product_fp32;

    bf16_multiplier multiplier_unit (
        .input_A(input_A),
        .input_B(input_B),
        .product(product_fp32)
    );

    fp32_adder adder_unit (
        .input_A(accumulator_in),
        .input_B(product_fp32),
        .sum(accumulator_next)
    );
endmodule
