`include "typedef.svh"

module tb_top;
    localparam int DATA_SIZE = 8;
    localparam int ACC_SIZE = 32;
    localparam int MATRIX_SIZE = 2;

    logic clk;
    logic rst_n;
    logic start;

    logic [DATA_SIZE-1:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [DATA_SIZE-1:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [ACC_SIZE-1:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic done;
    logic store_done;
    state_t state;

    int unsigned expected_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    int error_count;

    top #(
        .DATA_SIZE(DATA_SIZE),
        .ACC_SIZE(ACC_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .input_A(input_A),
        .input_B(input_B),
        .output_C(output_C),
        .done(done),
        .store_done(store_done),
        .state(state)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic calculate_expected;
        begin
            for (int row = 0; row < MATRIX_SIZE; row++) begin
                for (int col = 0; col < MATRIX_SIZE; col++) begin
                    expected_C[row][col] = 0;

                    for (int k = 0; k < MATRIX_SIZE; k++) begin
                        expected_C[row][col] += input_A[row][k] * input_B[k][col];
                    end
                end
            end
        end
    endtask

    task automatic start_and_check(input string test_name);
        begin
            calculate_expected();

            // Assert start while the controller is in IDLE.
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
                        $error("%s: C[%0d][%0d] got %0d expected %0d",
                               test_name, row, col,
                               output_C[row][col], expected_C[row][col]);
                        error_count++;
                    end
                end
            end

            // Allow DONE to return to IDLE before starting another operation.
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        error_count = 0;

        for (int row = 0; row < MATRIX_SIZE; row++) begin
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                input_A[row][col] = '0;
                input_B[row][col] = '0;
            end
        end

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        input_A[0][0] = 1; input_A[0][1] = 2;
        input_A[1][0] = 3; input_A[1][1] = 4;
        input_B[0][0] = 5; input_B[0][1] = 6;
        input_B[1][0] = 7; input_B[1][1] = 8;
        start_and_check("first operation");

        // A second operation verifies that clear removes old PE pipeline data.
        input_A[0][0] = 2; input_A[0][1] = 0;
        input_A[1][0] = 1; input_A[1][1] = 3;
        input_B[0][0] = 4; input_B[0][1] = 1;
        input_B[1][0] = 2; input_B[1][1] = 5;
        start_and_check("second operation");

        if (error_count == 0) begin
            $display("Top-level integration test passed");
        end else begin
            $fatal(1, "Top-level integration test failed with %0d errors",
                   error_count);
        end

        $finish;
    end
endmodule
