class accelerator_agent extends uvm_agent;
    `uvm_component_utils(accelerator_agent)

    accelerator_sequencer sequencer;
    accelerator_driver driver;
    accelerator_monitor monitor;

    function new(string name = "accelerator_agent",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sequencer = accelerator_sequencer::type_id::create(
            "sequencer", this);
        driver = accelerator_driver::type_id::create("driver", this);
        monitor = accelerator_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
