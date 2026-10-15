`timescale 1ns/1ps

module axi_timer_top #(
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

    // External Timer Interrupt Output
    output wire                   timer_irq_o
);

    // Register Offsets (matching OpenTitan rv_timer register map)
    localparam [8:0] REG_ALERT_TEST        = 9'h000;
    localparam [8:0] REG_CTRL              = 9'h004;
    localparam [8:0] REG_INTR_ENABLE0      = 9'h100;
    localparam [8:0] REG_INTR_STATE0       = 9'h104;
    localparam [8:0] REG_INTR_TEST0        = 9'h108;
    localparam [8:0] REG_CFG0              = 9'h10C;
    localparam [8:0] REG_TIMER_V_LOWER0    = 9'h110;
    localparam [8:0] REG_TIMER_V_UPPER0    = 9'h114;
    localparam [8:0] REG_COMPARE_LOWER0_0  = 9'h118;
    localparam [8:0] REG_COMPARE_UPPER0_0  = 9'h11C;

    // Internal Registers
    reg        ctrl_active;
    reg [11:0] cfg_prescaler;
    reg [7:0]  cfg_step;
    reg        intr_enable;
    reg        intr_state;
    reg [63:0] mtime_q;
    reg [63:0] mtimecmp_q;

    // Timer Core Signals
    wire        core_tick;
    wire [63:0] core_mtime_d;
    wire [0:0]  core_intr;
    wire [63:0] core_mtimecmp [1];
    assign core_mtimecmp[0] = mtimecmp_q;

    timer_core #(
        .N(1)
    ) u_timer_core (
        .clk_i      (axi_aclk),
        .rst_ni     (axi_aresetn),
        .active     (ctrl_active),
        .prescaler  (cfg_prescaler),
        .step       (cfg_step),
        .tick       (core_tick),
        .mtime_d    (core_mtime_d),
        .mtime      (mtime_q),
        .mtimecmp   (core_mtimecmp),
        .intr       (core_intr)
    );

    // Interrupt output is asserted when interrupt is enabled and pending
    assign timer_irq_o = intr_state & intr_enable;

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

    wire [8:0]          write_addr = aw_captured ? awaddr_reg[8:0] : axi_awaddr[8:0];
    wire [DATA_WIDTH-1:0] write_data = w_captured  ? wdata_reg        : axi_wdata;
    wire [ID_WIDTH-1:0] write_id   = aw_captured ? awid_reg         : axi_awid;

    // Read Data Mux
    reg [DATA_WIDTH-1:0] read_data_comb;
    always_comb begin
        case (axi_araddr[8:0])
            REG_ALERT_TEST:       read_data_comb = 32'd0;
            REG_CTRL:             read_data_comb = {31'd0, ctrl_active};
            REG_INTR_ENABLE0:     read_data_comb = {31'd0, intr_enable};
            REG_INTR_STATE0:      read_data_comb = {31'd0, intr_state};
            REG_INTR_TEST0:       read_data_comb = 32'd0;
            REG_CFG0:             read_data_comb = {8'd0, cfg_step, 4'd0, cfg_prescaler};
            REG_TIMER_V_LOWER0:   read_data_comb = mtime_q[31:0];
            REG_TIMER_V_UPPER0:   read_data_comb = mtime_q[63:32];
            REG_COMPARE_LOWER0_0: read_data_comb = mtimecmp_q[31:0];
            REG_COMPARE_UPPER0_0: read_data_comb = mtimecmp_q[63:32];
            default:              read_data_comb = 32'd0;
        endcase
    end

    // Sequential Register Updates & AXI Handshake
    always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            state           <= IDLE;
            axi_awready     <= 1'b0;
            axi_wready      <= 1'b0;
            axi_bvalid      <= 1'b0;
            axi_bresp       <= 2'b00;
            axi_bid         <= {ID_WIDTH{1'b0}};
            axi_arready     <= 1'b0;
            axi_rvalid      <= 1'b0;
            axi_rresp       <= 2'b00;
            axi_rdata       <= {DATA_WIDTH{1'b0}};
            axi_rid         <= {ID_WIDTH{1'b0}};
            awaddr_reg      <= {ADDR_WIDTH{1'b0}};
            awid_reg        <= {ID_WIDTH{1'b0}};
            aw_captured     <= 1'b0;
            wdata_reg       <= {DATA_WIDTH{1'b0}};
            wstrb_reg       <= {STRB_WIDTH{1'b0}};
            w_captured      <= 1'b0;

            ctrl_active     <= 1'b0;
            cfg_prescaler   <= 12'd0;
            cfg_step        <= 8'd1; // Default step = 1
            intr_enable     <= 1'b0;
            intr_state      <= 1'b0;
            mtime_q         <= 64'd0;
            mtimecmp_q      <= 64'hFFFF_FFFF_FFFF_FFFF;
        end else begin
            // -------------------------------------------------------------
            // Hardware Timer Counter & Interrupt Update Logic
            // -------------------------------------------------------------
            // If core tick pulses and software is not writing mtime this cycle, advance mtime
            if (core_tick) begin
                mtime_q <= core_mtime_d;
            end

            // Hardware interrupt trigger
            if (core_intr[0]) begin
                intr_state <= 1'b1;
            end

            // -------------------------------------------------------------
            // AXI Protocol Engine & Software Register Writes
            // -------------------------------------------------------------
            case (state)
                IDLE: begin
                    if (write_now) begin
                        axi_awready <= !aw_captured;
                        axi_wready  <= !w_captured;
                        aw_captured <= 1'b0;
                        w_captured  <= 1'b0;
                        axi_bid     <= write_id;
                        axi_bresp   <= 2'b00; // OKAY
                        axi_bvalid  <= 1'b1;
                        state       <= WRITE_RESP;

                        // Perform Register Write
                        case (write_addr)
                            REG_CTRL: begin
                                ctrl_active <= write_data[0];
                            end
                            REG_INTR_ENABLE0: begin
                                intr_enable <= write_data[0];
                            end
                            REG_INTR_STATE0: begin
                                if (write_data[0]) begin
                                    intr_state <= 1'b0; // Write-1-to-Clear (W1C)
                                end
                            end
                            REG_INTR_TEST0: begin
                                if (write_data[0]) begin
                                    intr_state <= 1'b1;
                                end
                            end
                            REG_CFG0: begin
                                cfg_prescaler <= write_data[11:0];
                                cfg_step      <= write_data[23:16];
                            end
                            REG_TIMER_V_LOWER0: begin
                                mtime_q[31:0] <= write_data;
                            end
                            REG_TIMER_V_UPPER0: begin
                                mtime_q[63:32] <= write_data;
                            end
                            REG_COMPARE_LOWER0_0: begin
                                mtimecmp_q[31:0] <= write_data;
                                intr_state       <= 1'b0; // Updating compare clears interrupt
                            end
                            REG_COMPARE_UPPER0_0: begin
                                mtimecmp_q[63:32] <= write_data;
                                intr_state        <= 1'b0;
                            end
                            default: ;
                        endcase
                    end else begin
                        // Latch early AW
                        if (axi_awvalid && !aw_captured) begin
                            awaddr_reg  <= axi_awaddr;
                            awid_reg    <= axi_awid;
                            aw_captured <= 1'b1;
                            axi_awready <= 1'b1;
                        end else begin
                            axi_awready <= 1'b0;
                        end

                        // Latch early W
                        if (axi_wvalid && !w_captured) begin
                            wdata_reg  <= axi_wdata;
                            wstrb_reg  <= axi_wstrb;
                            w_captured <= 1'b1;
                            axi_wready <= 1'b1;
                        end else begin
                            axi_wready <= 1'b0;
                        end

                        // Handle Read
                        if (read_now) begin
                            axi_arready <= 1'b1;
                            axi_rid     <= axi_arid;
                            axi_rdata   <= read_data_comb;
                            axi_rresp   <= 2'b00; // OKAY
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
