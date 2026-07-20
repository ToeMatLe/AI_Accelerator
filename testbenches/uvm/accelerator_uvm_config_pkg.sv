package accelerator_uvm_config_pkg;
    /* verilator lint_off UNUSEDPARAM */
    localparam int DATA_SIZE = 8;
    localparam int ACC_SIZE = 32;
    localparam int MATRIX_SIZE = 2;

    localparam logic [2:0] IDLE_VALUE = 3'd0;
    localparam logic [2:0] LOAD_VALUE = 3'd1;
    localparam logic [2:0] COMPUTE_VALUE = 3'd2;
    localparam logic [2:0] STORE_VALUE = 3'd3;
    localparam logic [2:0] DONE_VALUE = 3'd4;
    /* verilator lint_on UNUSEDPARAM */
endpackage
