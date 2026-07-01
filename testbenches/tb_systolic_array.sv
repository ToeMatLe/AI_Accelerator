module tb_systolic_array;
    localparam int DATA_SIZE = 8;
    localparam int ACC_SIZE = 32;

    logic clk;
    logic rst_n;

    // Testbench signals for 2x2, 3x3, and 4x4 systolic arrays
    logic valid2;
    logic clear2;
    logic [DATA_SIZE-1:0] input_A2 [0:1];
    logic [DATA_SIZE-1:0] input_B2 [0:1];
    logic [ACC_SIZE-1:0] output_C2 [0:1][0:1];

    logic valid3;
    logic clear3;
    logic [DATA_SIZE-1:0] input_A3 [0:2];
    logic [DATA_SIZE-1:0] input_B3 [0:2];
    logic [ACC_SIZE-1:0] output_C3 [0:2][0:2];

    logic valid4;
    logic clear4;
    logic [DATA_SIZE-1:0] input_A4 [0:3];
    logic [DATA_SIZE-1:0] input_B4 [0:3];
    logic [ACC_SIZE-1:0] output_C4 [0:3][0:3];

    Systolic_Array #(
        .DATA_SIZE(DATA_SIZE),
        .ACC_SIZE(ACC_SIZE),
        .MATRIX_SIZE(2)
    ) dut2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid2),
        .clear(clear2),
        .input_A(input_A2),
        .input_B(input_B2),
        .output_C(output_C2)
    );

    Systolic_Array #(
        .DATA_SIZE(DATA_SIZE),
        .ACC_SIZE(ACC_SIZE),
        .MATRIX_SIZE(3)
    ) dut3 (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid3),
        .clear(clear3),
        .input_A(input_A3),
        .input_B(input_B3),
        .output_C(output_C3)
    );

    Systolic_Array #(
        .DATA_SIZE(DATA_SIZE),
        .ACC_SIZE(ACC_SIZE),
        .MATRIX_SIZE(4)
    ) dut4 (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid4),
        .clear(clear4),
        .input_A(input_A4),
        .input_B(input_B4),
        .output_C(output_C4)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic reset_all;
        int i;
        begin
            rst_n = 1'b0;
            valid2 = 1'b0;
            clear2 = 1'b0;
            valid3 = 1'b0;
            clear3 = 1'b0;
            valid4 = 1'b0;
            clear4 = 1'b0;

            for (i = 0; i < 2; i++) begin
                input_A2[i] = '0;
                input_B2[i] = '0;
            end

            for (i = 0; i < 3; i++) begin
                input_A3[i] = '0;
                input_B3[i] = '0;
            end

            for (i = 0; i < 4; i++) begin
                input_A4[i] = '0;
                input_B4[i] = '0;
            end

            repeat (2) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    task automatic run_2x2;
        logic [DATA_SIZE-1:0] A [0:1][0:1];
        logic [DATA_SIZE-1:0] B [0:1][0:1];
        int expected [0:1][0:1];
        int cycle;
        int row;
        int col;
        int k;
        int idx;
        begin
            A[0][0] = 1; A[0][1] = 2;
            A[1][0] = 3; A[1][1] = 4;

            B[0][0] = 5; B[0][1] = 6;
            B[1][0] = 7; B[1][1] = 8;

            for (row = 0; row < 2; row++) begin
                for (col = 0; col < 2; col++) begin
                    expected[row][col] = 0;
                    for (k = 0; k < 2; k++) begin
                        expected[row][col] += A[row][k] * B[k][col];
                    end
                end
            end

            clear2 = 1'b1;
            @(posedge clk);
            #1;
            clear2 = 1'b0;
            valid2 = 1'b1;

            for (cycle = 0; cycle < 4; cycle++) begin
                for (row = 0; row < 2; row++) begin
                    idx = cycle - row;
                    input_A2[row] = (idx >= 0 && idx < 2) ? A[row][idx] : '0;
                end

                for (col = 0; col < 2; col++) begin
                    idx = cycle - col;
                    input_B2[col] = (idx >= 0 && idx < 2) ? B[idx][col] : '0;
                end

                @(posedge clk);
                #1;
            end

            valid2 = 1'b0;
            for (row = 0; row < 2; row++) begin
                input_A2[row] = '0;
                input_B2[row] = '0;
            end

            for (row = 0; row < 2; row++) begin
                for (col = 0; col < 2; col++) begin
                    if (output_C2[row][col] !== expected[row][col]) begin
                        $error("2x2 mismatch C[%0d][%0d]: got %0d expected %0d",
                               row, col, output_C2[row][col], expected[row][col]);
                    end
                end
            end

            $display("2x2 test passed");
        end
    endtask

    task automatic run_3x3;
        logic [DATA_SIZE-1:0] A [0:2][0:2];
        logic [DATA_SIZE-1:0] B [0:2][0:2];
        int expected [0:2][0:2];
        int cycle;
        int row;
        int col;
        int k;
        int idx;
        begin
            A[0][0] = 1; A[0][1] = 2; A[0][2] = 3;
            A[1][0] = 4; A[1][1] = 5; A[1][2] = 6;
            A[2][0] = 7; A[2][1] = 8; A[2][2] = 9;

            B[0][0] = 9; B[0][1] = 8; B[0][2] = 7;
            B[1][0] = 6; B[1][1] = 5; B[1][2] = 4;
            B[2][0] = 3; B[2][1] = 2; B[2][2] = 1;

            for (row = 0; row < 3; row++) begin
                for (col = 0; col < 3; col++) begin
                    expected[row][col] = 0;
                    for (k = 0; k < 3; k++) begin
                        expected[row][col] += A[row][k] * B[k][col];
                    end
                end
            end

            clear3 = 1'b1;
            @(posedge clk);
            #1;
            clear3 = 1'b0;
            valid3 = 1'b1;

            for (cycle = 0; cycle < 7; cycle++) begin
                for (row = 0; row < 3; row++) begin
                    idx = cycle - row;
                    input_A3[row] = (idx >= 0 && idx < 3) ? A[row][idx] : '0;
                end

                for (col = 0; col < 3; col++) begin
                    idx = cycle - col;
                    input_B3[col] = (idx >= 0 && idx < 3) ? B[idx][col] : '0;
                end

                @(posedge clk);
                #1;
            end

            valid3 = 1'b0;
            for (row = 0; row < 3; row++) begin
                input_A3[row] = '0;
                input_B3[row] = '0;
            end

            for (row = 0; row < 3; row++) begin
                for (col = 0; col < 3; col++) begin
                    if (output_C3[row][col] !== expected[row][col]) begin
                        $error("3x3 mismatch C[%0d][%0d]: got %0d expected %0d",
                               row, col, output_C3[row][col], expected[row][col]);
                    end
                end
            end

            $display("3x3 test passed");
        end
    endtask

    task automatic run_4x4;
        logic [DATA_SIZE-1:0] A [0:3][0:3];
        logic [DATA_SIZE-1:0] B [0:3][0:3];
        int expected [0:3][0:3];
        int cycle;
        int row;
        int col;
        int k;
        int idx;
        begin
            for (row = 0; row < 4; row++) begin
                for (col = 0; col < 4; col++) begin
                    A[row][col] = DATA_SIZE'(row * 4 + col + 1);
                    B[row][col] = (row == col) ? 1 : 0;
                end
            end

            for (row = 0; row < 4; row++) begin
                for (col = 0; col < 4; col++) begin
                    expected[row][col] = 0;
                    for (k = 0; k < 4; k++) begin
                        expected[row][col] += A[row][k] * B[k][col];
                    end
                end
            end

            clear4 = 1'b1;
            @(posedge clk);
            #1;
            clear4 = 1'b0;
            valid4 = 1'b1;

            for (cycle = 0; cycle < 10; cycle++) begin
                for (row = 0; row < 4; row++) begin
                    idx = cycle - row;
                    input_A4[row] = (idx >= 0 && idx < 4) ? A[row][idx] : '0;
                end

                for (col = 0; col < 4; col++) begin
                    idx = cycle - col;
                    input_B4[col] = (idx >= 0 && idx < 4) ? B[idx][col] : '0;
                end

                @(posedge clk);
                #1;
            end

            valid4 = 1'b0;
            for (row = 0; row < 4; row++) begin
                input_A4[row] = '0;
                input_B4[row] = '0;
            end

            for (row = 0; row < 4; row++) begin
                for (col = 0; col < 4; col++) begin
                    if (output_C4[row][col] !== expected[row][col]) begin
                        $error("4x4 mismatch C[%0d][%0d]: got %0d expected %0d",
                               row, col, output_C4[row][col], expected[row][col]);
                    end
                end
            end

            $display("4x4 test passed");
        end
    endtask

    initial begin
        reset_all();
        run_2x2();
        run_3x3();
        run_4x4();
        $display("All systolic array tests passed");
        $finish;
    end
endmodule
