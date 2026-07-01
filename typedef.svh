`ifndef TYPEDEF_SVH
`define TYPEDEF_SVH

typedef enum logic [2:0] {
    IDLE,
    LOAD,
    COMPUTE,
    STORE,
    DONE
} state_t;

`endif
