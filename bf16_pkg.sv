package bf16_pkg;
    localparam int BF16_WIDTH = 16;
    localparam int FP32_WIDTH = 32;

    typedef logic [BF16_WIDTH-1:0] bf16_t;
    typedef logic [FP32_WIDTH-1:0] fp32_t;

    localparam bf16_t BF16_POS_ZERO = 16'h0000;
    localparam fp32_t FP32_POS_ZERO = 32'h0000_0000;
    localparam fp32_t FP32_POS_INF  = 32'h7f80_0000;
    localparam fp32_t FP32_QNAN     = 32'h7fc0_0000;

    function automatic logic bf16_is_zero(input bf16_t value);
        return (value[14:0] == 15'b0);
    endfunction

    function automatic logic bf16_is_inf(input bf16_t value);
        return (value[14:7] == 8'hff) && (value[6:0] == 7'b0);
    endfunction

    function automatic logic bf16_is_nan(input bf16_t value);
        return (value[14:7] == 8'hff) && (value[6:0] != 7'b0);
    endfunction

    function automatic logic fp32_is_zero(input fp32_t value);
        return (value[30:0] == 31'b0);
    endfunction

    function automatic logic fp32_is_inf(input fp32_t value);
        return (value[30:23] == 8'hff) && (value[22:0] == 23'b0);
    endfunction

    function automatic logic fp32_is_nan(input fp32_t value);
        return (value[30:23] == 8'hff) && (value[22:0] != 23'b0);
    endfunction
endpackage
