module MemoryBank #(
    parameter ACC_SIZE = 32,
    parameter MATRIX_SIZE = 2
)(
    input logic clk,
    input logic rst_n,
    input logic store_enable,

    input logic [ACC_SIZE-1:0] acc_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic [ACC_SIZE-1:0] stored_matrix [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    output logic store_done
);
    localparam INDEX_WIDTH = $clog2(MATRIX_SIZE);

    logic [$clog2(MATRIX_SIZE + 1)-1:0] write_count;
    logic [INDEX_WIDTH-1:0] row_index;

    assign store_done = (write_count == MATRIX_SIZE);
    assign row_index = write_count[INDEX_WIDTH-1:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_count <= '0;

            for (int row = 0; row < MATRIX_SIZE; row++) begin
                for (int col = 0; col < MATRIX_SIZE; col++) begin
                    stored_matrix[row][col] <= '0;
                end
            end
        end else if (store_enable && !store_done) begin
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                stored_matrix[row_index][col] <= acc_matrix[row_index][col];
            end

            write_count <= write_count + 1'b1;
        end else if (!store_enable) begin
            write_count <= '0;
        end
    end
endmodule
