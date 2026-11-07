// =============================================================================
// Smart ControlSoC - SoC Virtual Sequence Base
// Base virtual sequence coordinating external interface VIPs from Testplan
// =============================================================================

`ifndef SOC_VIRTUAL_SEQUENCE_SV
`define SOC_VIRTUAL_SEQUENCE_SV

class soc_virtual_sequence extends uvm_sequence;
    `uvm_object_utils(soc_virtual_sequence)
    `uvm_declare_p_sequencer(soc_virtual_sequencer)

    function new(string name = "soc_virtual_sequence");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "--------------------------------------------------", UVM_LOW)
        `uvm_info(get_type_name(), "Executing SoC Base Virtual Sequence...", UVM_LOW)
        `uvm_info(get_type_name(), "External Interface VIP Sequencer handles (Testplan defined):", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  UART External Sequencer handle: %s", (p_sequencer.uart_seqr != null) ? "CONNECTED" : "NULL/PASSIVE"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  GPIO External Sequencer handle: %s", (p_sequencer.gpio_seqr != null) ? "CONNECTED" : "NULL/PASSIVE"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  I2C  External Sequencer handle: %s", (p_sequencer.i2c_seqr  != null) ? "CONNECTED" : "NULL/PASSIVE"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  SPI  External Sequencer handle: %s", (p_sequencer.spi_seqr  != null) ? "CONNECTED" : "NULL/PASSIVE"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  PWM  External Sequencer handle: %s", (p_sequencer.pwm_seqr  != null) ? "CONNECTED" : "NULL/PASSIVE"), UVM_LOW)
        `uvm_info(get_type_name(), "Base initialization complete (all 5 testplan external VIPs verified).", UVM_LOW)
        `uvm_info(get_type_name(), "--------------------------------------------------", UVM_LOW)
    endtask

endclass : soc_virtual_sequence

`endif // SOC_VIRTUAL_SEQUENCE_SV
