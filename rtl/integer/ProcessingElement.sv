module ProcessingElement #(
    parameter DATA_SIZE = 8,  // Integer 8 bits, later BF16 
    parameter ACC_SIZE = 32   // Accumulator size
)(
    input logic clk,
    input logic rst_n,
    input logic valid, // Valid signal to indicate when inputs are valid
    input logic clear, // Clear signal to reset the accumulator
    input logic signed [DATA_SIZE-1:0] input_A,
    input logic signed [DATA_SIZE-1:0] input_B,
    output logic signed [DATA_SIZE-1:0] output_A,  // Shifts right in systoic array
    output logic signed [DATA_SIZE-1:0] output_B,   // Shifts down in systoic array
    output logic signed [ACC_SIZE-1:0] acc_out     // Accumulated output
);
localparam PRODUCT_SIZE = 2*DATA_SIZE;

logic signed [PRODUCT_SIZE-1:0] product;
logic signed [ACC_SIZE-1:0] extended_product;

assign product = input_A * input_B;
assign extended_product = {{(ACC_SIZE-PRODUCT_SIZE){product[PRODUCT_SIZE-1]}}, product};

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        acc_out <= '0;
        output_A <= '0;
        output_B <= '0;
    end else if (clear) begin
        acc_out <= '0;
        output_A <= '0;
        output_B <= '0;
    end else if (valid) begin
        acc_out <= acc_out + extended_product;
        output_A <= input_A;
        output_B <= input_B;
    end
end
endmodule
