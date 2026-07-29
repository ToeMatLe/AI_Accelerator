module Systolic_Array_BF16 #(
    parameter int MATRIX_SIZE = 2
)(
    input  logic clk,
    input  logic rst_n,
    input  logic valid,
    input  logic clear,
    input  logic [15:0] input_A [0:MATRIX_SIZE-1],
    input  logic [15:0] input_B [0:MATRIX_SIZE-1],
    output logic [31:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1]
);
    logic [15:0] top_wire [0:MATRIX_SIZE][0:MATRIX_SIZE-1];
    logic [15:0] left_wire [0:MATRIX_SIZE-1][0:MATRIX_SIZE];
    assign top_wire[0] = input_B; // Connect input_B to the top row of the systolic array
    for (genvar i = 0; i < MATRIX_SIZE; i++) begin : input_a_connections
        assign left_wire[i][0] = input_A[i]; // Connect input_A to the left column of the systolic array
    end

    generate
        for (genvar i = 0; i < MATRIX_SIZE; i++) begin : row_loop
            for (genvar j = 0; j < MATRIX_SIZE; j++) begin : col_loop
                ProcessingElement_BF16 pe_unit (
                    .clk(clk),
                    .rst_n(rst_n),
                    .valid(valid),
                    .clear(clear),
                    .input_A(left_wire[i][j]),
                    .input_B(top_wire[i][j]),
                    .output_A(left_wire[i][j+1]),
                    .output_B(top_wire[i+1][j]),
                    .acc_out(output_C[i][j])
                );
            end
        end
    endgenerate
endmodule
