`timescale 1ns/1ps

module smart_controlsoc_top #(
    // AXI4-Lite Parameters (Matching UART, SPI & Interconnect)
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter ID_WIDTH   = 12
)(
    // Global Clock and Reset
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    // UART External Pins
    input  wire        uart_rx_i,
    output wire        uart_tx_o,
    output wire        uart_interrupt_o,

    // SPI External Pins
    output wire        spi_clk_o,
    output wire        spi_cs_n_o,
    output wire        spi_mosi_o,
    input  wire        spi_miso_i
);

    // -------------------------------------------------------------------------
    // RISC-V CPU (VeeR EL2) <-> AXI Interconnect S00 Wires
    // -------------------------------------------------------------------------
    wire [ID_WIDTH-1:0]      s00_axi_awid;
    wire [ADDR_WIDTH-1:0]    s00_axi_awaddr;
    wire [7:0]               s00_axi_awlen;
    wire [2:0]               s00_axi_awsize;
    wire [1:0]               s00_axi_awburst;
    wire                     s00_axi_awlock;
    wire [3:0]               s00_axi_awcache;
    wire [2:0]               s00_axi_awprot;
    wire                     s00_axi_awvalid;
    wire                     s00_axi_awready;
    wire [DATA_WIDTH-1:0]    s00_axi_wdata;
    wire [STRB_WIDTH-1:0]    s00_axi_wstrb;
    wire                     s00_axi_wlast;
    wire                     s00_axi_wvalid;
    wire                     s00_axi_wready;
    wire [ID_WIDTH-1:0]      s00_axi_bid;
    wire [1:0]               s00_axi_bresp;
    wire                     s00_axi_bvalid;
    wire                     s00_axi_bready;
    wire [ID_WIDTH-1:0]      s00_axi_arid;
    wire [ADDR_WIDTH-1:0]    s00_axi_araddr;
    wire [7:0]               s00_axi_arlen;
    wire [2:0]               s00_axi_arsize;
    wire [1:0]               s00_axi_arburst;
    wire                     s00_axi_arlock;
    wire [3:0]               s00_axi_arcache;
    wire [2:0]               s00_axi_arprot;
    wire                     s00_axi_arvalid;
    wire                     s00_axi_arready;
    wire [ID_WIDTH-1:0]      s00_axi_rid;
    wire [DATA_WIDTH-1:0]    s00_axi_rdata;
    wire [1:0]               s00_axi_rresp;
    wire                     s00_axi_rlast;
    wire                     s00_axi_rvalid;
    wire                     s00_axi_rready;

    // CPU LSU uses 64-bit AXI data, bridge to 32-bit interconnect
    wire [63:0] cpu_lsu_wdata;
    wire [7:0]  cpu_lsu_wstrb;
    wire [63:0] cpu_lsu_rdata;

    assign s00_axi_wdata = cpu_lsu_wdata[31:0];
    assign s00_axi_wstrb = cpu_lsu_wstrb[3:0];
    assign cpu_lsu_rdata = {32'h0, s00_axi_rdata};

    // -------------------------------------------------------------------------
    // RISC-V CPU (VeeR EL2) Instantiation
    // -------------------------------------------------------------------------
    el2_veer_wrapper cpu_inst (
        .clk             (sys_clk),
        .rst_l           (sys_rst_n),
        .dbg_rst_l       (sys_rst_n),
        .rst_vec         (31'h0000_0000), // Boot address
        .nmi_int         (1'b0),
        .nmi_vec         (31'h0000_0000),
        .jtag_id         (31'h0000_0000),

        // LSU AXI Interface -> Interconnect S00
        .lsu_axi_awvalid (s00_axi_awvalid),
        .lsu_axi_awready (s00_axi_awready),
        .lsu_axi_awid    (s00_axi_awid),
        .lsu_axi_awaddr  (s00_axi_awaddr),
        .lsu_axi_awlen   (s00_axi_awlen),
        .lsu_axi_awsize  (s00_axi_awsize),
        .lsu_axi_awburst (s00_axi_awburst),
        .lsu_axi_awlock  (s00_axi_awlock),
        .lsu_axi_awcache (s00_axi_awcache),
        .lsu_axi_awprot  (s00_axi_awprot),
        
        .lsu_axi_wvalid  (s00_axi_wvalid),
        .lsu_axi_wready  (s00_axi_wready),
        .lsu_axi_wdata   (cpu_lsu_wdata),
        .lsu_axi_wstrb   (cpu_lsu_wstrb),
        .lsu_axi_wlast   (s00_axi_wlast),
        
        .lsu_axi_bvalid  (s00_axi_bvalid),
        .lsu_axi_bready  (s00_axi_bready),
        .lsu_axi_bresp   (s00_axi_bresp),
        .lsu_axi_bid     (s00_axi_bid),
        
        .lsu_axi_arvalid (s00_axi_arvalid),
        .lsu_axi_arready (s00_axi_arready),
        .lsu_axi_arid    (s00_axi_arid),
        .lsu_axi_araddr  (s00_axi_araddr),
        .lsu_axi_arlen   (s00_axi_arlen),
        .lsu_axi_arsize  (s00_axi_arsize),
        .lsu_axi_arburst (s00_axi_arburst),
        .lsu_axi_arlock  (s00_axi_arlock),
        .lsu_axi_arcache (s00_axi_arcache),
        .lsu_axi_arprot  (s00_axi_arprot),
        
        .lsu_axi_rvalid  (s00_axi_rvalid),
        .lsu_axi_rready  (s00_axi_rready),
        .lsu_axi_rid     (s00_axi_rid),
        .lsu_axi_rdata   (cpu_lsu_rdata),
        .lsu_axi_rresp   (s00_axi_rresp),
        .lsu_axi_rlast   (s00_axi_rlast),
        
        // Tie off IFU AXI
        .ifu_axi_awready (1'b1),
        .ifu_axi_wready  (1'b1),
        .ifu_axi_bvalid  (1'b0),
        .ifu_axi_arready (1'b1),
        .ifu_axi_rvalid  (1'b0),
        
        // Tie off SB AXI
        .sb_axi_awready  (1'b1),
        .sb_axi_wready   (1'b1),
        .sb_axi_bvalid   (1'b0),
        .sb_axi_arready  (1'b1),
        .sb_axi_rvalid   (1'b0),
        
        // Tie off DMA AXI Slave
        .dma_axi_awvalid (1'b0),
        .dma_axi_wvalid  (1'b0),
        .dma_axi_arvalid (1'b0),
        .dma_axi_bready  (1'b1),
        .dma_axi_rready  (1'b1),

        // Clock enables and Interrupts
        .lsu_bus_clk_en  (1'b1),
        .ifu_bus_clk_en  (1'b1),
        .dbg_bus_clk_en  (1'b1),
        .dma_bus_clk_en  (1'b1),
        .timer_int       (1'b0),
        .soft_int        (1'b0),
        .extintsrc_req   (1'b0)
    );

    // -------------------------------------------------------------------------
    // AXI Interconnect Master 0 (M00) <-> UART Slave Wires
    // -------------------------------------------------------------------------
    wire [ID_WIDTH-1:0]      m00_axi_awid;
    wire [ADDR_WIDTH-1:0]    m00_axi_awaddr;
    wire [7:0]               m00_axi_awlen;
    wire [2:0]               m00_axi_awsize;
    wire [1:0]               m00_axi_awburst;
    wire                     m00_axi_awlock;
    wire [3:0]               m00_axi_awcache;
    wire [2:0]               m00_axi_awprot;
    wire                     m00_axi_awvalid;
    wire                     m00_axi_awready;
    wire [DATA_WIDTH-1:0]    m00_axi_wdata;
    wire [STRB_WIDTH-1:0]    m00_axi_wstrb;
    wire                     m00_axi_wlast;
    wire                     m00_axi_wvalid;
    wire                     m00_axi_wready;
    wire [ID_WIDTH-1:0]      m00_axi_bid;
    wire [1:0]               m00_axi_bresp;
    wire                     m00_axi_bvalid;
    wire                     m00_axi_bready;
    wire [ID_WIDTH-1:0]      m00_axi_arid;
    wire [ADDR_WIDTH-1:0]    m00_axi_araddr;
    wire [7:0]               m00_axi_arlen;
    wire [2:0]               m00_axi_arsize;
    wire [1:0]               m00_axi_arburst;
    wire                     m00_axi_arlock;
    wire [3:0]               m00_axi_arcache;
    wire [2:0]               m00_axi_arprot;
    wire                     m00_axi_arvalid;
    wire                     m00_axi_arready;
    wire [ID_WIDTH-1:0]      m00_axi_rid;
    wire [DATA_WIDTH-1:0]    m00_axi_rdata;
    wire [1:0]               m00_axi_rresp;
    wire                     m00_axi_rlast;
    wire                     m00_axi_rvalid;
    wire                     m00_axi_rready;

    // -------------------------------------------------------------------------
    // AXI Interconnect Master 3 (M03) <-> SPI Slave Wires
    // -------------------------------------------------------------------------
    wire [ID_WIDTH-1:0]      m03_axi_awid;
    wire [ADDR_WIDTH-1:0]    m03_axi_awaddr;
    wire [7:0]               m03_axi_awlen;
    wire [2:0]               m03_axi_awsize;
    wire [1:0]               m03_axi_awburst;
    wire                     m03_axi_awlock;
    wire [3:0]               m03_axi_awcache;
    wire [2:0]               m03_axi_awprot;
    wire                     m03_axi_awvalid;
    wire                     m03_axi_awready;
    wire [DATA_WIDTH-1:0]    m03_axi_wdata;
    wire [STRB_WIDTH-1:0]    m03_axi_wstrb;
    wire                     m03_axi_wlast;
    wire                     m03_axi_wvalid;
    wire                     m03_axi_wready;
    wire [ID_WIDTH-1:0]      m03_axi_bid;
    wire [1:0]               m03_axi_bresp;
    wire                     m03_axi_bvalid;
    wire                     m03_axi_bready;
    wire [ID_WIDTH-1:0]      m03_axi_arid;
    wire [ADDR_WIDTH-1:0]    m03_axi_araddr;
    wire [7:0]               m03_axi_arlen;
    wire [2:0]               m03_axi_arsize;
    wire [1:0]               m03_axi_arburst;
    wire                     m03_axi_arlock;
    wire [3:0]               m03_axi_arcache;
    wire [2:0]               m03_axi_arprot;
    wire                     m03_axi_arvalid;
    wire                     m03_axi_arready;
    wire [ID_WIDTH-1:0]      m03_axi_rid;
    wire [DATA_WIDTH-1:0]    m03_axi_rdata;
    wire [1:0]               m03_axi_rresp;
    wire                     m03_axi_rlast;
    wire                     m03_axi_rvalid;
    wire                     m03_axi_rready;

    // -------------------------------------------------------------------------
    // AXI Interconnect 2x6 Instantiation
    // -------------------------------------------------------------------------
    axi_interconnect_wrap_2x6 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        
        // Memory Map Override (Based on system specifications)
        .M00_BASE_ADDR  (32'h2000_0000), // UART Base Address (4KB)
        .M00_ADDR_WIDTH (32'd12),
        
        .M01_BASE_ADDR  (32'h2000_1000), // Timer Base Address (4KB)
        .M01_ADDR_WIDTH (32'd12),
        
        .M02_BASE_ADDR  (32'h2000_2000), // GPIO Base Address (4KB)
        .M02_ADDR_WIDTH (32'd12),
        
        .M03_BASE_ADDR  (32'h2000_3000), // SPI Controller Base Address (4KB)
        .M03_ADDR_WIDTH (32'd12),
        
        .M04_BASE_ADDR  (32'h2000_4000), // I2C Controller Base Address (4KB)
        .M04_ADDR_WIDTH (32'd12),
        
        .M05_BASE_ADDR  (32'h2000_5000), // PWM Generator Base Address (4KB)
        .M05_ADDR_WIDTH (32'd12)
    ) system_interconnect (
        .clk(sys_clk), 
        .rst(~sys_rst_n), // Active high reset required by interconnect wrapper
        
        // Slave 00 Port <- RISC-V CPU
        .s00_axi_awid   (s00_axi_awid),
        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awlen  (s00_axi_awlen),
        .s00_axi_awsize (s00_axi_awsize),
        .s00_axi_awburst(s00_axi_awburst),
        .s00_axi_awlock (s00_axi_awlock),
        .s00_axi_awcache(s00_axi_awcache),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata  (s00_axi_wdata),
        .s00_axi_wstrb  (s00_axi_wstrb),
        .s00_axi_wlast  (s00_axi_wlast),
        .s00_axi_wvalid (s00_axi_wvalid),
        .s00_axi_wready (s00_axi_wready),
        .s00_axi_bid    (s00_axi_bid),
        .s00_axi_bresp  (s00_axi_bresp),
        .s00_axi_bvalid (s00_axi_bvalid),
        .s00_axi_bready (s00_axi_bready),
        .s00_axi_arid   (s00_axi_arid),
        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arlen  (s00_axi_arlen),
        .s00_axi_arsize (s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst),
        .s00_axi_arlock (s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rid    (s00_axi_rid),
        .s00_axi_rdata  (s00_axi_rdata),
        .s00_axi_rresp  (s00_axi_rresp),
        .s00_axi_rlast  (s00_axi_rlast),
        .s00_axi_rvalid (s00_axi_rvalid),
        .s00_axi_rready (s00_axi_rready),
        
        // Slave 01 Port (DMA - Reserved, tied off to 0)
        .s01_axi_awid(12'd0), .s01_axi_awaddr(32'd0), .s01_axi_awlen(8'd0), .s01_axi_awsize(3'd0), .s01_axi_awburst(2'd0), .s01_axi_awlock(1'b0), .s01_axi_awcache(4'd0), .s01_axi_awprot(3'd0), .s01_axi_awvalid(1'b0), .s01_axi_wdata(32'd0), .s01_axi_wstrb(4'd0), .s01_axi_wlast(1'b0), .s01_axi_wvalid(1'b0), .s01_axi_bready(1'b0), .s01_axi_arid(12'd0), .s01_axi_araddr(32'd0), .s01_axi_arlen(8'd0), .s01_axi_arsize(3'd0), .s01_axi_arburst(2'd0), .s01_axi_arlock(1'b0), .s01_axi_arcache(4'd0), .s01_axi_arprot(3'd0), .s01_axi_arvalid(1'b0), .s01_axi_rready(1'b0),
        
        // Master 00 Port -> UART (0x2000_0000)
        .m00_axi_awid   (m00_axi_awid),
        .m00_axi_awaddr (m00_axi_awaddr),
        .m00_axi_awlen  (m00_axi_awlen),
        .m00_axi_awsize (m00_axi_awsize),
        .m00_axi_awburst(m00_axi_awburst),
        .m00_axi_awlock (m00_axi_awlock),
        .m00_axi_awcache(m00_axi_awcache),
        .m00_axi_awprot (m00_axi_awprot),
        .m00_axi_awvalid(m00_axi_awvalid),
        .m00_axi_awready(m00_axi_awready),
        .m00_axi_wdata  (m00_axi_wdata),
        .m00_axi_wstrb  (m00_axi_wstrb),
        .m00_axi_wlast  (m00_axi_wlast),
        .m00_axi_wvalid (m00_axi_wvalid),
        .m00_axi_wready (m00_axi_wready),
        .m00_axi_bid    (m00_axi_bid),
        .m00_axi_bresp  (m00_axi_bresp),
        .m00_axi_bvalid (m00_axi_bvalid),
        .m00_axi_bready (m00_axi_bready),
        .m00_axi_arid   (m00_axi_arid),
        .m00_axi_araddr (m00_axi_araddr),
        .m00_axi_arlen  (m00_axi_arlen),
        .m00_axi_arsize (m00_axi_arsize),
        .m00_axi_arburst(m00_axi_arburst),
        .m00_axi_arlock (m00_axi_arlock),
        .m00_axi_arcache(m00_axi_arcache),
        .m00_axi_arprot (m00_axi_arprot),
        .m00_axi_arvalid(m00_axi_arvalid),
        .m00_axi_arready(m00_axi_arready),
        .m00_axi_rid    (m00_axi_rid),
        .m00_axi_rdata  (m00_axi_rdata),
        .m00_axi_rresp  (m00_axi_rresp),
        .m00_axi_rlast  (m00_axi_rlast),
        .m00_axi_rvalid (m00_axi_rvalid),
        .m00_axi_rready (m00_axi_rready),
        
        // Master 01 Port (Timer - Reserved tie-offs)
        .m01_axi_awready(1'b0), .m01_axi_wready(1'b0), .m01_axi_bid(12'd0), .m01_axi_bresp(2'd0), .m01_axi_bvalid(1'b0),
        .m01_axi_arready(1'b0), .m01_axi_rid(12'd0), .m01_axi_rdata(32'd0), .m01_axi_rresp(2'd0), .m01_axi_rlast(1'b0), .m01_axi_rvalid(1'b0),

        // Master 02 Port (GPIO - Reserved tie-offs)
        .m02_axi_awready(1'b0), .m02_axi_wready(1'b0), .m02_axi_bid(12'd0), .m02_axi_bresp(2'd0), .m02_axi_bvalid(1'b0),
        .m02_axi_arready(1'b0), .m02_axi_rid(12'd0), .m02_axi_rdata(32'd0), .m02_axi_rresp(2'd0), .m02_axi_rlast(1'b0), .m02_axi_rvalid(1'b0),

        // Master 03 Port -> SPI Controller (0x2000_3000)
        .m03_axi_awid   (m03_axi_awid),
        .m03_axi_awaddr (m03_axi_awaddr),
        .m03_axi_awlen  (m03_axi_awlen),
        .m03_axi_awsize (m03_axi_awsize),
        .m03_axi_awburst(m03_axi_awburst),
        .m03_axi_awlock (m03_axi_awlock),
        .m03_axi_awcache(m03_axi_awcache),
        .m03_axi_awprot (m03_axi_awprot),
        .m03_axi_awvalid(m03_axi_awvalid),
        .m03_axi_awready(m03_axi_awready),
        .m03_axi_wdata  (m03_axi_wdata),
        .m03_axi_wstrb  (m03_axi_wstrb),
        .m03_axi_wlast  (m03_axi_wlast),
        .m03_axi_wvalid (m03_axi_wvalid),
        .m03_axi_wready (m03_axi_wready),
        .m03_axi_bid    (m03_axi_bid),
        .m03_axi_bresp  (m03_axi_bresp),
        .m03_axi_bvalid (m03_axi_bvalid),
        .m03_axi_bready (m03_axi_bready),
        .m03_axi_arid   (m03_axi_arid),
        .m03_axi_araddr (m03_axi_araddr),
        .m03_axi_arlen  (m03_axi_arlen),
        .m03_axi_arsize (m03_axi_arsize),
        .m03_axi_arburst(m03_axi_arburst),
        .m03_axi_arlock (m03_axi_arlock),
        .m03_axi_arcache(m03_axi_arcache),
        .m03_axi_arprot (m03_axi_arprot),
        .m03_axi_arvalid(m03_axi_arvalid),
        .m03_axi_arready(m03_axi_arready),
        .m03_axi_rid    (m03_axi_rid),
        .m03_axi_rdata  (m03_axi_rdata),
        .m03_axi_rresp  (m03_axi_rresp),
        .m03_axi_rlast  (m03_axi_rlast),
        .m03_axi_rvalid (m03_axi_rvalid),
        .m03_axi_rready (m03_axi_rready),

        // Master 04 Port (I2C - Reserved tie-offs)
        .m04_axi_awready(1'b0), .m04_axi_wready(1'b0), .m04_axi_bid(12'd0), .m04_axi_bresp(2'd0), .m04_axi_bvalid(1'b0),
        .m04_axi_arready(1'b0), .m04_axi_rid(12'd0), .m04_axi_rdata(32'd0), .m04_axi_rresp(2'd0), .m04_axi_rlast(1'b0), .m04_axi_rvalid(1'b0),

        // Master 05 Port (PWM - Reserved tie-offs)
        .m05_axi_awready(1'b0), .m05_axi_wready(1'b0), .m05_axi_bid(12'd0), .m05_axi_bresp(2'd0), .m05_axi_bvalid(1'b0),
        .m05_axi_arready(1'b0), .m05_axi_rid(12'd0), .m05_axi_rdata(32'd0), .m05_axi_rresp(2'd0), .m05_axi_rlast(1'b0), .m05_axi_rvalid(1'b0)
    );

    // -------------------------------------------------------------------------
    // UART IP Instantiation
    // -------------------------------------------------------------------------
    axi_uart_top uart_ip_inst (
        .fixed_clk_i      (sys_clk),
        .axi_aclk_i       (sys_clk),
        .axi_aresetn_i    (sys_rst_n),
        
        // AR Channel
        .axi_arid_i       (m00_axi_arid),
        .axi_araddr_i     (m00_axi_araddr[4:0]), // UART uses lower 5 bits of address
        .axi_arvalid_i    (m00_axi_arvalid),
        .axi_arready_o    (m00_axi_arready),
        
        // R Channel
        .axi_rid_o        (m00_axi_rid),
        .axi_rdata_o      (m00_axi_rdata),
        .axi_rresp_o      (m00_axi_rresp),
        .axi_rvalid_o     (m00_axi_rvalid),
        .axi_rready_i     (m00_axi_rready),
        
        // AW Channel
        .axi_awid_i       (m00_axi_awid),
        .axi_awaddr_i     (m00_axi_awaddr[4:0]),
        .axi_awvalid_i    (m00_axi_awvalid),
        .axi_awready_o    (m00_axi_awready),
        
        // W Channel
        .axi_wdata_i      (m00_axi_wdata),
        .axi_wstrb_i      (m00_axi_wstrb),
        .axi_wvalid_i     (m00_axi_wvalid),
        .axi_wready_o     (m00_axi_wready),
        
        // B Channel
        .axi_bid_o        (m00_axi_bid),
        .axi_bresp_o      (m00_axi_bresp),
        .axi_bvalid_o     (m00_axi_bvalid),
        .axi_bready_i     (m00_axi_bready),
        
        // External Interfaces
        .read_interrupt_o (uart_interrupt_o),
        .uart_rx_i        (uart_rx_i),
        .uart_tx_o        (uart_tx_o)
    );

    // Tie off unused interconnect outputs from AXI to AXI-Lite
    assign m00_axi_rlast = 1'b1;

    // -------------------------------------------------------------------------
    // SPI Controller IP Instantiation
    // -------------------------------------------------------------------------
    axi_spi_top spi_ip_inst (
        .fixed_clk_i      (sys_clk),
        .axi_aclk_i       (sys_clk),
        .axi_aresetn_i    (sys_rst_n),
        
        // AR Channel
        .axi_arid_i       (m03_axi_arid),
        .axi_araddr_i     (m03_axi_araddr[6:0]), // SPI uses lower 7 bits of address
        .axi_arvalid_i    (m03_axi_arvalid),
        .axi_arready_o    (m03_axi_arready),
        
        // R Channel
        .axi_rid_o        (m03_axi_rid),
        .axi_rdata_o      (m03_axi_rdata),
        .axi_rresp_o      (m03_axi_rresp),
        .axi_rvalid_o     (m03_axi_rvalid),
        .axi_rready_i     (m03_axi_rready),
        
        // AW Channel
        .axi_awid_i       (m03_axi_awid),
        .axi_awaddr_i     (m03_axi_awaddr[6:0]),
        .axi_awvalid_i    (m03_axi_awvalid),
        .axi_awready_o    (m03_axi_awready),
        
        // W Channel
        .axi_wdata_i      (m03_axi_wdata),
        .axi_wstrb_i      (m03_axi_wstrb),
        .axi_wvalid_i     (m03_axi_wvalid),
        .axi_wready_o     (m03_axi_wready),
        
        // B Channel
        .axi_bid_o        (m03_axi_bid),
        .axi_bresp_o      (m03_axi_bresp),
        .axi_bvalid_o     (m03_axi_bvalid),
        .axi_bready_i     (m03_axi_bready),
        
        // External SPI Interface Pins
        .spi_clk_o        (spi_clk_o),
        .spi_cs_n_o       (spi_cs_n_o),
        .spi_mosi_o       (spi_mosi_o),
        .spi_miso_i       (spi_miso_i)
    );

    // Tie off unused interconnect outputs from AXI to AXI-Lite
    assign m03_axi_rlast = 1'b1;

endmodule
