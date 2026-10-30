// =============================================================================
// Axi DMA Top Wrapper for Smart ControlSoC
// Encapsulates dma_axi_wrapper with standard AXI4 / AXI4-Lite pin-level interfaces
// =============================================================================
`timescale 1ns/1ps

module axi_dma_top
  import amba_axi_pkg::*;
  import dma_utils_pkg::*;
#(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32,
  parameter STRB_WIDTH = (DATA_WIDTH/8),
  parameter ID_WIDTH   = 12,
  parameter DMA_ID_VAL = 1
)(
  input  wire                   axi_aclk,
  input  wire                   axi_aresetn,

  // ---------------------------------------------------------------------------
  // AXI4-Lite CSR Slave Interface (For DMA configuration & control)
  // ---------------------------------------------------------------------------
  // Write Address Channel
  input  wire [ADDR_WIDTH-1:0]  s_axil_csr_awaddr,
  input  wire [2:0]             s_axil_csr_awprot,
  input  wire                   s_axil_csr_awvalid,
  output wire                   s_axil_csr_awready,

  // Write Data Channel
  input  wire [DATA_WIDTH-1:0]  s_axil_csr_wdata,
  input  wire [STRB_WIDTH-1:0]  s_axil_csr_wstrb,
  input  wire                   s_axil_csr_wvalid,
  output wire                   s_axil_csr_wready,

  // Write Response Channel
  output wire [1:0]             s_axil_csr_bresp,
  output wire                   s_axil_csr_bvalid,
  input  wire                   s_axil_csr_bready,

  // Read Address Channel
  input  wire [ADDR_WIDTH-1:0]  s_axil_csr_araddr,
  input  wire [2:0]             s_axil_csr_arprot,
  input  wire                   s_axil_csr_arvalid,
  output wire                   s_axil_csr_arready,

  // Read Data Channel
  output wire [DATA_WIDTH-1:0]  s_axil_csr_rdata,
  output wire [1:0]             s_axil_csr_rresp,
  output wire                   s_axil_csr_rvalid,
  input  wire                   s_axil_csr_rready,

  // ---------------------------------------------------------------------------
  // AXI4 Master Interface (Connects to Interconnect S01 Port)
  // ---------------------------------------------------------------------------
  // Write Address Channel
  output wire [ID_WIDTH-1:0]    m_axi_awid,
  output wire [ADDR_WIDTH-1:0]  m_axi_awaddr,
  output wire [7:0]             m_axi_awlen,
  output wire [2:0]             m_axi_awsize,
  output wire [1:0]             m_axi_awburst,
  output wire                   m_axi_awlock,
  output wire [3:0]             m_axi_awcache,
  output wire [2:0]             m_axi_awprot,
  output wire [3:0]             m_axi_awqos,
  output wire [3:0]             m_axi_awregion,
  output wire                   m_axi_awvalid,
  input  wire                   m_axi_awready,

  // Write Data Channel
  output wire [DATA_WIDTH-1:0]  m_axi_wdata,
  output wire [STRB_WIDTH-1:0]  m_axi_wstrb,
  output wire                   m_axi_wlast,
  output wire                   m_axi_wvalid,
  input  wire                   m_axi_wready,

  // Write Response Channel
  input  wire [ID_WIDTH-1:0]    m_axi_bid,
  input  wire [1:0]             m_axi_bresp,
  input  wire                   m_axi_bvalid,
  output wire                   m_axi_bready,

  // Read Address Channel
  output wire [ID_WIDTH-1:0]    m_axi_arid,
  output wire [ADDR_WIDTH-1:0]  m_axi_araddr,
  output wire [7:0]             m_axi_arlen,
  output wire [2:0]             m_axi_arsize,
  output wire [1:0]             m_axi_arburst,
  output wire                   m_axi_arlock,
  output wire [3:0]             m_axi_arcache,
  output wire [2:0]             m_axi_arprot,
  output wire [3:0]             m_axi_arqos,
  output wire [3:0]             m_axi_arregion,
  output wire                   m_axi_arvalid,
  input  wire                   m_axi_arready,

  // Read Data Channel
  input  wire [ID_WIDTH-1:0]    m_axi_rid,
  input  wire [DATA_WIDTH-1:0]  m_axi_rdata,
  input  wire [1:0]             m_axi_rresp,
  input  wire                   m_axi_rlast,
  input  wire                   m_axi_rvalid,
  output wire                   m_axi_rready,

  // ---------------------------------------------------------------------------
  // Interrupt Flags
  // ---------------------------------------------------------------------------
  output wire                   dma_done_o,
  output wire                   dma_error_o
);

  // Internal structs for dma_axi_wrapper
  s_axil_mosi_t dma_csr_mosi;
  s_axil_miso_t dma_csr_miso;
  s_axi_mosi_t  dma_m_mosi;
  s_axi_miso_t  dma_m_miso;

  // ---------------------------------------------------------------------------
  // CSR Slave AXI-Lite Mapping
  // ---------------------------------------------------------------------------
  always_comb begin
    dma_csr_mosi          = '0;
    dma_csr_mosi.awid     = '0;
    dma_csr_mosi.awaddr   = s_axil_csr_awaddr;
    dma_csr_mosi.awprot   = axi_prot_t'(s_axil_csr_awprot);
    dma_csr_mosi.awvalid  = s_axil_csr_awvalid;
    dma_csr_mosi.wdata    = s_axil_csr_wdata;
    dma_csr_mosi.wstrb    = s_axil_csr_wstrb;
    dma_csr_mosi.wvalid   = s_axil_csr_wvalid;
    dma_csr_mosi.bready   = s_axil_csr_bready;
    dma_csr_mosi.arid     = '0;
    dma_csr_mosi.araddr   = s_axil_csr_araddr;
    dma_csr_mosi.arprot   = axi_prot_t'(s_axil_csr_arprot);
    dma_csr_mosi.arvalid  = s_axil_csr_arvalid;
    dma_csr_mosi.rready   = s_axil_csr_rready;
  end

  assign s_axil_csr_awready = dma_csr_miso.awready;
  assign s_axil_csr_wready  = dma_csr_miso.wready;
  assign s_axil_csr_bresp   = dma_csr_miso.bresp;
  assign s_axil_csr_bvalid  = dma_csr_miso.bvalid;
  assign s_axil_csr_arready = dma_csr_miso.arready;
  assign s_axil_csr_rdata   = dma_csr_miso.rdata;
  assign s_axil_csr_rresp   = dma_csr_miso.rresp;
  assign s_axil_csr_rvalid  = dma_csr_miso.rvalid;

  // ---------------------------------------------------------------------------
  // Master AXI4 Interface Mapping (to Interconnect S01)
  // ---------------------------------------------------------------------------
  assign m_axi_awid     = {{(ID_WIDTH-8){1'b0}}, dma_m_mosi.awid};
  assign m_axi_awaddr   = dma_m_mosi.awaddr;
  assign m_axi_awlen    = dma_m_mosi.awlen;
  assign m_axi_awsize   = dma_m_mosi.awsize;
  assign m_axi_awburst  = dma_m_mosi.awburst;
  assign m_axi_awlock   = dma_m_mosi.awlock;
  assign m_axi_awcache  = dma_m_mosi.awcache;
  assign m_axi_awprot   = dma_m_mosi.awprot;
  assign m_axi_awqos    = dma_m_mosi.awqos;
  assign m_axi_awregion = dma_m_mosi.awregion;
  assign m_axi_awvalid  = dma_m_mosi.awvalid;

  assign m_axi_wdata    = dma_m_mosi.wdata;
  assign m_axi_wstrb    = dma_m_mosi.wstrb;
  assign m_axi_wlast    = dma_m_mosi.wlast;
  assign m_axi_wvalid   = dma_m_mosi.wvalid;

  assign m_axi_bready   = dma_m_mosi.bready;

  assign m_axi_arid     = {{(ID_WIDTH-8){1'b0}}, dma_m_mosi.arid};
  assign m_axi_araddr   = dma_m_mosi.araddr;
  assign m_axi_arlen    = dma_m_mosi.arlen;
  assign m_axi_arsize   = dma_m_mosi.arsize;
  assign m_axi_arburst  = dma_m_mosi.arburst;
  assign m_axi_arlock   = dma_m_mosi.arlock;
  assign m_axi_arcache  = dma_m_mosi.arcache;
  assign m_axi_arprot   = dma_m_mosi.arprot;
  assign m_axi_arqos    = dma_m_mosi.arqos;
  assign m_axi_arregion = dma_m_mosi.arregion;
  assign m_axi_arvalid  = dma_m_mosi.arvalid;

  assign m_axi_rready   = dma_m_mosi.rready;

  always_comb begin
    dma_m_miso          = '0;
    dma_m_miso.awready  = m_axi_awready;
    dma_m_miso.wready   = m_axi_wready;
    dma_m_miso.bid      = m_axi_bid[7:0];
    dma_m_miso.bresp    = axi_resp_t'(m_axi_bresp);
    dma_m_miso.bvalid   = m_axi_bvalid;

    dma_m_miso.arready  = m_axi_arready;
    dma_m_miso.rid      = m_axi_rid[7:0];
    dma_m_miso.rdata    = m_axi_rdata;
    dma_m_miso.rresp    = axi_resp_t'(m_axi_rresp);
    dma_m_miso.rlast    = m_axi_rlast;
    dma_m_miso.rvalid   = m_axi_rvalid;
  end

  // ---------------------------------------------------------------------------
  // DMA AXI Wrapper Instance
  // Note: rst is active-high in dma_axi_wrapper
  // ---------------------------------------------------------------------------
  dma_axi_wrapper #(
    .DMA_ID_VAL(DMA_ID_VAL)
  ) u_dma_axi_wrapper (
    .clk            (axi_aclk),
    .rst            (~axi_aresetn),
    .dma_csr_mosi_i (dma_csr_mosi),
    .dma_csr_miso_o (dma_csr_miso),
    .dma_m_mosi_o   (dma_m_mosi),
    .dma_m_miso_i   (dma_m_miso),
    .dma_done_o     (dma_done_o),
    .dma_error_o    (dma_error_o)
  );

endmodule
