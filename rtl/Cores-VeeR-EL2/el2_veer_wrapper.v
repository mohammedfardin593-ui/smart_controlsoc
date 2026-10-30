`timescale 1ns/1ps

module el2_veer_wrapper #(
    parameter ID_WIDTH   = 12,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
)(
    input  wire        clk,
    input  wire        rst_l,
    input  wire        dbg_rst_l,
    input  wire [30:0] rst_vec,
    input  wire        nmi_int,
    input  wire [30:0] nmi_vec,
    input  wire [30:0] jtag_id,

    // LSU AXI Interface
    output reg                     lsu_axi_awvalid,
    input  wire                    lsu_axi_awready,
    output reg  [ID_WIDTH-1:0]     lsu_axi_awid,
    output reg  [ADDR_WIDTH-1:0]   lsu_axi_awaddr,
    output reg  [7:0]              lsu_axi_awlen,
    output reg  [2:0]              lsu_axi_awsize,
    output reg  [1:0]              lsu_axi_awburst,
    output reg                     lsu_axi_awlock,
    output reg  [3:0]              lsu_axi_awcache,
    output reg  [2:0]              lsu_axi_awprot,
    
    output reg                     lsu_axi_wvalid,
    input  wire                    lsu_axi_wready,
    output reg  [DATA_WIDTH-1:0]   lsu_axi_wdata,
    output reg  [7:0]              lsu_axi_wstrb,
    output reg                     lsu_axi_wlast,
    
    input  wire                    lsu_axi_bvalid,
    output reg                     lsu_axi_bready,
    input  wire [1:0]              lsu_axi_bresp,
    input  wire [ID_WIDTH-1:0]     lsu_axi_bid,
    
    output reg                     lsu_axi_arvalid,
    input  wire                    lsu_axi_arready,
    output reg  [ID_WIDTH-1:0]     lsu_axi_arid,
    output reg  [ADDR_WIDTH-1:0]   lsu_axi_araddr,
    output reg  [7:0]              lsu_axi_arlen,
    output reg  [2:0]              lsu_axi_arsize,
    output reg  [1:0]              lsu_axi_arburst,
    output reg                     lsu_axi_arlock,
    output reg  [3:0]              lsu_axi_arcache,
    output reg  [2:0]              lsu_axi_arprot,
    
    input  wire                    lsu_axi_rvalid,
    output reg                     lsu_axi_rready,
    input  wire [ID_WIDTH-1:0]     lsu_axi_rid,
    input  wire [DATA_WIDTH-1:0]   lsu_axi_rdata,
    input  wire [1:0]              lsu_axi_rresp,
    input  wire                    lsu_axi_rlast,

    // IFU AXI Interface (tied off in top)
    input  wire                    ifu_axi_awready,
    input  wire                    ifu_axi_wready,
    input  wire                    ifu_axi_bvalid,
    input  wire                    ifu_axi_arready,
    input  wire                    ifu_axi_rvalid,

    // SB AXI Interface (tied off in top)
    input  wire                    sb_axi_awready,
    input  wire                    sb_axi_wready,
    input  wire                    sb_axi_bvalid,
    input  wire                    sb_axi_arready,
    input  wire                    sb_axi_rvalid,

    // DMA AXI Interface (tied off in top)
    input  wire                    dma_axi_awvalid,
    input  wire                    dma_axi_wvalid,
    input  wire                    dma_axi_arvalid,
    input  wire                    dma_axi_bready,
    input  wire                    dma_axi_rready,

    // Clock enables and Interrupts
    input  wire        lsu_bus_clk_en,
    input  wire        ifu_bus_clk_en,
    input  wire        dbg_bus_clk_en,
    input  wire        dma_bus_clk_en,
    input  wire        timer_int,
    input  wire        soft_int,
    input  wire        extintsrc_req
);

    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            lsu_axi_awvalid <= 1'b0;
            lsu_axi_awid    <= {ID_WIDTH{1'b0}};
            lsu_axi_awaddr  <= {ADDR_WIDTH{1'b0}};
            lsu_axi_awlen   <= 8'h00;
            lsu_axi_awsize  <= 3'b010;
            lsu_axi_awburst <= 2'b01;
            lsu_axi_awlock  <= 1'b0;
            lsu_axi_awcache <= 4'h0;
            lsu_axi_awprot  <= 3'b000;

            lsu_axi_wvalid  <= 1'b0;
            lsu_axi_wdata   <= {DATA_WIDTH{1'b0}};
            lsu_axi_wstrb   <= 8'h00;
            lsu_axi_wlast   <= 1'b0;

            lsu_axi_bready  <= 1'b0;

            lsu_axi_arvalid <= 1'b0;
            lsu_axi_arid    <= {ID_WIDTH{1'b0}};
            lsu_axi_araddr  <= {ADDR_WIDTH{1'b0}};
            lsu_axi_arlen   <= 8'h00;
            lsu_axi_arsize  <= 3'b010;
            lsu_axi_arburst <= 2'b01;
            lsu_axi_arlock  <= 1'b0;
            lsu_axi_arcache <= 4'h0;
            lsu_axi_arprot  <= 3'b000;

            lsu_axi_rready  <= 1'b0;
        end
    end

    // CPU Bus Functional Model (BFM) Tasks
    task cpu_write(
        input [ADDR_WIDTH-1:0] addr,
        input [31:0]           data,
        input [3:0]            strb
    );
        reg aw_done;
        reg w_done;
        begin
            @(posedge clk);
            lsu_axi_awaddr  <= addr;
            lsu_axi_awid    <= 12'h101;
            lsu_axi_awvalid <= 1'b1;
            lsu_axi_wdata   <= {32'h0, data};
            lsu_axi_wstrb   <= {4'h0, strb};
            lsu_axi_wlast   <= 1'b1;
            lsu_axi_wvalid  <= 1'b1;
            lsu_axi_bready  <= 1'b1;
            aw_done = 0;
            w_done  = 0;

            while (!(aw_done && w_done)) begin
                @(posedge clk);
                if (lsu_axi_awvalid && lsu_axi_awready) begin
                    lsu_axi_awvalid <= 1'b0;
                    aw_done = 1;
                end
                if (lsu_axi_wvalid && lsu_axi_wready) begin
                    lsu_axi_wvalid <= 1'b0;
                    w_done = 1;
                end
            end

            while (!lsu_axi_bvalid) begin
                @(posedge clk);
            end
            @(posedge clk);
            lsu_axi_bready <= 1'b0;
            lsu_axi_wlast  <= 1'b0;
        end
    endtask

    task cpu_read(
        input  [ADDR_WIDTH-1:0] addr,
        output [31:0]           data
    );
        begin
            @(posedge clk);
            lsu_axi_araddr  <= addr;
            lsu_axi_arid    <= 12'h202;
            lsu_axi_arvalid <= 1'b1;
            lsu_axi_rready  <= 1'b1;

            while (!(lsu_axi_arvalid && lsu_axi_arready)) begin
                @(posedge clk);
            end
            lsu_axi_arvalid <= 1'b0;

            while (!lsu_axi_rvalid) begin
                @(posedge clk);
            end
            data = lsu_axi_rdata[31:0];
            @(posedge clk);
            lsu_axi_rready <= 1'b0;
        end
    endtask

endmodule
