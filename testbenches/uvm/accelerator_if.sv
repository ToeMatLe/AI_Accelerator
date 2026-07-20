interface accelerator_if(input logic clk);
    import accelerator_uvm_config_pkg::*;

    logic rst_n;
    logic start;
    logic relu_enable;

    logic signed [DATA_SIZE-1:0] input_A [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [DATA_SIZE-1:0] input_B [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    logic signed [ACC_SIZE-1:0] output_C [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    logic done;
    logic store_done;
    logic [2:0] state;
endinterface
