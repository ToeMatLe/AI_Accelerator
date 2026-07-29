module tb_bf16_datapath;
    logic clk;
    logic rst_n;
    logic valid;
    logic clear;
    logic [15:0] input_A [0:1];
    logic [15:0] input_B [0:1];
    logic [31:0] output_C [0:1][0:1];

    logic [15:0] multiply_A;
    logic [15:0] multiply_B;
    logic [31:0] multiply_result;
    logic [31:0] add_A;
    logic [31:0] add_B;
    logic [31:0] add_result;

    bf16_multiplier multiplier_dut (
        .input_A(multiply_A),
        .input_B(multiply_B),
        .product(multiply_result)
    );

    fp32_adder adder_dut (
        .input_A(add_A),
        .input_B(add_B),
        .sum(add_result)
    );

    Systolic_Array_BF16 #(
        .MATRIX_SIZE(2)
    ) array_dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .clear(clear),
        .input_A(input_A),
        .input_B(input_B),
        .output_C(output_C)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string name
    );
        if (actual !== expected) begin
            $error("%s: got %h expected %h", name, actual, expected);
        end
    endtask

    initial begin
        rst_n = 1'b0;
        valid = 1'b0;
        clear = 1'b0;
        input_A[0] = 16'h0000;
        input_A[1] = 16'h0000;
        input_B[0] = 16'h0000;
        input_B[1] = 16'h0000;

        // -3.0 BF16 * -6.0 BF16 = +18.0 FP32.
        multiply_A = 16'hc040;
        multiply_B = 16'hc0c0;
        #1;
        check_value(multiply_result, 32'h4190_0000, "BF16 multiply");

        // TPU-style BF16 flushes subnormal operands to zero.
        multiply_A = 16'h0001;
        multiply_B = 16'h3f80;
        #1;
        check_value(multiply_result, 32'h0000_0000, "BF16 subnormal flush");

        // 1.5 FP32 + 2.25 FP32 = 3.75 FP32.
        add_A = 32'h3fc0_0000;
        add_B = 32'h4010_0000;
        #1;
        check_value(add_result, 32'h4070_0000, "FP32 add");

        add_A = 32'h3f80_0000;
        add_B = 32'hbf80_0000;
        #1;
        check_value(add_result, 32'h0000_0000, "FP32 cancellation");

        add_A = 32'h0000_0001;
        add_B = 32'h0000_0001;
        #1;
        check_value(add_result, 32'h0000_0002, "FP32 subnormal add");

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;
        valid = 1'b1;

        // A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]].
        // The edge inputs are skewed so equal k values meet in each PE.
        input_A[0] = 16'h3f80; input_A[1] = 16'h0000;
        input_B[0] = 16'h40a0; input_B[1] = 16'h0000;
        @(posedge clk); #1;

        input_A[0] = 16'h4000; input_A[1] = 16'h4040;
        input_B[0] = 16'h40e0; input_B[1] = 16'h40c0;
        @(posedge clk); #1;

        input_A[0] = 16'h0000; input_A[1] = 16'h4080;
        input_B[0] = 16'h0000; input_B[1] = 16'h4100;
        @(posedge clk); #1;

        input_A[0] = 16'h0000; input_A[1] = 16'h0000;
        input_B[0] = 16'h0000; input_B[1] = 16'h0000;
        @(posedge clk); #1;

        valid = 1'b0;
        check_value(output_C[0][0], 32'h4198_0000, "C[0][0]");
        check_value(output_C[0][1], 32'h41b0_0000, "C[0][1]");
        check_value(output_C[1][0], 32'h422c_0000, "C[1][0]");
        check_value(output_C[1][1], 32'h4248_0000, "C[1][1]");

        $display("BF16 datapath and 2x2 systolic-array tests passed");
        $finish;
    end
endmodule
