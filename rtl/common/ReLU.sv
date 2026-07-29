module ReLU #(
    parameter ACC_SIZE = 32,
    parameter MATRIX_SIZE = 2
)(
    input logic relu_enable,
    input logic signed [ACC_SIZE-1:0] input_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic signed [ACC_SIZE-1:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1]
);
    // ReLU(x) = max(0, x). When disabled, this stage passes values through.
    always_comb begin
        for (int row = 0; row < MATRIX_SIZE; row++) begin
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                if (relu_enable && input_C[row][col][ACC_SIZE-1]) begin
                    output_C[row][col] = '0;
                end else begin
                    output_C[row][col] = input_C[row][col];
                end
            end
        end
    end
endmodule
