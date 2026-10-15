`timescale 1ns/1ps

`include "register_interface/typedef.svh"

module axi_gpio_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    parameter ID_WIDTH   = 12
)(
    // Clock and Reset
    input  wire                   axi_aclk,
    input  wire                   axi_aresetn,

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

    // External GPIO Interface
    inout  wire [31:0]            gpio_io,
    output wire                   gpio_irq_o
);

    // Register Bus Typedef
    typedef logic [10:0] addr_t;
    typedef logic [31:0] data_t;
    typedef logic [3:0]  strb_t;

    `REG_BUS_TYPEDEF_ALL(reg_bus, addr_t, data_t, strb_t)

    reg_bus_req_t reg_req;
    reg_bus_rsp_t reg_rsp;

    // Internal GPIO Core Signals
    wire [31:0] gpio_in_internal;
    wire [31:0] gpio_out_internal;
    wire [31:0] gpio_tx_en_internal;

    // Tristate Bidirectional Buffers
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_gpio_tri
            assign gpio_io[i] = gpio_tx_en_internal[i] ? gpio_out_internal[i] : 1'bz;
            assign gpio_in_internal[i] = gpio_io[i];
        end
    endgenerate

    // Core Instantiation
    gpio #(
        .DATA_WIDTH (DATA_WIDTH),
        .reg_req_t  (reg_bus_req_t),
        .reg_rsp_t  (reg_bus_rsp_t)
    ) u_gpio_core (
        .clk_i                 (axi_aclk),
        .rst_ni                (axi_aresetn),
        .gpio_in               (gpio_in_internal),
        .gpio_out              (gpio_out_internal),
        .gpio_tx_en_o          (gpio_tx_en_internal),
        .gpio_in_sync_o        (),
        .global_interrupt_o    (gpio_irq_o),
        .pin_level_interrupts_o(),
        .reg_req_i             (reg_req),
        .reg_rsp_o             (reg_rsp)
    );

    // AXI4-Lite Slave Engine
    localparam IDLE       = 2'd0;
    localparam WRITE_RESP = 2'd1;
    localparam READ_RESP  = 2'd2;

    reg [1:0] state;

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [ID_WIDTH-1:0]   awid_reg;
    reg                  aw_captured;

    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg                  w_captured;

    wire write_now = (aw_captured || axi_awvalid) && (w_captured || axi_wvalid) && (state == IDLE);
    wire read_now  = axi_arvalid && !write_now && !aw_captured && !w_captured && (state == IDLE);

    wire [10:0] write_addr = aw_captured ? awaddr_reg[10:0] : axi_awaddr[10:0];
    wire [31:0] write_data = w_captured  ? wdata_reg        : axi_wdata;
    wire [3:0]  write_strb = w_captured  ? wstrb_reg        : axi_wstrb;
    wire [ID_WIDTH-1:0] write_id = aw_captured ? awid_reg  : axi_awid;

    // Drive reg_bus request combinationally based on state
    always_comb begin
        if (state == IDLE && write_now) begin
            reg_req.valid = 1'b1;
            reg_req.write = 1'b1;
            reg_req.addr  = write_addr;
            reg_req.wdata = write_data;
            reg_req.wstrb = write_strb;
        end else if (state == IDLE && read_now) begin
            reg_req.valid = 1'b1;
            reg_req.write = 1'b0;
            reg_req.addr  = axi_araddr[10:0];
            reg_req.wdata = 32'd0;
            reg_req.wstrb = 4'd0;
        end else begin
            reg_req.valid = 1'b0;
            reg_req.write = 1'b0;
            reg_req.addr  = 11'd0;
            reg_req.wdata = 32'd0;
            reg_req.wstrb = 4'd0;
        end
    end

    // Sequential State Machine & Handshake Control
    always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
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
            awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            awid_reg    <= {ID_WIDTH{1'b0}};
            aw_captured <= 1'b0;
            wdata_reg   <= {DATA_WIDTH{1'b0}};
            wstrb_reg   <= {STRB_WIDTH{1'b0}};
            w_captured  <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (write_now) begin
                        axi_awready <= !aw_captured;
                        axi_wready  <= !w_captured;
                        aw_captured <= 1'b0;
                        w_captured  <= 1'b0;
                        axi_bid     <= write_id;
                        axi_bresp   <= reg_rsp.error ? 2'b10 : 2'b00;
                        axi_bvalid  <= 1'b1;
                        state       <= WRITE_RESP;
                    end else begin
                        // Latch AW if it arrives early
                        if (axi_awvalid && !aw_captured) begin
                            awaddr_reg  <= axi_awaddr;
                            awid_reg    <= axi_awid;
                            aw_captured <= 1'b1;
                            axi_awready <= 1'b1;
                        end else begin
                            axi_awready <= 1'b0;
                        end

                        // Latch W if it arrives early
                        if (axi_wvalid && !w_captured) begin
                            wdata_reg  <= axi_wdata;
                            wstrb_reg  <= axi_wstrb;
                            w_captured <= 1'b1;
                            axi_wready <= 1'b1;
                        end else begin
                            axi_wready <= 1'b0;
                        end

                        // Handle Read if no write pending
                        if (read_now) begin
                            axi_arready <= 1'b1;
                            axi_rid     <= axi_arid;
                            axi_rdata   <= reg_rsp.rdata;
                            axi_rresp   <= reg_rsp.error ? 2'b10 : 2'b00;
                            axi_rvalid  <= 1'b1;
                            state       <= READ_RESP;
                        end else begin
                            axi_arready <= 1'b0;
                        end
                    end
                end

                WRITE_RESP: begin
                    axi_awready <= 1'b0;
                    axi_wready  <= 1'b0;
                    if (axi_bvalid && axi_bready) begin
                        axi_bvalid <= 1'b0;
                        state      <= IDLE;
                    end
                end

                READ_RESP: begin
                    axi_arready <= 1'b0;
                    if (axi_rvalid && axi_rready) begin
                        axi_rvalid <= 1'b0;
                        state      <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
