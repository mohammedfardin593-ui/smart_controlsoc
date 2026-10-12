`timescale 1ns/1ps

module axi_i2c_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter ID_WIDTH   = 12
)(
    // Clock and Reset
    input  wire        axi_aclk,
    input  wire        axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [ID_WIDTH-1:0]    axi_awid,
    input  wire [ADDR_WIDTH-1:0]  axi_awaddr,
    input  wire                   axi_awvalid,
    output reg                    axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  axi_wdata,
    input  wire [STRB_WIDTH-1:0]  axi_wstrb,
    input  wire                   axi_wvalid,
    output reg                    axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [ID_WIDTH-1:0]    axi_bid,
    output reg  [1:0]             axi_bresp,
    output reg                    axi_bvalid,
    input  wire                   axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ID_WIDTH-1:0]    axi_arid,
    input  wire [ADDR_WIDTH-1:0]  axi_araddr,
    input  wire                   axi_arvalid,
    output reg                    axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [ID_WIDTH-1:0]    axi_rid,
    output reg  [DATA_WIDTH-1:0]  axi_rdata,
    output reg  [1:0]             axi_rresp,
    output reg                    axi_rvalid,
    input  wire                   axi_rready,

    // External I2C Interface
    inout  wire                   i2c_scl_io,
    inout  wire                   i2c_sda_io,
    output wire                   i2c_irq_o
);

    // Wishbone signals for core
    reg  [2:0]  wb_adr;
    reg  [7:0]  wb_dat_i;
    wire [7:0]  wb_dat_o;
    reg         wb_we;
    reg         wb_stb;
    reg         wb_cyc;
    wire        wb_ack;
    wire        wb_inta;

    // I2C pad control signals
    wire scl_pad_i;
    wire scl_pad_o;
    wire scl_padoen_o;
    wire sda_pad_i;
    wire sda_pad_o;
    wire sda_padoen_o;

    // Tristate buffers for external I2C open-drain lines
    assign i2c_scl_io = scl_padoen_o ? 1'bz : scl_pad_o;
    assign scl_pad_i  = i2c_scl_io;

    assign i2c_sda_io = sda_padoen_o ? 1'bz : sda_pad_o;
    assign sda_pad_i  = i2c_sda_io;

    assign i2c_irq_o  = wb_inta;

    // FSM States for AXI to Wishbone bridge
    localparam IDLE       = 2'd0;
    localparam WB_WRITE   = 2'd1;
    localparam WB_READ    = 2'd2;
    localparam RESP       = 2'd3;

    reg [1:0] state;

    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            state       <= IDLE;
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_bresp   <= 2'b00;
            axi_bid     <= {ID_WIDTH{1'b0}};
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rresp   <= 2'b00;
            axi_rdata   <= {DATA_WIDTH{1'b0}};
            axi_rid     <= {ID_WIDTH{1'b0}};
            wb_adr      <= 3'd0;
            wb_dat_i    <= 8'd0;
            wb_we       <= 1'b0;
            wb_stb      <= 1'b0;
            wb_cyc      <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    // Priority to Write transactions
                    if (axi_awvalid && axi_wvalid) begin
                        axi_awready <= 1'b1;
                        axi_wready  <= 1'b1;
                        axi_bid     <= axi_awid;
                        wb_adr      <= axi_awaddr[4:2]; // Word-aligned register mapping
                        wb_dat_i    <= axi_wdata[7:0];
                        wb_we       <= 1'b1;
                        wb_stb      <= 1'b1;
                        wb_cyc      <= 1'b1;
                        state       <= WB_WRITE;
                    end else if (axi_arvalid) begin
                        axi_arready <= 1'b1;
                        axi_rid     <= axi_arid;
                        wb_adr      <= axi_araddr[4:2];
                        wb_we       <= 1'b0;
                        wb_stb      <= 1'b1;
                        wb_cyc      <= 1'b1;
                        state       <= WB_READ;
                    end
                end

                WB_WRITE: begin
                    axi_awready <= 1'b0;
                    axi_wready  <= 1'b0;
                    if (wb_ack) begin
                        wb_cyc     <= 1'b0;
                        wb_stb     <= 1'b0;
                        wb_we      <= 1'b0;
                        axi_bvalid <= 1'b1;
                        axi_bresp  <= 2'b00; // OKAY
                        state      <= RESP;
                    end
                end

                WB_READ: begin
                    axi_arready <= 1'b0;
                    if (wb_ack) begin
                        wb_cyc     <= 1'b0;
                        wb_stb     <= 1'b0;
                        axi_rdata  <= {24'd0, wb_dat_o};
                        axi_rvalid <= 1'b1;
                        axi_rresp  <= 2'b00; // OKAY
                        state      <= RESP;
                    end
                end

                RESP: begin
                    if (axi_bvalid && axi_bready) begin
                        axi_bvalid <= 1'b0;
                        state      <= IDLE;
                    end else if (axi_rvalid && axi_rready) begin
                        axi_rvalid <= 1'b0;
                        state      <= IDLE;
                    end
                end
            endcase
        end
    end

    // Instantiate OpenCores I2C Master Core
    i2c_master_top #(
        .ARST_LVL(1'b0) // Active low async reset
    ) u_i2c_core (
        .wb_clk_i     (axi_aclk),
        .wb_rst_i     (1'b0),
        .arst_i       (axi_aresetn),
        .wb_adr_i     (wb_adr),
        .wb_dat_i     (wb_dat_i),
        .wb_dat_o     (wb_dat_o),
        .wb_we_i      (wb_we),
        .wb_stb_i     (wb_stb),
        .wb_cyc_i     (wb_cyc),
        .wb_ack_o     (wb_ack),
        .wb_inta_o    (wb_inta),
        .scl_pad_i    (scl_pad_i),
        .scl_pad_o    (scl_pad_o),
        .scl_padoen_o (scl_padoen_o),
        .sda_pad_i    (sda_pad_i),
        .sda_pad_o    (sda_pad_o),
        .sda_padoen_o (sda_padoen_o)
    );

endmodule
