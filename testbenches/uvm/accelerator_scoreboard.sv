class accelerator_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(accelerator_scoreboard)

    uvm_tlm_analysis_fifo #(accelerator_seq_item) request_fifo;
    uvm_tlm_analysis_fifo #(accelerator_seq_item) response_fifo;

    int unsigned transactions_checked;

    function new(string name = "accelerator_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        request_fifo = new("request_fifo", this);
        response_fifo = new("response_fifo", this);
        transactions_checked = 0;
    endfunction

    task run_phase(uvm_phase phase);
        accelerator_seq_item request;
        accelerator_seq_item response;
        logic [ACC_SIZE-1:0] expected;

        forever begin
            request_fifo.get(request);
            response_fifo.get(response);

            for (int row = 0; row < MATRIX_SIZE; row++) begin
                for (int col = 0; col < MATRIX_SIZE; col++) begin
                    expected = '0;

                    for (int k = 0; k < MATRIX_SIZE; k++) begin
                        expected += request.input_A[row][k] *
                                    request.input_B[k][col];
                    end

                    if (response.output_C[row][col] !== expected) begin
                        `uvm_error(
                            "MATRIX_MISMATCH",
                            $sformatf(
                                "%s C[%0d][%0d] got %0d expected %0d",
                                request.inputs_to_string(),
                                row, col,
                                response.output_C[row][col],
                                expected
                            )
                        )
                    end
                end
            end

            transactions_checked++;
            `uvm_info(
                "SCOREBOARD",
                $sformatf("Checked transaction %0d: %s",
                          transactions_checked, request.inputs_to_string()),
                UVM_LOW
            )
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        if (transactions_checked == 0) begin
            `uvm_error("NO_TRAFFIC", "Scoreboard did not check any transactions")
        end else begin
            `uvm_info(
                "SCOREBOARD",
                $sformatf("Checked %0d accelerator transactions",
                          transactions_checked),
                UVM_NONE
            )
        end
    endfunction
endclass
