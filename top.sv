`include "typedef.svh"

module top #(
    parameter DATA_SIZE = 8,   // Integer size
    parameter ACC_SIZE = 32,   // Accumulator size
    parameter MATRIX_SIZE = 2   // Size of the systolic array (2x2) -> Can seperate into L x W later
)(
    input logic clk,
    input logic rst_n,
    input logic start,

    input logic [DATA_SIZE-1:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    input logic [DATA_SIZE-1:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],

    output logic [ACC_SIZE-1:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic done,
    output logic store_done,
    output state_t state
);
    logic valid;
    logic clear;
    logic load_enable;
    logic feed_enable;
    logic store_enable;

    logic [DATA_SIZE-1:0] buffered_A [0:MATRIX_SIZE-1];
    logic [DATA_SIZE-1:0] buffered_B [0:MATRIX_SIZE-1];
    logic [ACC_SIZE-1:0] acc_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // The controller selects the LOAD, COMPUTE, STORE, and DONE phases.
    controller #(
        .MATRIX_SIZE(MATRIX_SIZE)
    ) controller_unit (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        // Outputs to control the Input_Buffers, Systolic_Array, and MemoryBank
        .valid(valid),
        .clear(clear),
        .load_enable(load_enable),
        .feed_enable(feed_enable),
        .store_enable(store_enable),
        .done(done),
        .state(state)
    );

    // Store both input matrices, then generate the skewed edge vectors.
    Input_Buffers #(
        .DATA_SIZE(DATA_SIZE),
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

    // Multiply and accumulate the skewed A/B values.
    Systolic_Array #(
        .DATA_SIZE(DATA_SIZE),
        .ACC_SIZE(ACC_SIZE),
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

    // Preserve the completed accumulator matrix one row per STORE cycle.
    MemoryBank #(
        .ACC_SIZE(ACC_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) output_memory_unit (
        .clk(clk),
        .rst_n(rst_n),
        .store_enable(store_enable),
        .acc_matrix(acc_matrix),
        .stored_matrix(output_C),
        .store_done(store_done)
    );
endmodule
