module ProcessingElement #(
    parameter DATA_SIZE = 16  //BF16 
    parameter ACC_SIZE = 32   // Data size times 2
)(
    input logic clk,
    input logic rst_n,
    input logic [DATA_SIZE-1:0] input_A,
    input logic [DATA_SIZE-1:0] input_B,
    output logic [DATA_SIZE-1:0] output_A,  // Shifts right in systoic array
    output logic [DATA_SIZE-1:0] output_B   // Shifts down in systoic array
    output logic [ACC_SIZE-1:0] acc_out     // Accumulated output
);

always _ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        output_A <= '0;
        output_B <= '0;
    end else begin
        acc_out <= acc_out + (input_A * input_B); 
        output_A <= input_A; // Pass input_A to output_A
        output_B <= input_B; // Pass input_B to output_B
    end
end
endmodule