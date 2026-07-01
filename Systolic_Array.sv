module Systoic_Array #(
    parameter DATA_SIZE = 8,   // Integer size
    parameter ACC_SIZE = 32,   // Accumulator size
    parameter MATRIX_SIZE = 2,   // Size of the systolic array (2x2) -> Can seperate into L x W later
    )(
    input logic clk,
    input logic rst_n,

    input logic [DATA_SIZE-1:0] input_A [0:MATRIX_SIZE-1], // Input vector A (Column) 
    input logic [DATA_SIZE-1:0] input_B [0:MATRIX_SIZE-1], // Input vector B (Row)

    output logic [ACC_SIZE-1:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1] // Output Matrix C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1] (OUTPUT)
);

logic [DATA_SIZE-1:0] top_wire [0:MATRIX_SIZE][0:MATRIX_SIZE-1];  // Wiring mesh to shift right
logic [DATA_SIZE-1:0] left_wire [0:MATRIX_SIZE-1][0:MATRIX_SIZE]; // Wiring mesh to shift down
assign top_wire[0] = input_B; // Connect input_B to the top row of the systolic array
for (genvar i = 0; i < MATRIX_SIZE; i++) begin
    assign left_wire[i][0] = input_A[i]; // Connect input_A to the left column of the systolic array
end
generate
    for (genvar i = 0; i < MATRIX_SIZE; i++) begin : row_loop
        for (genvar j = 0; j < MATRIX_SIZE; j++) begin : col_loop
            ProcessingElement #(
                .DATA_SIZE(DATA_SIZE),
                .ACC_SIZE(ACC_SIZE)
            ) pe_unit (
                .clk(clk),
                .rst_n(rst_n),
                .valid(valid),
                .clear(clear),

                .input_A(left_wire[i][j]),
                .input_B(top_wire[i][j]),

                // Shifts in systolic array
                .output_A(left_wire[i][j+1]),    
                .output_B(top_wire[i+1][j]),
                // Accumulated output connected to output_C
                .acc_out(output_C[i][j])        
            );
        end
    end
endgenerate 
endmodule