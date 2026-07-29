`include "typedef.svh"

module tb_top_BF16;
    localparam int MATRIX_SIZE = 2;

    logic clk;
    logic rst_n;
    logic start;
    logic relu_enable;
    logic [15:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [15:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [31:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [31:0] expected_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic done;
    logic store_done;
    state_t state;
    int error_count;

    top_BF16 #(
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .relu_enable(relu_enable),
        .input_A(input_A),
        .input_B(input_B),
        .output_C(output_C),
        .done(done),
        .store_done(store_done),
        .state(state)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic start_and_check(input string test_name);
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            wait (done === 1'b1);
            #1;

            if (state !== DONE || store_done !== 1'b1) begin
                $error("%s: DONE handshake was not aligned", test_name);
                error_count++;
            end

            for (int row = 0; row < MATRIX_SIZE; row++) begin
                for (int col = 0; col < MATRIX_SIZE; col++) begin
                    if (output_C[row][col] !== expected_C[row][col]) begin
                        $error("%s: C[%0d][%0d] got %h expected %h",
                               test_name, row, col,
                               output_C[row][col], expected_C[row][col]);
                        error_count++;
                    end
                end
            end

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        relu_enable = 1'b0;
        error_count = 0;

        for (int row = 0; row < MATRIX_SIZE; row++) begin
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                input_A[row][col] = 16'h0000;
                input_B[row][col] = 16'h0000;
                expected_C[row][col] = 32'h0000_0000;
            end
        end

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]].
        input_A[0][0] = 16'h3f80; input_A[0][1] = 16'h4000;
        input_A[1][0] = 16'h4040; input_A[1][1] = 16'h4080;
        input_B[0][0] = 16'h40a0; input_B[0][1] = 16'h40c0;
        input_B[1][0] = 16'h40e0; input_B[1][1] = 16'h4100;

        expected_C[0][0] = 32'h4198_0000; // 19.0
        expected_C[0][1] = 32'h41b0_0000; // 22.0
        expected_C[1][0] = 32'h422c_0000; // 43.0
        expected_C[1][1] = 32'h4248_0000; // 50.0
        start_and_check("BF16 matrix multiply");

        // Multiplication by the identity matrix preserves A.
        input_A[0][0] = 16'hbf80; input_A[0][1] = 16'h4000;
        input_A[1][0] = 16'h4040; input_A[1][1] = 16'hc080;
        input_B[0][0] = 16'h3f80; input_B[0][1] = 16'h0000;
        input_B[1][0] = 16'h0000; input_B[1][1] = 16'h3f80;

        relu_enable = 1'b1;
        expected_C[0][0] = 32'h0000_0000;
        expected_C[0][1] = 32'h4000_0000; // 2.0
        expected_C[1][0] = 32'h4040_0000; // 3.0
        expected_C[1][1] = 32'h0000_0000;
        start_and_check("BF16 ReLU enabled");

        relu_enable = 1'b0;
        expected_C[0][0] = 32'hbf80_0000; // -1.0
        expected_C[0][1] = 32'h4000_0000; //  2.0
        expected_C[1][0] = 32'h4040_0000; //  3.0
        expected_C[1][1] = 32'hc080_0000; // -4.0
        start_and_check("BF16 ReLU disabled");

        if (error_count == 0) begin
            $display("BF16 top-level integration test passed");
        end else begin
            $fatal(1, "BF16 top-level integration test failed with %0d errors",
                   error_count);
        end

        $finish;
    end
endmodule
