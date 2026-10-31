#!/bin/bash
# =============================================================================
# Smart ControlSoC - Top-Level UVM Testbench Runner (tb_top)
# Compiles & executes tb_top combining UART, SPI, I2C, PWM, and GPIO VIPs
# =============================================================================

set -e

# Setup Synopsys EDA environment
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=================================================================="
echo "   Compiling Unified SoC Top UVM Testbench (tb_top)              "
echo "=================================================================="
vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm \
    -top tb_top \
    -P "$VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab" "$VERDI_HOME/share/PLI/VCS/LINUX64/pli.a" \
    +define+FSDB \
    -debug_access+all \
    +incdir+tb \
    +incdir+tb/gpio.vip_uvm_tb \
    +incdir+tb/i2c.vip_uvm_tb \
    +incdir+tb/pwm.vip_uvm_tb \
    +incdir+tb/spi.vip_uvm_tb \
    +incdir+tb/uart.vip_uvm_tb \
    tb/gpio.vip_uvm_tb/gpio_vip_pkg.sv tb/gpio.vip_uvm_tb/gpio_vip_if.sv \
    tb/i2c.vip_uvm_tb/i2c_vip_pkg.sv tb/i2c.vip_uvm_tb/i2c_vip_if.sv \
    tb/pwm.vip_uvm_tb/pwm_vip_pkg.sv tb/pwm.vip_uvm_tb/pwm_vip_if.sv \
    tb/spi.vip_uvm_tb/spi_vip_pkg.sv tb/spi.vip_uvm_tb/spi_vip_if.sv \
    tb/uart.vip_uvm_tb/uart_vip_pkg.sv tb/uart.vip_uvm_tb/uart_vip_if.sv \
    tb/soc_top_pkg.sv \
    -f filelist.f \
    tb/tb_top.sv -o simv_uvm_top

echo ""
echo "=================================================================="
echo "   Running Unified UVM Simulation (soc_top_test)                  "
echo "=================================================================="
./simv_uvm_top +UVM_TESTNAME=soc_top_test "$@"

echo ""
echo "=================================================================="
echo "   Simulation Complete! FSDB Ready: tb_top.fsdb                  "
echo "   To view in Verdi:                                             "
echo "       verdi -ssf tb_top.fsdb &                                  "
echo "=================================================================="
