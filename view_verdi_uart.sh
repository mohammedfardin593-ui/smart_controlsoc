#!/bin/bash
# =============================================================================
# Launch Synopsys Verdi for UART End-to-End Verification Waveform Inspection
# Automatically opens tb_soc_uvm_top.fsdb with pre-configured signal groups
# =============================================================================

export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f "tb_soc_uvm_top.fsdb" ]; then
    echo "ERROR: tb_soc_uvm_top.fsdb not found! Please run ./run_soc_uvm.sh uart_connectivity_test first."
    exit 1
fi

echo "=================================================================="
echo "   Launching Synopsys Verdi with tb_soc_uvm_top.fsdb              "
echo "   Loading Signal Session : uart_waves.rc                         "
echo "=================================================================="

verdi -ssf tb_soc_uvm_top.fsdb -sswr uart_waves.rc -f tb/soc_uvm/filelist_soc_uvm.f &
