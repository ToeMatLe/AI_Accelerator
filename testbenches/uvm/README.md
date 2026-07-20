# Accelerator UVM Verification

This directory verifies the complete `top` accelerator with a reusable,
class-based UVM environment, concurrent SystemVerilog assertions, functional
coverage, and an automated Synopsys VCS regression.

## Verification architecture

The UVM data flow is:

```text
sequence
  -> sequencer
  -> driver
  -> accelerator interface/DUT
  -> monitor
  -> scoreboard
```

- `accelerator_seq_item.sv`: randomized signed A/B matrices and ReLU mode.
- `accelerator_sequences.sv`: positive, zero, identity, negative/ReLU, and
  constrained-random traffic.
- `accelerator_driver.sv`: drives matrices, selects ReLU, and pulses `start`.
- `accelerator_monitor.sv`: observes LOAD requests and DONE responses and
  samples controller-state functional coverage.
- `accelerator_scoreboard.sv`: calculates signed `A x B`, applies the selected
  ReLU reference behavior, and compares every MemoryBank output element.
- `accelerator_agent.sv`: groups the sequencer, driver, and monitor.
- `accelerator_env.sv`: connects the agent to the scoreboard.
- `accelerator_tests.sv`: defines `accelerator_smoke_test` and
  `accelerator_random_test`.
- `accelerator_sva.sv`: checks controller outputs, state transitions, the final
  `done`/`store_done` handshake, and nonnegative outputs when ReLU is enabled.
- `tb_accelerator_uvm.sv`: clock, reset, DUT, interface, and `run_test()`.

The configuration package currently matches the integrated 2x2 DUT:

```systemverilog
DATA_SIZE = 8
ACC_SIZE = 32
MATRIX_SIZE = 2
```

## UCLA VCS regression

The regression script configures these UCLA installations automatically:

```text
VCS:   /home/apps3/Synopsys/VCS/vT-2022.06-1
Verdi: /home/apps3/Synopsys/Verdi/vT-2022.06-SP1
```

Copy the project to:

```text
/home/nadersb/ucla-tapeout/tle/systolic_array
```

Then connect to the server and run:

```bash
ssh nadersb@164.67.204.164
cd /home/nadersb/ucla-tapeout/tle/systolic_array
chmod +x testbenches/uvm/run_vcs_regression.sh
./testbenches/uvm/run_vcs_regression.sh
```

The script compiles once and runs:

```text
accelerator_smoke_test, seed 1
accelerator_random_test, seed 11
accelerator_random_test, seed 29
accelerator_random_test, seed 47
```

Override the number of randomized transactions with:

```bash
NUM_TRANSACTIONS=100 ./testbenches/uvm/run_vcs_regression.sh
```

Override the build directory or VCS executable with:

```bash
BUILD_DIR=/tmp/my_accel_uvm \
VCS_BIN=/path/to/vcs \
./testbenches/uvm/run_vcs_regression.sh
```

The default server build directory is `vcs_build/` under the copied project.
Logs, compiled simulation files, and the merged VCS coverage database are
written there.

After compilation, open the design in Verdi with:

```bash
/home/apps3/Synopsys/Verdi/vT-2022.06-SP1/bin/verdi \
  -simflow \
  -dbdir vcs_build/simv.daidir
```

## What a passing regression establishes

A passing run shows that:

- Directed and constrained-random matrices complete through the full
  LOAD/COMPUTE/STORE/DONE flow.
- The stored output agrees with an independent matrix-multiplication model.
- Consecutive operations do not retain stale PE data.
- ReLU clamps negative accumulated results to zero when enabled.
- ReLU-disabled operations preserve negative accumulated results.
- Controller control outputs obey their state contracts.
- Key controller transitions and the final storage handshake are asserted.
- Every controller state and both ReLU modes are sampled by functional
  coverage.

This is functional verification. VCS simulation does not establish synthesis
timing or maximum clock frequency; those require synthesis and static timing
analysis.
