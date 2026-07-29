module Input_Buffers_BF16 #(
    parameter int MATRIX_SIZE = 2
)(
    input  logic clk,
    input  logic rst_n,
    input  logic load_enable,
    input  logic feed_enable,

    input  logic [15:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],
    input  logic [15:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1],

    output logic [15:0] output_A [0:MATRIX_SIZE-1],
    output logic [15:0] output_B [0:MATRIX_SIZE-1]
);
    localparam int FEED_CYCLES = 2*MATRIX_SIZE - 1;
    localparam int FEED_COUNT_WIDTH =
        (FEED_CYCLES <= 1) ? 1 : $clog2(FEED_CYCLES);

    logic [15:0] buffer_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [15:0] buffer_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic [FEED_COUNT_WIDTH-1:0] feed_count;

    // Capture the complete BF16 matrices. BF16 values remain unsigned packed
    // bit patterns; their floating-point sign is stored in bit 15.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feed_count <= '0;

            for (int row = 0; row < MATRIX_SIZE; row++) begin
                for (int col = 0; col < MATRIX_SIZE; col++) begin
                    buffer_A[row][col] <= '0;
                    buffer_B[row][col] <= '0;
                end
            end
        end else if (load_enable) begin
            feed_count <= '0;

            for (int row = 0; row < MATRIX_SIZE; row++) begin
                for (int col = 0; col < MATRIX_SIZE; col++) begin
                    buffer_A[row][col] <= input_A[row][col];
                    buffer_B[row][col] <= input_B[row][col];
                end
            end
        end else if (feed_enable) begin
            if (int'(feed_count) < FEED_CYCLES - 1) begin
                feed_count <= feed_count + 1'b1;
            end
        end
    end

    // Delay A row r by r cycles and B column c by c cycles so matching
    // A[row][k] and B[k][col] values meet in the same processing element.
    always_comb begin
        int unsigned feed_cycle;
        feed_cycle = int'(feed_count);

        for (int row = 0; row < MATRIX_SIZE; row++) begin
            output_A[row] = '0;

            if (feed_enable &&
                (feed_cycle >= row) &&
                (feed_cycle < row + MATRIX_SIZE)) begin
                output_A[row] = buffer_A[row][feed_cycle - row];
            end
        end

        for (int col = 0; col < MATRIX_SIZE; col++) begin
            output_B[col] = '0;

            if (feed_enable &&
                (feed_cycle >= col) &&
                (feed_cycle < col + MATRIX_SIZE)) begin
                output_B[col] = buffer_B[feed_cycle - col][col];
            end
        end
    end
endmodule
