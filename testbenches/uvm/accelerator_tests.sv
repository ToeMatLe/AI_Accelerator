class accelerator_base_test extends uvm_test;
    `uvm_component_utils(accelerator_base_test)

    accelerator_env env;

    function new(string name = "accelerator_base_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = accelerator_env::type_id::create("env", this);
    endfunction
endclass

class accelerator_smoke_test extends accelerator_base_test;
    `uvm_component_utils(accelerator_smoke_test)

    function new(string name = "accelerator_smoke_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        accelerator_smoke_sequence sequence_handle;

        phase.raise_objection(this);
        sequence_handle = accelerator_smoke_sequence::type_id::create(
            "smoke_sequence");
        sequence_handle.start(env.agent.sequencer);
        wait (env.scoreboard.transactions_checked == 5);
        phase.drop_objection(this);
    endtask
endclass

class accelerator_random_test extends accelerator_base_test;
    `uvm_component_utils(accelerator_random_test)

    function new(string name = "accelerator_random_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        accelerator_random_sequence sequence_handle;

        phase.raise_objection(this);
        sequence_handle = accelerator_random_sequence::type_id::create(
            "random_sequence");
        sequence_handle.start(env.agent.sequencer);
        wait (env.scoreboard.transactions_checked ==
              sequence_handle.transaction_count);
        phase.drop_objection(this);
    endtask
endclass
