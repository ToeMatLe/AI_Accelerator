/* verilator lint_off SYNCASYNCNET */
module accelerator_sva (
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [2:0] state,
    input logic valid,
    input logic clear,
    input logic load_enable,
    input logic feed_enable,
    input logic store_enable,
    input logic done
);
    import accelerator_uvm_config_pkg::*;

    default clocking controller_cb @(posedge clk);
    endclocking

    default disable iff (!rst_n);

    ap_known_control_signals:
        assert property (!$isunknown({
            state, valid, clear, load_enable,
            feed_enable, store_enable, done
        }));

    ap_idle_outputs:
        assert property (
            state == IDLE_VALUE |->
            clear && !valid && !load_enable &&
            !feed_enable && !store_enable && !done
        );

    ap_load_outputs:
        assert property (
            state == LOAD_VALUE |->
            clear && load_enable && !valid &&
            !feed_enable && !store_enable && !done
        );

    ap_compute_outputs:
        assert property (
            state == COMPUTE_VALUE |->
            valid && !clear && !load_enable &&
            !store_enable && !done
        );

    ap_store_outputs:
        assert property (
            state == STORE_VALUE |->
            store_enable && !valid && !clear &&
            !load_enable && !feed_enable && !done
        );

    ap_done_outputs:
        assert property (
            state == DONE_VALUE |->
            done && !valid && !clear && !load_enable &&
            !feed_enable && !store_enable
        );

    ap_feed_requires_compute:
        assert property (feed_enable |-> state == COMPUTE_VALUE && valid);

    ap_start_enters_load:
        assert property (
            state == IDLE_VALUE && start |=> state == LOAD_VALUE
        );

    ap_load_enters_compute:
        assert property (state == LOAD_VALUE |=> state == COMPUTE_VALUE);

    ap_done_returns_idle:
        assert property (state == DONE_VALUE |=> state == IDLE_VALUE);

    cp_start_to_compute:
        cover property (
            state == IDLE_VALUE && start
            ##1 state == LOAD_VALUE
            ##1 state == COMPUTE_VALUE
        );

    cp_store_to_idle:
        cover property (
            state == STORE_VALUE
            ##1 state == DONE_VALUE
            ##1 state == IDLE_VALUE
        );
endmodule

/* verilator lint_off DECLFILENAME */
module accelerator_top_sva #(
    parameter ACC_SIZE = 32,
    parameter MATRIX_SIZE = 2
)(
    input logic clk,
    input logic rst_n,
    input logic done,
    input logic store_done,
    input logic relu_enable,
    input logic [2:0] state,
    input logic signed [ACC_SIZE-1:0] output_C
        [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1]
);
    import accelerator_uvm_config_pkg::*;

    default clocking top_cb @(posedge clk);
    endclocking

    default disable iff (!rst_n);

    ap_done_has_stored_result:
        assert property (
            done |-> store_done && state == DONE_VALUE
        );

    ap_store_done_aligns_with_done:
        assert property (store_done |-> done);

    generate
        for (genvar row = 0; row < MATRIX_SIZE; row++) begin : relu_row_sva
            for (genvar col = 0; col < MATRIX_SIZE; col++) begin : relu_col_sva
                ap_relu_clamps_negative_results:
                    assert property (
                        done && relu_enable |->
                        !output_C[row][col][ACC_SIZE-1]
                    );
            end
        end
    endgenerate
endmodule
/* verilator lint_on DECLFILENAME */

bind controller accelerator_sva controller_sva_i (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .state(state),
    .valid(valid),
    .clear(clear),
    .load_enable(load_enable),
    .feed_enable(feed_enable),
    .store_enable(store_enable),
    .done(done)
);

bind top accelerator_top_sva #(
    .ACC_SIZE(ACC_SIZE),
    .MATRIX_SIZE(MATRIX_SIZE)
) top_sva_i (
    .clk(clk),
    .rst_n(rst_n),
    .done(done),
    .store_done(store_done),
    .relu_enable(relu_enable_latched),
    .state(state),
    .output_C(output_C)
);
/* verilator lint_on SYNCASYNCNET */
