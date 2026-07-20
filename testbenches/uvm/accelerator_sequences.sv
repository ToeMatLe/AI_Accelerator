class accelerator_smoke_sequence extends uvm_sequence #(accelerator_seq_item);
    `uvm_object_utils(accelerator_smoke_sequence)

    function new(string name = "accelerator_smoke_sequence");
        super.new(name);
    endfunction

    task body();
        accelerator_seq_item request;

        request = accelerator_seq_item::type_id::create("known_matrix_request");
        start_item(request);
        request.input_A[0][0] = 1; request.input_A[0][1] = 2;
        request.input_A[1][0] = 3; request.input_A[1][1] = 4;
        request.input_B[0][0] = 5; request.input_B[0][1] = 6;
        request.input_B[1][0] = 7; request.input_B[1][1] = 8;
        finish_item(request);

        request = accelerator_seq_item::type_id::create("identity_request");
        start_item(request);
        request.input_A[0][0] = 9; request.input_A[0][1] = 3;
        request.input_A[1][0] = 4; request.input_A[1][1] = 7;
        request.input_B[0][0] = 1; request.input_B[0][1] = 0;
        request.input_B[1][0] = 0; request.input_B[1][1] = 1;
        finish_item(request);

        request = accelerator_seq_item::type_id::create("zero_request");
        start_item(request);
        foreach (request.input_A[row, col]) begin
            request.input_A[row][col] = '0;
            request.input_B[row][col] = '0;
        end
        finish_item(request);
    endtask
endclass

class accelerator_random_sequence extends uvm_sequence #(accelerator_seq_item);
    int unsigned transaction_count = 25;

    `uvm_object_utils(accelerator_random_sequence)

    function new(string name = "accelerator_random_sequence");
        super.new(name);
    endfunction

    task body();
        accelerator_seq_item request;
        void'($value$plusargs("NUM_TRANSACTIONS=%d", transaction_count));

        repeat (transaction_count) begin
            request = accelerator_seq_item::type_id::create("random_request");
            start_item(request);
            if (!request.randomize()) begin
                `uvm_fatal("RANDOMIZE", "Failed to randomize accelerator transaction")
            end
            finish_item(request);
        end
    endtask
endclass
