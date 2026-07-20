module tb_accelerator_uvm;
    import uvm_pkg::*;
    import accelerator_uvm_config_pkg::*;
    import accelerator_uvm_pkg::*;

    logic clk;
    accelerator_if accel_vif(clk);

    top #(
        .DATA_SIZE(DATA_SIZE),
        .ACC_SIZE(ACC_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(accel_vif.rst_n),
        .start(accel_vif.start),
        .input_A(accel_vif.input_A),
        .input_B(accel_vif.input_B),
        .output_C(accel_vif.output_C),
        .done(accel_vif.done),
        .store_done(accel_vif.store_done),
        .state(accel_vif.state)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        accel_vif.rst_n = 1'b0;
        accel_vif.start = 1'b0;

        for (int row = 0; row < MATRIX_SIZE; row++) begin
            for (int col = 0; col < MATRIX_SIZE; col++) begin
                accel_vif.input_A[row][col] = '0;
                accel_vif.input_B[row][col] = '0;
            end
        end

        repeat (5) @(posedge clk);
        accel_vif.rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual accelerator_if)::set(
            null, "*", "vif", accel_vif);
        run_test();
    end

    initial begin
        #1ms;
        $fatal(1, "UVM accelerator test timed out");
    end
endmodule
