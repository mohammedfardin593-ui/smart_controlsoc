#!/bin/bash
# =============================================================================
# Smart ControlSoC - SoC-Level UVM Verification Runner (tb_soc_uvm_top)
# Compiles & executes tb_soc_uvm_top integrating UART, GPIO, I2C, SPI, PWM VIPs
# =============================================================================

set -e

# Setup Synopsys EDA environment
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TEST_NAME="soc_test"
EXTRA_ARGS=()

for arg in "$@"; do
    if [[ "$arg" == +UVM_TESTNAME=* ]]; then
        TEST_NAME="${arg#+UVM_TESTNAME=}"
    elif [[ "$arg" == "soc_test" || "$arg" == "uart_connectivity_test" || "$arg" == "gpio_test" || "$arg" == "i2c_test" || "$arg" == "pwm_test" || "$arg" == "spi_test" ]]; then
        TEST_NAME="$arg"
    else
        EXTRA_ARGS+=("$arg")
    fi
done

echo "=================================================================="
echo "   [1/2] Compiling SoC-Level UVM Testbench (tb_soc_uvm_top)       "
echo "=================================================================="
vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm \
    -top tb_soc_uvm_top \
    -P "$VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab" "$VERDI_HOME/share/PLI/VCS/LINUX64/pli.a" \
    +define+FSDB \
    -debug_access+all \
    -f tb/soc_uvm/filelist_soc_uvm.f \
    -o simv_soc_uvm

echo ""
echo "=================================================================="
echo "   [2/2] Running SoC UVM Test: $TEST_NAME                        "
echo "=================================================================="
./simv_soc_uvm +UVM_TESTNAME="$TEST_NAME" -no_save "${EXTRA_ARGS[@]}"

echo ""
echo "=================================================================="
echo "   SoC UVM Simulation Complete! FSDB Ready: tb_soc_uvm_top.fsdb  "
echo "   To view in Verdi:                                             "
echo "       verdi -ssf tb_soc_uvm_top.fsdb &                          "
echo "=================================================================="
