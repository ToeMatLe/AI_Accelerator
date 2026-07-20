class accelerator_driver extends uvm_driver #(accelerator_seq_item);
    `uvm_component_utils(accelerator_driver)

    virtual accelerator_if vif;

    function new(string name = "accelerator_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual accelerator_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "accelerator_driver could not get accelerator_if")
        end
    endfunction

    task run_phase(uvm_phase phase);
        accelerator_seq_item request;

        vif.start <= 1'b0;
        wait (vif.rst_n === 1'b1);

        forever begin
            seq_item_port.get_next_item(request);

            // Only begin a new transaction after the controller returns to IDLE.
            while (vif.state != IDLE_VALUE) @(negedge vif.clk);

            @(negedge vif.clk);
            for (int row = 0; row < MATRIX_SIZE; row++) begin
                for (int col = 0; col < MATRIX_SIZE; col++) begin
                    vif.input_A[row][col] <= request.input_A[row][col];
                    vif.input_B[row][col] <= request.input_B[row][col];
                end
            end
            vif.start <= 1'b1;

            // One full start pulse is enough for IDLE to enter LOAD.
            @(negedge vif.clk);
            vif.start <= 1'b0;

            wait (vif.done === 1'b1);
            @(negedge vif.clk);
            seq_item_port.item_done();
        end
    endtask
endclass
