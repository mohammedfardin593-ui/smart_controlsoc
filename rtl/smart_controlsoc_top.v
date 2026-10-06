`timescale 1ns/1ps

module smart_controlsoc_top #(
    // AXI4-Lite Parameters (Matching UART & Interconnect)
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
    output wire        uart_interrupt_o

    // Other top-level ports for RISC-V, DMA, Timer, etc. will go here later
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

    // (Wires for S00, S01, M01, M02, M03, M04, M05 to be defined as you add the RISC-V, DMA, and other IPs)

    // -------------------------------------------------------------------------
    // AXI Interconnect 2x6 Instantiation
    // -------------------------------------------------------------------------
    axi_interconnect_wrap_2x6 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        
        // Memory Map Override (Based on documentation)
        .M00_BASE_ADDR  (32'h2000_0000), // UART Base Address
        .M00_ADDR_WIDTH (32'd12),        // 4KB address space for UART
        
        .M01_BASE_ADDR  (32'h2000_1000), // Timer Base Address
        .M01_ADDR_WIDTH (32'd12),
        
        .M02_BASE_ADDR  (32'h2000_2000), // GPIO Base Address
        .M02_ADDR_WIDTH (32'd12),
        
        .M03_BASE_ADDR  (32'h2000_3000), // SPI Controller Base Address
        .M03_ADDR_WIDTH (32'd12),
        
        .M04_BASE_ADDR  (32'h2000_4000), // I2C Controller Base Address
        .M04_ADDR_WIDTH (32'd12),
        
        .M05_BASE_ADDR  (32'h2000_5000), // PWM Generator Base Address
        .M05_ADDR_WIDTH (32'd12)
    ) system_interconnect (
        .clk(sys_clk), 
        .rst(~sys_rst_n), // Active high reset required by interconnect wrapper
        
        // Master 00 Port -> UART
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
        .m00_axi_rready (m00_axi_rready)
        
        // M01-M05 and S00-S01 tie-offs omitted for brevity until other IPs are added
    );

    // -------------------------------------------------------------------------
    // UART IP Instantiation
    // -------------------------------------------------------------------------
    // Note: The UART IP is configured for AXI-Lite, so we only connect the relevant AXI signals.
    axi_uart_top uart_ip_inst (
        .fixed_clk_i      (sys_clk),
        .axi_aclk_i       (sys_clk),
        .axi_aresetn_i    (sys_rst_n),
        
        // AR Channel
        .axi_arid_i       (m00_axi_arid),
        .axi_araddr_i     (m00_axi_araddr[4:0]), // UART only uses lower 5 bits of address
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

endmodule
