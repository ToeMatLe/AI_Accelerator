module tb_input_buffers;
    localparam int DATA_SIZE = 8;
    localparam int MATRIX_SIZE = 3;
    localparam int FEED_CYCLES = 2*MATRIX_SIZE - 1;

    logic clk;
    logic rst_n;
    logic load_enable;
    logic feed_enable;

    logic [DATA_SIZE-1:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [DATA_SIZE-1:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [DATA_SIZE-1:0] output_A [0:MATRIX_SIZE-1];
    logic [DATA_SIZE-1:0] output_B [0:MATRIX_SIZE-1];

    int error_count;

    Input_Buffers #(
        .DATA_SIZE(DATA_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_enable(load_enable),
        .feed_enable(feed_enable),
        .input_A(input_A),
        .input_B(input_B),
        .output_A(output_A),
        .output_B(output_B)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check_feed_cycle(input int cycle);
        int index;
        logic [DATA_SIZE-1:0] expected_A;
        logic [DATA_SIZE-1:0] expected_B;
        begin
            for (int row = 0; row < MATRIX_SIZE; row++) begin
                index = cycle - row;
                expected_A = (index >= 0 && index < MATRIX_SIZE)
                           ? input_A[row][index] : '0;

                if (output_A[row] !== expected_A) begin
                    $error("cycle %0d: A[%0d] got %0d expected %0d",
                           cycle, row, output_A[row], expected_A);
                    error_count++;
                end
            end

            for (int col = 0; col < MATRIX_SIZE; col++) begin
                index = cycle - col;
                expected_B = (index >= 0 && index < MATRIX_SIZE)
                           ? input_B[index][col] : '0;

                if (output_B[col] !== expected_B) begin
                    $error("cycle %0d: B[%0d] got %0d expected %0d",
                           cycle, col, output_B[col], expected_B);
                    error_count++;
                end
            end
        end
    endtask

    initial begin
        rst_n = 1'b0;
        load_enable = 1'b0;
        feed_enable = 1'b0;
        error_count = 0;

        for (int row = 0; row < MATRIX_SIZE; row++) begin
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                input_A[row][col] = DATA_SIZE'(row * MATRIX_SIZE + col + 1);
                input_B[row][col] = DATA_SIZE'(20 + row * MATRIX_SIZE + col);
            end
        end

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        load_enable = 1'b1;
        @(posedge clk);
        #1;

        load_enable = 1'b0;
        feed_enable = 1'b1;

        for (int cycle = 0; cycle < FEED_CYCLES; cycle++) begin
            #1;
            check_feed_cycle(cycle);
            @(posedge clk);
            #1;
        end

        feed_enable = 1'b0;
        #1;

        for (int index = 0; index < MATRIX_SIZE; index++) begin
            if (output_A[index] !== '0 || output_B[index] !== '0) begin
                $error("outputs must be zero when feed_enable is low");
                error_count++;
            end
        end

        if (error_count == 0) begin
            $display("Input_Buffers test passed");
        end else begin
            $fatal(1, "Input_Buffers test failed with %0d errors", error_count);
        end

        $finish;
    end
endmodule
