// =============================================================================
// Smart ControlSoC - Top-Level SoC UVM Testbench (tb_soc_uvm_top)
// Instantiates the actual SoC DUT (smart_controlsoc_top as soc_dut)
// and connects the 5 external interfaces from Smart_ControlSoC_Testplan.csv
// (UART, GPIO, I2C, SPI, PWM) and the CPU BFM interface.
// =============================================================================

`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_soc_uvm_top;

    import uvm_pkg::*;
    import soc_uvm_pkg::*;

    // -------------------------------------------------------------------------
    // System Clock & Reset Generation
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD = 10; // 100 MHz System Clock (10ns period)
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam STRB_WIDTH = DATA_WIDTH / 8;
    localparam ID_WIDTH   = 12;

    logic sys_clk;
    logic sys_rst_n;

    initial begin
        sys_clk = 1'b0;
        forever #(CLK_PERIOD / 2) sys_clk = ~sys_clk;
    end

    initial begin
        sys_rst_n = 1'b0;
        #(CLK_PERIOD * 10);
        sys_rst_n = 1'b1;
        $display("[%0t ns] [TB_TOP] System Reset De-asserted.", $time);
    end

    // -------------------------------------------------------------------------
    // External VIP Interface Instantiations (5 Interfaces from Testplan)
    // -------------------------------------------------------------------------
    uart_vip_if uart_vif (.clk(sys_clk), .rst_n(sys_rst_n));
    gpio_vip_if gpio_vif (.clk(sys_clk), .rst_n(sys_rst_n));
    i2c_vip_if  i2c_vif  (.clk(sys_clk), .rst_n(sys_rst_n));
    spi_vip_if  spi_vif  (.clk(sys_clk), .rst_n(sys_rst_n));
    pwm_vip_if  pwm_vif  (.clk(sys_clk), .rst_n(sys_rst_n));

    // CPU Bus Functional Model (BFM) Interface (wraps VeeR CPU LSU AXI tasks)
    cpu_bfm_if  cpu_vif  (.clk(sys_clk), .rst_n(sys_rst_n));

    // Open-drain pull-ups for I2C bus (SCL & SDA)
    pullup (i2c_vif.i2c_scl_io);
    pullup (i2c_vif.i2c_sda_io);

    // I2C Slave Model (reused from rtl/i2c_directory/tb/i2c_slave_model.v)
    i2c_slave_model #(
        .I2C_ADR(7'b001_0000)
    ) i2c_slave_inst (
        .scl(i2c_vif.i2c_scl_io),
        .sda(i2c_vif.i2c_sda_io)
    );

    // -------------------------------------------------------------------------
    // Top-Level Interrupt & Interconnect Wires
    // -------------------------------------------------------------------------
    wire uart_interrupt_o;
    wire gpio_interrupt_o;
    wire i2c_interrupt_o;
    wire timer_interrupt_o;
    wire dma_done_interrupt_o;
    wire dma_error_interrupt_o;

    assign uart_interrupt_o = uart_vif.uart_interrupt_o;

    // -------------------------------------------------------------------------
    // Actual SoC DUT Instantiation (Instance Name: soc_dut)
    // -------------------------------------------------------------------------
    smart_controlsoc_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) soc_dut (
        .sys_clk             (sys_clk),
        .sys_rst_n           (sys_rst_n),

        // UART External Pins -> UART VIP Interface
        .uart_rx_i           (uart_vif.uart_rx_i),
        .uart_tx_o           (uart_vif.uart_tx_o),
        .uart_interrupt_o    (uart_vif.uart_interrupt_o),

        // SPI External Pins -> SPI VIP Interface
        .spi_clk_o           (spi_vif.spi_clk_o),
        .spi_cs_n_o          (spi_vif.spi_cs_n_o),
        .spi_mosi_o          (spi_vif.spi_mosi_o),
        .spi_miso_i          (spi_vif.spi_miso_i),

        // I2C External Pins -> I2C VIP Interface
        .i2c_scl_io          (i2c_vif.i2c_scl_io),
        .i2c_sda_io          (i2c_vif.i2c_sda_io),
        .i2c_interrupt_o     (i2c_interrupt_o),

        // PWM External Pin -> PWM VIP Interface
        .pwm_out_o           (pwm_vif.pwm_out_o),

        // GPIO External Pins -> GPIO VIP Interface
        .gpio_io             (gpio_vif.gpio_io),
        .gpio_interrupt_o    (gpio_interrupt_o),

        // Hardware Timer External Interrupt Pin
        .timer_interrupt_o   (timer_interrupt_o),

        // DMA Dedicated AXI4-Lite CSR Port (Safe Tie-offs for External Slave Port)
        .dma_csr_awaddr_i    ({ADDR_WIDTH{1'b0}}),
        .dma_csr_awprot_i    (3'b000),
        .dma_csr_awvalid_i   (1'b0),
        .dma_csr_awready_o   (),
        .dma_csr_wdata_i     ({DATA_WIDTH{1'b0}}),
        .dma_csr_wstrb_i     ({STRB_WIDTH{1'b0}}),
        .dma_csr_wvalid_i    (1'b0),
        .dma_csr_wready_o    (),
        .dma_csr_bresp_o     (),
        .dma_csr_bvalid_o    (),
        .dma_csr_bready_i    (1'b1),
        .dma_csr_araddr_i    ({ADDR_WIDTH{1'b0}}),
        .dma_csr_arprot_i    (3'b000),
        .dma_csr_arvalid_i   (1'b0),
        .dma_csr_arready_o   (),
        .dma_csr_rdata_o     (),
        .dma_csr_rresp_o     (),
        .dma_csr_rvalid_o    (),
        .dma_csr_rready_i    (1'b1),

        // DMA Interrupts
        .dma_done_interrupt_o(dma_done_interrupt_o),
        .dma_error_interrupt_o(dma_error_interrupt_o)
    );

    // -------------------------------------------------------------------------
    // Waveform Dumping for Synopsys VCS / Verdi
    // -------------------------------------------------------------------------
    initial begin
        `ifdef FSDB
            $fsdbDumpfile("tb_soc_uvm_top.fsdb");
            $fsdbDumpvars(0, tb_soc_uvm_top);
            $display("[%0t ns] [VCS/VERDI] FSDB waveform dumping enabled -> tb_soc_uvm_top.fsdb", $time);
        `endif
    end

    // -------------------------------------------------------------------------
    // UVM Configuration DB Setup & Test Launch
    // -------------------------------------------------------------------------
    initial begin
        soc_config cfg = soc_config::type_id::create("soc_cfg");

        // Assign virtual interface handles to soc_config
        cfg.uart_vif = uart_vif;
        cfg.gpio_vif = gpio_vif;
        cfg.i2c_vif  = i2c_vif;
        cfg.spi_vif  = spi_vif;
        cfg.pwm_vif  = pwm_vif;
        cfg.cpu_vif  = cpu_vif;

        // Configure Active / Passive modes
        cfg.uart_is_active = UVM_ACTIVE;
        cfg.gpio_is_active = UVM_ACTIVE;
        cfg.i2c_is_active  = UVM_ACTIVE;
        cfg.spi_is_active  = UVM_ACTIVE;
        cfg.pwm_is_active  = UVM_PASSIVE;

        // Publish soc_config to UVM config database
        uvm_config_db#(soc_config)::set(null, "*", "soc_cfg", cfg);

        // Also publish virtual interfaces individually as backup/direct queries
        uvm_config_db#(virtual uart_vip_if)::set(null, "*", "uart_vif", uart_vif);
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "gpio_vif", gpio_vif);
        uvm_config_db#(virtual i2c_vip_if)::set(null, "*", "i2c_vif",  i2c_vif);
        uvm_config_db#(virtual spi_vip_if)::set(null, "*", "spi_vif",  spi_vif);
        uvm_config_db#(virtual pwm_vip_if)::set(null, "*", "pwm_vif",  pwm_vif);
        uvm_config_db#(virtual cpu_bfm_if)::set(null, "*", "cpu_bfm_vif", cpu_vif);

        // Run the UVM test specified on command line (defaults to soc_test)
        run_test("soc_test");
    end

endmodule : tb_soc_uvm_top
