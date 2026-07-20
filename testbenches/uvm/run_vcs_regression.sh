#!/usr/bin/env bash
set -euo pipefail

# UCLA school server Synopsys setup.
export SYNOPSYS="${SYNOPSYS:-/usr/apps/synopsys}"
export VCS_HOME="${VCS_HOME:-/home/apps3/Synopsys/VCS/vT-2022.06-1}"
export VERDI_HOME="${VERDI_HOME:-/home/apps3/Synopsys/Verdi/vT-2022.06-SP1}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-5281@lm-cadence.seas.ucla.edu}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-1784@lm-synopsys.seas.ucla.edu}"
export PATH="${VCS_HOME}/bin:${VCS_HOME}/amd64/bin:${VERDI_HOME}/bin:${PATH}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${REPO_ROOT}/vcs_build}"
VCS_BIN="${VCS_BIN:-${VCS_HOME}/bin/vcs}"

cd "${REPO_ROOT}"
mkdir -p "${BUILD_DIR}"

if ! command -v "${VCS_BIN}" >/dev/null 2>&1; then
    echo "VCS was not found at: ${VCS_BIN}" >&2
    echo "Check that the UCLA VCS installation is mounted on this server." >&2
    echo "You can override it with VCS_BIN=/path/to/vcs." >&2
    exit 127
fi

echo "Project root: ${REPO_ROOT}"
echo "VCS executable: ${VCS_BIN}"
echo "Build directory: ${BUILD_DIR}"
echo "Compiling UVM accelerator testbench..."
"${VCS_BIN}" \
    -full64 \
    -sverilog \
    -ntb_opts uvm-1.2 \
    -timescale=1ns/1ps \
    -assert svaext \
    -debug_access+all \
    -kdb \
    -lca \
    -cm line+cond+fsm+tgl+branch+assert \
    -cm_dir "${BUILD_DIR}/regression.vdb" \
    -Mdir="${BUILD_DIR}/csrc" \
    -f testbenches/uvm/accelerator_uvm.f \
    -top tb_accelerator_uvm \
    -o "${BUILD_DIR}/simv" \
    -l "${BUILD_DIR}/compile.log"

tests=(
    "accelerator_smoke_test:1"
    "accelerator_random_test:11"
    "accelerator_random_test:29"
    "accelerator_random_test:47"
)

failures=0

for entry in "${tests[@]}"; do
    test_name="${entry%%:*}"
    seed="${entry##*:}"
    run_name="${test_name}_seed_${seed}"
    log_file="${BUILD_DIR}/${run_name}.log"

    echo "Running ${test_name} with seed ${seed}..."

    set +e
    "${BUILD_DIR}/simv" \
        +UVM_TESTNAME="${test_name}" \
        +UVM_VERBOSITY=UVM_MEDIUM \
        +UVM_MAX_QUIT_COUNT=1,YES \
        +NUM_TRANSACTIONS="${NUM_TRANSACTIONS:-25}" \
        +ntb_random_seed="${seed}" \
        -cm line+cond+fsm+tgl+branch+assert \
        -cm_name "${run_name}" \
        -cm_dir "${BUILD_DIR}/regression.vdb" \
        -l "${log_file}"
    run_status=$?
    set -e

    if (( run_status != 0 )) ||
       grep -Eq 'UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9]' "${log_file}"; then
        echo "FAIL: ${run_name} (see ${log_file})" >&2
        failures=$((failures + 1))
    else
        echo "PASS: ${run_name}"
    fi
done

if (( failures != 0 )); then
    echo "Regression failed: ${failures} run(s) failed." >&2
    exit 1
fi

echo "All UVM regression runs passed."
echo "Logs and coverage database: ${BUILD_DIR}"
echo "Open the compiled design in Verdi with:"
echo "  ${VERDI_HOME}/bin/verdi -simflow -dbdir ${BUILD_DIR}/simv.daidir"
