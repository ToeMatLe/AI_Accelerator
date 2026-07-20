class accelerator_monitor extends uvm_monitor;
    `uvm_component_utils(accelerator_monitor)

    virtual accelerator_if vif;
    uvm_analysis_port #(accelerator_seq_item) request_ap;
    uvm_analysis_port #(accelerator_seq_item) response_ap;

    covergroup state_coverage with function sample(logic [2:0] sampled_state);
        option.per_instance = 1;

        state_cp: coverpoint sampled_state {
            bins idle = {IDLE_VALUE};
            bins load = {LOAD_VALUE};
            bins compute = {COMPUTE_VALUE};
            bins store = {STORE_VALUE};
            bins done = {DONE_VALUE};
            illegal_bins illegal_state = default;
        }
    endgroup

    function new(string name = "accelerator_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
        state_coverage = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        request_ap = new("request_ap", this);
        response_ap = new("response_ap", this);

        if (!uvm_config_db#(virtual accelerator_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "accelerator_monitor could not get accelerator_if")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_states();
            monitor_requests();
            monitor_responses();
        join
    endtask

    task monitor_states();
        forever begin
            @(negedge vif.clk);
            if (vif.rst_n) state_coverage.sample(vif.state);
        end
    endtask

    task monitor_requests();
        accelerator_seq_item request;

        forever begin
            @(negedge vif.clk);
            if (vif.rst_n && vif.state == LOAD_VALUE) begin
                request = accelerator_seq_item::type_id::create(
                    "monitored_request", this);

                for (int row = 0; row < MATRIX_SIZE; row++) begin
                    for (int col = 0; col < MATRIX_SIZE; col++) begin
                        request.input_A[row][col] = vif.input_A[row][col];
                        request.input_B[row][col] = vif.input_B[row][col];
                    end
                end

                request_ap.write(request);
            end
        end
    endtask

    task monitor_responses();
        accelerator_seq_item response;

        forever begin
            @(negedge vif.clk);
            if (vif.rst_n && vif.done) begin
                response = accelerator_seq_item::type_id::create(
                    "monitored_response", this);

                for (int row = 0; row < MATRIX_SIZE; row++) begin
                    for (int col = 0; col < MATRIX_SIZE; col++) begin
                        response.output_C[row][col] = vif.output_C[row][col];
                    end
                end

                response_ap.write(response);
            end
        end
    endtask
endclass
