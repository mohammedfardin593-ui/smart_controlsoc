// =============================================================================
// Smart ControlSoC - SoC Virtual Sequencer
// Coordination point for external interface VIP sequencers (UART, GPIO, I2C, SPI, PWM)
// =============================================================================

`ifndef SOC_VIRTUAL_SEQUENCER_SV
`define SOC_VIRTUAL_SEQUENCER_SV

class soc_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(soc_virtual_sequencer)

    // Handles to the 5 External Interface VIP Sequencers from Testplan
    uart_vip_sequencer uart_seqr;
    gpio_vip_sequencer gpio_seqr;
    i2c_vip_sequencer  i2c_seqr;
    spi_vip_sequencer  spi_seqr;
    pwm_vip_sequencer  pwm_seqr;

    function new(string name = "soc_virtual_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Building soc_virtual_sequencer for external interfaces...", UVM_HIGH)
    endfunction

endclass : soc_virtual_sequencer

`endif // SOC_VIRTUAL_SEQUENCER_SV
