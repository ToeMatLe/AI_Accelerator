class accelerator_env extends uvm_env;
    `uvm_component_utils(accelerator_env)

    accelerator_agent agent;
    accelerator_scoreboard scoreboard;

    function new(string name = "accelerator_env",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent = accelerator_agent::type_id::create("agent", this);
        scoreboard = accelerator_scoreboard::type_id::create(
            "scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agent.monitor.request_ap.connect(
            scoreboard.request_fifo.analysis_export);
        agent.monitor.response_ap.connect(
            scoreboard.response_fifo.analysis_export);
    endfunction
endclass
