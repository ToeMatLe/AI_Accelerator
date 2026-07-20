class accelerator_sequencer extends uvm_sequencer #(accelerator_seq_item);
    `uvm_component_utils(accelerator_sequencer)

    function new(string name = "accelerator_sequencer",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
