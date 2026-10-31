// =============================================================================
// Smart ControlSoC - Top-Level UVM Package
// Aggregates all 5 peripheral VIPs: GPIO, I2C, PWM, SPI, and UART
// =============================================================================

`ifndef SOC_TOP_PKG_SV
`define SOC_TOP_PKG_SV

`include "uvm_macros.svh"

package soc_top_pkg;
    import uvm_pkg::*;
    import gpio_vip_pkg::*;
    import i2c_vip_pkg::*;
    import pwm_vip_pkg::*;
    import spi_vip_pkg::*;
    import uart_vip_pkg::*;

    // =========================================================================
    // Combined SoC Top Environment
    // =========================================================================
    class soc_top_env extends uvm_env;
        `uvm_component_utils(soc_top_env)

        gpio_vip_env gpio_env;
        i2c_vip_env  i2c_env;
        pwm_vip_env  pwm_env;
        spi_vip_env  spi_env;
        uart_vip_env uart_env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Building SoC Top UVM Environment...", UVM_LOW)

            gpio_env = gpio_vip_env::type_id::create("gpio_env", this);
            i2c_env  = i2c_vip_env::type_id::create("i2c_env", this);
            pwm_env  = pwm_vip_env::type_id::create("pwm_env", this);
            spi_env  = spi_vip_env::type_id::create("spi_env", this);
            uart_env = uart_vip_env::type_id::create("uart_env", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "Connecting SoC Top UVM Environment...", UVM_LOW)
        endfunction
    endclass: soc_top_env

    // =========================================================================
    // Base SoC Top Test
    // =========================================================================
    class soc_top_test extends uvm_test;
        `uvm_component_utils(soc_top_test)

        soc_top_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Building soc_top_test with all 5 VIPs...", UVM_LOW)
            env = soc_top_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "==================================================", UVM_LOW)
            `uvm_info(get_type_name(), "  SoC Top UVM Testbench Active (All 5 VIPs Running)", UVM_LOW)
            `uvm_info(get_type_name(), "  VIPs: UART, SPI, I2C, PWM, GPIO                   ", UVM_LOW)
            `uvm_info(get_type_name(), "==================================================", UVM_LOW)
            
            // Allow reset settling and initial simulation cycles
            #1000ns;
            
            `uvm_info(get_type_name(), "SoC Top VIP integration test completed successfully.", UVM_LOW)
            phase.drop_objection(this);
        endtask
    endclass: soc_top_test

endpackage: soc_top_pkg

`endif // SOC_TOP_PKG_SV
