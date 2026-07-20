class accelerator_seq_item extends uvm_sequence_item;
    rand logic signed [DATA_SIZE-1:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    rand logic signed [DATA_SIZE-1:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    rand logic relu_enable;

    logic signed [ACC_SIZE-1:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Keep randomized operands small enough that the current accumulator
    // cannot overflow during these tests.
    constraint small_signed_values {
        foreach (input_A[row, col]) input_A[row][col] inside {[-8:8]};
        foreach (input_B[row, col]) input_B[row][col] inside {[-8:8]};
    }

    `uvm_object_utils(accelerator_seq_item)

    function new(string name = "accelerator_seq_item");
        super.new(name);
    endfunction

    function string inputs_to_string();
        string message;
        message = $sformatf("ReLU=%0b A=", relu_enable);

        for (int row = 0; row < MATRIX_SIZE; row++) begin
            message = {message, "["};
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                message = {
                    message,
                    $sformatf("%0d", $signed(input_A[row][col]))
                };
                if (col != MATRIX_SIZE - 1) message = {message, ","};
            end
            message = {message, "]"};
        end

        message = {message, " B="};
        for (int row = 0; row < MATRIX_SIZE; row++) begin
            message = {message, "["};
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                message = {
                    message,
                    $sformatf("%0d", $signed(input_B[row][col]))
                };
                if (col != MATRIX_SIZE - 1) message = {message, ","};
            end
            message = {message, "]"};
        end

        return message;
    endfunction
endclass
