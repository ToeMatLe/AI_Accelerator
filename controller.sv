`include "typedef.svh"

module controller #(
    parameter DATA_SIZE = 8,    // Integer size
    parameter ACC_SIZE = 32,    // Accumulator size
    parameter MATRIX_SIZE = 2   // Size of the systolic array
)(
    input logic clk,
    input logic rst_n,
    input logic start,

    output logic valid,
    output logic clear,        
    output logic load_enable,  // High while input buffers should load A/B matrices
    output logic feed_enable,  // High while buffers should feed real A/B edge values
    output logic store_enable, // High while output_C should be copied to output memory
    output logic done,

    output state_t state
);
    localparam FEED_CYCLES = 2*MATRIX_SIZE - 1;
    localparam TOTAL_CYCLES = 3*MATRIX_SIZE - 2;
    localparam STORE_CYCLES = MATRIX_SIZE;

    logic [$clog2(3*MATRIX_SIZE + 1)-1:0] cycle_count;
    logic [$clog2(MATRIX_SIZE + 1)-1:0] write_count;

    state_t current_state, next_state;
    assign state = current_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            cycle_count <= '0;
            write_count <= '0;
        end else begin
            current_state <= next_state;
            case (current_state)
                IDLE: begin
                    cycle_count <= '0;
                    write_count <= '0;
                end
                LOAD: begin
                    cycle_count <= '0;
                    write_count <= '0;
                end
                COMPUTE: begin
                    cycle_count <= cycle_count + 1'b1;
                    write_count <= '0;
                end
                STORE: begin
                    // row-vector memory interface 
                    // could do a single cycle store, but this is more realistic for larger matrices
                    // BRAM/SRAM have limited number of write ports
                    cycle_count <= '0;
                    write_count <= write_count + 1'b1;
                end
                DONE: begin
                    cycle_count <= '0;
                    write_count <= '0;
                end
                default: begin
                    cycle_count <= '0;
                    write_count <= '0;
                end
            endcase
        end
    end

    always_comb begin
        next_state = current_state;

        valid = 1'b0;
        clear = 1'b0;
        load_enable = 1'b0;
        feed_enable = 1'b0;
        store_enable = 1'b0;
        done = 1'b0;

        case (current_state)
            IDLE: begin
                clear = 1'b1;
                next_state = start ? LOAD : IDLE;
            end
            LOAD: begin
                clear = 1'b1;
                load_enable = 1'b1;
                next_state = COMPUTE;
            end
            COMPUTE: begin
                valid = 1'b1;
                feed_enable = (cycle_count < FEED_CYCLES);
                next_state = (cycle_count == TOTAL_CYCLES - 1'b1) ? STORE : COMPUTE;
            end
            STORE: begin
                store_enable = 1'b1;

                next_state = (write_count == STORE_CYCLES - 1'b1) ? DONE : STORE;
            end
            DONE: begin
                done = 1'b1;
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule
