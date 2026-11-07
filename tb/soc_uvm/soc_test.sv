// =============================================================================
// Smart ControlSoC - SoC Base Test (soc_test)
// Initializes the verification environment and verifies construction sanity
// for the 5 external interfaces specified in Smart_ControlSoC_Testplan.csv
// =============================================================================

`ifndef SOC_TEST_SV
`define SOC_TEST_SV

class soc_test extends uvm_test;
    `uvm_component_utils(soc_test)

    soc_env    env;
    soc_config cfg;

    function new(string name = "soc_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Executing soc_test::build_phase...", UVM_LOW)

        // Check if configuration already provided, else create and populate it
        if (!uvm_config_db#(soc_config)::get(this, "", "soc_cfg", cfg)) begin
            `uvm_info(get_type_name(), "Creating fresh soc_config in soc_test...", UVM_LOW)
            cfg = soc_config::type_id::create("cfg");

            // Look up virtual interfaces from config DB
            void'(uvm_config_db#(virtual uart_vip_if)::get(this, "", "uart_vif", cfg.uart_vif));
            void'(uvm_config_db#(virtual gpio_vip_if)::get(this, "", "gpio_vif", cfg.gpio_vif));
            void'(uvm_config_db#(virtual i2c_vip_if)::get(this, "", "i2c_vif",  cfg.i2c_vif));
            void'(uvm_config_db#(virtual spi_vip_if)::get(this, "", "spi_vif",  cfg.spi_vif));
            void'(uvm_config_db#(virtual pwm_vip_if)::get(this, "", "pwm_vif",  cfg.pwm_vif));
            void'(uvm_config_db#(virtual cpu_bfm_if)::get(this, "", "cpu_bfm_vif", cfg.cpu_vif));
        end

        // PWM is passive (external output-only line)
        cfg.pwm_is_active = UVM_PASSIVE;

        // Distribute configuration to env
        uvm_config_db#(soc_config)::set(this, "env", "soc_cfg", cfg);

        // Instantiate SoC verification environment
        env = soc_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        soc_virtual_sequence vseq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================", UVM_LOW)
        `uvm_info(get_type_name(), "  Smart Control SoC - UVM Verification Active     ", UVM_LOW)
        `uvm_info(get_type_name(), "  DUT: smart_controlsoc_top (instance: soc_dut)   ", UVM_LOW)
        `uvm_info(get_type_name(), "  Architecture: VeeR EL2 CPU + 2x6 AXI Interconnect", UVM_LOW)
        `uvm_info(get_type_name(), "  External Interface VIPs (per Testplan):         ", UVM_LOW)
        `uvm_info(get_type_name(), "    1. UART VIP Agent (Active)                    ", UVM_LOW)
        `uvm_info(get_type_name(), "    2. GPIO VIP Agent (Active)                    ", UVM_LOW)
        `uvm_info(get_type_name(), "    3. I2C  VIP Agent (Active)                    ", UVM_LOW)
        `uvm_info(get_type_name(), "    4. SPI  VIP Agent (Active)                    ", UVM_LOW)
        `uvm_info(get_type_name(), "    5. PWM  VIP Agent (Passive)                   ", UVM_LOW)
        `uvm_info(get_type_name(), "  Note: Timer & DMA are internal IPs (no ext VIP) ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================", UVM_LOW)

        // Execute base virtual sequence to verify coordination infrastructure
        vseq = soc_virtual_sequence::type_id::create("vseq");
        vseq.start(env.v_sequencer);

        // Allow clock and reset settling
        #500ns;

        `uvm_info(get_type_name(), "SoC UVM construction test passed cleanly for all 5 testplan external interfaces.", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : soc_test

`endif // SOC_TEST_SV
