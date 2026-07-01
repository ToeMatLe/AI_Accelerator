`include "typedef.svh"

module controller #(
    parameter DATA_SIZE = 8,    // Integer size
    parameter ACC_SIZE = 32,    // Accumulator size
    parameter MATRIX_SIZE = 2   // Size of the systolic array (2x2) -> Can seperate into L x W later
)(
    input logic clk,
    input logic rst_n,
    input logic start, // Start signal to initiate the computation

    output logic valid, // Valid signal to indicate when inputs are valid
    output logic clear, // Clear signal to reset the accumulator
    output logic done, // Done signal to indicate completion of the computation
    output state_t state // Current state of the controller
);
    state_t current_state, next_state;
    localparam MIN_CYCLES = 3*MATRIX_SIZE - 2; // Minimum cycles needed for computation (3*MATRIX_SIZE - 2)
    logic [$clog2(MIN_CYCLES+1)-1:0] cycle_counter; // Counter to track the number of cycles
    logic [$clog2(MATRIX_SIZE +1)-1:0] store_counter; // Counter to track the number of store operations

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            cycle_counter <= 0;
        end else begin
            current_state <= next_state;
        end
    end
    
    always_comb begin
        next_state = current_state; // Default to hold state
        valid = 0;
        clear = 0;

        case (current_state) 
            IDLE: next_state = start ? LOAD : IDLE; 

            LOAD: begin
                valid = 1; // Indicate that inputs are valid for loading
                next_state = COMPUTE;
            end

            COMPUTE: begin
                valid = 1; // Indicate that inputs are valid for computation
                next_state = STORE;
            end

            STORE: begin
                clear = 1; // Clear the accumulator after storing results
                next_state = DONE;
            end

            DONE: begin
                next_state = IDLE; // Return to IDLE after completion
            end

            default: begin
                next_state = IDLE; // Default to IDLE on unexpected state
            end
        endcase
    end
endmodule