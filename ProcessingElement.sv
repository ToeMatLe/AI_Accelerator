module ProcessingElement #(
    parameter DATA_SIZE = 8,  // Integer 8 bits, later BF16 
    parameter ACC_SIZE = 32   // Accumulator size
)(
    input logic clk,
    input logic rst_n,
    input logic valid, // Valid signal to indicate when inputs are valid
    input logic clear, // Clear signal to reset the accumulator
    input logic [DATA_SIZE-1:0] input_A,
    input logic [DATA_SIZE-1:0] input_B,
    output logic [DATA_SIZE-1:0] output_A,  // Shifts right in systoic array
    output logic [DATA_SIZE-1:0] output_B,   // Shifts down in systoic array
    output logic [ACC_SIZE-1:0] acc_out     // Accumulated output
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        acc_out <= '0;
        output_A <= '0;
        output_B <= '0;
    end else if (clear) begin
        acc_out <= '0;
    end else if (enable) begin
        acc_out <= acc_out + (input_A * input_B);
        output_A <= input_A;
        output_B <= input_B;
    end
end
endmodule