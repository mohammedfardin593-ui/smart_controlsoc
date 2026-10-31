// =============================================================================
// Smart ControlSoC - Top-Level Integrated Testbench (tb_top)
// Combines all generated peripheral VIPs: GPIO, I2C, PWM, SPI, and UART
// Connects VIP interfaces to SoC DUT (smart_controlsoc_top)
// =============================================================================

`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top;
    import uvm_pkg::*;
    import gpio_vip_pkg::*;
    import i2c_vip_pkg::*;
    import pwm_vip_pkg::*;
    import spi_vip_pkg::*;
    import uart_vip_pkg::*;
    import soc_top_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam STRB_WIDTH = (DATA_WIDTH/8);
    localparam ID_WIDTH   = 12;
    localparam CLK_PERIOD = 10; // 100 MHz clock

    // -------------------------------------------------------------------------
    // Global Clock & Reset Generation
    // -------------------------------------------------------------------------
    logic sys_clk;
    logic sys_rst_n;

    initial begin
        sys_clk = 1'b0;
        forever #(CLK_PERIOD/2) sys_clk = ~sys_clk;
    end

    initial begin
        sys_rst_n = 1'b0;
        #(CLK_PERIOD * 10);
        sys_rst_n = 1'b1;
        $display("[%0t ns] [TB_TOP] System Reset Deasserted.", $time);
    end

    // -------------------------------------------------------------------------
    // VIP Interface Instantiations
    // -------------------------------------------------------------------------
    gpio_vip_if gpio_vif (.clk(sys_clk), .rst_n(sys_rst_n));
    i2c_vip_if  i2c_vif  (.clk(sys_clk), .rst_n(sys_rst_n));
    pwm_vip_if  pwm_vif  (.clk(sys_clk), .rst_n(sys_rst_n));
    spi_vip_if  spi_vif  (.clk(sys_clk), .rst_n(sys_rst_n));
    uart_vip_if uart_vif (.clk(sys_clk), .rst_n(sys_rst_n));

    // -------------------------------------------------------------------------
    // Top-Level Interrupt & Interconnect Wires
    // -------------------------------------------------------------------------
    wire uart_interrupt_o;
    wire gpio_interrupt_o;
    wire i2c_interrupt_o;
    wire timer_interrupt_o;
    wire dma_done_interrupt_o;
    wire dma_error_interrupt_o;

    // Open-drain pull-ups for I2C SCL & SDA
    pullup (i2c_vif.i2c_scl_io);
    pullup (i2c_vif.i2c_sda_io);

    // -------------------------------------------------------------------------
    // DUT (Smart ControlSoC Top) Instantiation
    // -------------------------------------------------------------------------
    smart_controlsoc_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .sys_clk             (sys_clk),
        .sys_rst_n           (sys_rst_n),

        // UART VIP Interface Connections
        .uart_rx_i           (uart_vif.uart_rx_i),
        .uart_tx_o           (uart_vif.uart_tx_o),
        .uart_interrupt_o    (uart_interrupt_o),

        // SPI VIP Interface Connections
        .spi_clk_o           (spi_vif.spi_clk_o),
        .spi_cs_n_o          (spi_vif.spi_cs_n_o),
        .spi_mosi_o          (spi_vif.spi_mosi_o),
        .spi_miso_i          (spi_vif.spi_miso_i),

        // I2C VIP Interface Connections
        .i2c_scl_io          (i2c_vif.i2c_scl_io),
        .i2c_sda_io          (i2c_vif.i2c_sda_io),
        .i2c_interrupt_o     (i2c_interrupt_o),

        // PWM VIP Interface Connection
        .pwm_out_o           (pwm_vif.pwm_out_o),

        // GPIO VIP Interface Connection
        .gpio_io             (gpio_vif.gpio_io),
        .gpio_interrupt_o    (gpio_interrupt_o),

        // Hardware Timer Interrupt
        .timer_interrupt_o   (timer_interrupt_o),

        // DMA Dedicated AXI4-Lite CSR Port (Tied to Idle)
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
    // Waveform Dumping for Synopsys VCS & Verdi
    // -------------------------------------------------------------------------
    initial begin
        `ifdef FSDB
            $fsdbDumpfile("tb_top.fsdb");
            $fsdbDumpvars(0, tb_top);
            $display("[%0t ns] [VCS/VERDI] FSDB waveform dumping enabled -> tb_top.fsdb", $time);
        `endif
    end

    // -------------------------------------------------------------------------
    // UVM Configuration DB Registration & Simulation Launch
    // -------------------------------------------------------------------------
    initial begin
        // Set virtual interfaces in UVM config database for all 5 VIPs
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*gpio_env*", "vif", gpio_vif);
        uvm_config_db#(virtual i2c_vip_if)::set(null, "*i2c_env*",  "vif", i2c_vif);
        uvm_config_db#(virtual pwm_vip_if)::set(null, "*pwm_env*",  "vif", pwm_vif);
        uvm_config_db#(virtual spi_vip_if)::set(null, "*spi_env*",  "vif", spi_vif);
        uvm_config_db#(virtual uart_vip_if)::set(null, "*uart_env*", "vif", uart_vif);

        // Run the combined SoC UVM Test
        run_test("soc_top_test");
    end

endmodule: tb_top
