`include "typedef.svh"

module top_BF16 #(
    parameter int MATRIX_SIZE = 2
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic relu_enable,

    input  logic [15:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    input  logic [15:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],

    output logic [31:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic done,
    output logic store_done,
    output state_t state
);
    localparam int BF16_SIZE = 16;
    localparam int FP32_SIZE = 32;

    logic valid;
    logic clear;
    logic load_enable;
    logic feed_enable;
    logic store_enable;
    logic relu_enable_latched;

    logic signed [BF16_SIZE-1:0] buffered_A [0:MATRIX_SIZE-1];
    logic signed [BF16_SIZE-1:0] buffered_B [0:MATRIX_SIZE-1];
    logic signed [FP32_SIZE-1:0] acc_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [FP32_SIZE-1:0] activated_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Keep the selected activation mode stable for the entire operation.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            relu_enable_latched <= 1'b0;
        end else if (load_enable) begin
            relu_enable_latched <= relu_enable;
        end
    end

    controller #(
        .MATRIX_SIZE(MATRIX_SIZE)
    ) controller_unit (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid(valid),
        .clear(clear),
        .load_enable(load_enable),
        .feed_enable(feed_enable),
        .store_enable(store_enable),
        .done(done),
        .state(state)
    );

    Input_Buffers #(
        .DATA_SIZE(BF16_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) input_buffers_unit (
        .clk(clk),
        .rst_n(rst_n),
        .load_enable(load_enable),
        .feed_enable(feed_enable),
        .input_A(input_A),
        .input_B(input_B),
        .output_A(buffered_A),
        .output_B(buffered_B)
    );

    Systolic_Array_BF16 #(
        .MATRIX_SIZE(MATRIX_SIZE)
    ) systolic_array_unit (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .clear(clear),
        .input_A(buffered_A),
        .input_B(buffered_B),
        .output_C(acc_matrix)
    );

    ReLU #(
        .ACC_SIZE(FP32_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) relu_unit (
        .relu_enable(relu_enable_latched),
        .input_C(acc_matrix),
        .output_C(activated_matrix)
    );

    MemoryBank #(
        .ACC_SIZE(FP32_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) output_memory_unit (
        .clk(clk),
        .rst_n(rst_n),
        .store_enable(store_enable),
        .acc_matrix(activated_matrix),
        .stored_matrix(output_C),
        .store_done(store_done)
    );
endmodule
