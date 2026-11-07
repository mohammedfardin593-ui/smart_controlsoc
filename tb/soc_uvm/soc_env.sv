// =============================================================================
// Smart ControlSoC - SoC Verification Environment
// Aggregates the 5 external interface VIP agents (UART, GPIO, I2C, SPI, PWM)
// as defined in Smart_ControlSoC_Testplan.csv and the UART Scoreboard
// =============================================================================

`ifndef SOC_ENV_SV
`define SOC_ENV_SV

class soc_env extends uvm_env;
    `uvm_component_utils(soc_env)

    // Configuration handle
    soc_config cfg;

    // Available External Interface VIP Agents from Testplan
    uart_vip_agent         uart_agent;
    gpio_vip_agent         gpio_agent;
    i2c_vip_agent          i2c_agent;
    spi_vip_agent          spi_agent;
    pwm_vip_agent          pwm_agent;

    // Scoreboards for end-to-end verification
    uart_vip_scoreboard    uart_sb;
    gpio_vip_scoreboard    gpio_sb;
    i2c_vip_scoreboard     i2c_sb;
    pwm_vip_scoreboard     pwm_sb;
    spi_vip_scoreboard     spi_sb;

    // SoC Virtual Sequencer
    soc_virtual_sequencer  v_sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Building SoC verification environment (soc_env)...", UVM_LOW)

        // Retrieve SoC configuration object
        if (!uvm_config_db#(soc_config)::get(this, "", "soc_cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "soc_config object not found in uvm_config_db!")
        end

        // Validate configuration
        if (!cfg.validate()) begin
            `uvm_fatal(get_type_name(), "soc_config validation failed!")
        end

        cfg.print_config();

        // 1. Configure and pass active/passive status to each external VIP agent
        uvm_config_db#(uvm_active_passive_enum)::set(this, "uart_agent", "is_active", cfg.uart_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "gpio_agent", "is_active", cfg.gpio_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "i2c_agent",  "is_active", cfg.i2c_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "spi_agent",  "is_active", cfg.spi_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "pwm_agent",  "is_active", cfg.pwm_is_active);

        // 2. Pass virtual interfaces to agent sub-components (driver and monitor)
        uvm_config_db#(virtual uart_vip_if)::set(this, "uart_agent.*", "vif", cfg.uart_vif);
        uvm_config_db#(virtual gpio_vip_if)::set(this, "gpio_agent.*", "vif", cfg.gpio_vif);
        uvm_config_db#(virtual i2c_vip_if)::set(this, "i2c_agent.*",  "vif", cfg.i2c_vif);
        uvm_config_db#(virtual spi_vip_if)::set(this, "spi_agent.*",  "vif", cfg.spi_vif);
        uvm_config_db#(virtual pwm_vip_if)::set(this, "pwm_agent.*",  "vif", cfg.pwm_vif);

        // 3. Instantiate the 5 external interface VIP agents
        uart_agent = uart_vip_agent::type_id::create("uart_agent", this);
        gpio_agent = gpio_vip_agent::type_id::create("gpio_agent", this);
        i2c_agent  = i2c_vip_agent::type_id::create("i2c_agent", this);
        spi_agent  = spi_vip_agent::type_id::create("spi_agent", this);
        pwm_agent  = pwm_vip_agent::type_id::create("pwm_agent", this);

        // 4. Instantiate UART, GPIO, I2C, PWM, and SPI Scoreboards
        uart_sb = uart_vip_scoreboard::type_id::create("uart_sb", this);
        gpio_sb = gpio_vip_scoreboard::type_id::create("gpio_sb", this);
        i2c_sb  = i2c_vip_scoreboard::type_id::create("i2c_sb", this);
        pwm_sb  = pwm_vip_scoreboard::type_id::create("pwm_sb", this);
        spi_sb  = spi_vip_scoreboard::type_id::create("spi_sb", this);

        // 5. Instantiate Virtual Sequencer
        v_sequencer = soc_virtual_sequencer::type_id::create("v_sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), "Connecting external VIP sequencers to soc_virtual_sequencer...", UVM_LOW)

        // Connect individual agent sequencers to virtual sequencer handles
        if (uart_agent.get_is_active() == UVM_ACTIVE) begin
            v_sequencer.uart_seqr = uart_agent.seqr;
            `uvm_info(get_type_name(), "  Connected UART VIP sequencer -> v_sequencer.uart_seqr", UVM_LOW)
            // Connect UART VIP Driver analysis port to Scoreboard
            uart_agent.drv.drv_ap.connect(uart_sb.drv_imp);
            `uvm_info(get_type_name(), "  Connected UART VIP Driver analysis port -> uart_sb.drv_imp", UVM_LOW)
        end
        if (gpio_agent.get_is_active() == UVM_ACTIVE) begin
            v_sequencer.gpio_seqr = gpio_agent.seqr;
            `uvm_info(get_type_name(), "  Connected GPIO VIP sequencer -> v_sequencer.gpio_seqr", UVM_LOW)
            gpio_agent.drv.drv_ap.connect(gpio_sb.drv_imp);
            `uvm_info(get_type_name(), "  Connected GPIO VIP Driver analysis port -> gpio_sb.drv_imp", UVM_LOW)
        end
        gpio_agent.mon.ap.connect(gpio_sb.mon_imp);
        `uvm_info(get_type_name(), "  Connected GPIO VIP Monitor analysis port -> gpio_sb.mon_imp", UVM_LOW)
        if (i2c_agent.get_is_active() == UVM_ACTIVE) begin
            v_sequencer.i2c_seqr = i2c_agent.seqr;
            `uvm_info(get_type_name(), "  Connected I2C VIP sequencer  -> v_sequencer.i2c_seqr", UVM_LOW)
        end
        i2c_agent.mon.ap.connect(i2c_sb.mon_imp);
        `uvm_info(get_type_name(), "  Connected I2C VIP Monitor analysis port -> i2c_sb.mon_imp", UVM_LOW)
        if (spi_agent.get_is_active() == UVM_ACTIVE) begin
            v_sequencer.spi_seqr = spi_agent.seqr;
            `uvm_info(get_type_name(), "  Connected SPI VIP sequencer  -> v_sequencer.spi_seqr", UVM_LOW)
            spi_agent.drv.drv_ap.connect(spi_sb.drv_imp);
            `uvm_info(get_type_name(), "  Connected SPI VIP Driver analysis port -> spi_sb.drv_imp", UVM_LOW)
        end
        spi_agent.mon.ap.connect(spi_sb.mon_imp);
        `uvm_info(get_type_name(), "  Connected SPI VIP Monitor analysis port -> spi_sb.mon_imp", UVM_LOW)
        if (pwm_agent.get_is_active() == UVM_ACTIVE) begin
            v_sequencer.pwm_seqr = pwm_agent.seqr;
            `uvm_info(get_type_name(), "  Connected PWM VIP sequencer  -> v_sequencer.pwm_seqr", UVM_LOW)
        end
        pwm_agent.mon.ap.connect(pwm_sb.mon_imp);
        `uvm_info(get_type_name(), "  Connected PWM VIP Monitor analysis port -> pwm_sb.mon_imp", UVM_LOW)

        // Connect UART VIP Monitor analysis port to Scoreboard
        uart_agent.mon.ap.connect(uart_sb.mon_imp);
        `uvm_info(get_type_name(), "  Connected UART VIP Monitor analysis port -> uart_sb.mon_imp", UVM_LOW)
    endfunction

endclass : soc_env

`endif // SOC_ENV_SV
