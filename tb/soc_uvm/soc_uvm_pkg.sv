// =============================================================================
// Smart ControlSoC - SoC UVM Verification Package
// Aggregates the 5 external peripheral VIP packages from Smart_ControlSoC_Testplan.csv
// (UART, GPIO, I2C, SPI, PWM)
// =============================================================================

`ifndef SOC_UVM_PKG_SV
`define SOC_UVM_PKG_SV

`include "uvm_macros.svh"

package soc_uvm_pkg;
    import uvm_pkg::*;

    // Available External Interface VIP Packages
    import uart_vip_pkg::*;
    import gpio_vip_pkg::*;
    import i2c_vip_pkg::*;
    import spi_vip_pkg::*;
    import pwm_vip_pkg::*;

    // SoC-Level UVM Components
    `include "soc_config.sv"
    `include "soc_virtual_sequencer.sv"
    `include "soc_virtual_sequence.sv"
    `include "uart_connectivity_sequence.sv"
    `include "soc_env.sv"
    `include "soc_test.sv"
    `include "uart_connectivity_test.sv"
    `include "gpio_test.sv"
    `include "i2c_test.sv"
    `include "pwm_test.sv"
    `include "spi_test.sv"

endpackage : soc_uvm_pkg

`endif // SOC_UVM_PKG_SV
