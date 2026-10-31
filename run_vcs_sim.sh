#!/bin/bash
# =============================================================================
# Smart ControlSoC - VCS Compilation & Simulation Runner Script
# Runs the C firmware test (main1.hex) and generates waveforms for VCS/Verdi
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
echo "   [1/3] Compiling Smart ControlSoC with Synopsys VCS            "
echo "=================================================================="
vcs -full64 -sverilog -timescale=1ns/1ps \
    -top tb_smart_controlsoc_top \
    -P "$VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab" "$VERDI_HOME/share/PLI/VCS/LINUX64/pli.a" \
    +define+FSDB \
    -debug_access+all \
    -f filelist.f \
    tb/tb_smart_controlsoc_top.sv -o simv

echo ""
echo "=================================================================="
echo "   [2/3] Executing VCS Simulation (C Test Verification)          "
echo "=================================================================="
./simv "$@"

echo ""
echo "=================================================================="
echo "   [3/3] Simulation Complete & Waveforms Ready                   "
echo "=================================================================="
echo "Waveform file: $SCRIPT_DIR/smart_controlsoc.fsdb"
echo "To view waveforms in Verdi, run:"
echo "    verdi -ssf smart_controlsoc.fsdb &"
echo "=================================================================="
