`timescale 1ns/1ps

module tb_timer;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam STRB_WIDTH = (DATA_WIDTH/8);
    localparam ID_WIDTH   = 12;
    localparam CLK_PERIOD = 10;

    reg                   axi_aclk;
    reg                   axi_aresetn;

    // AXI signals
    reg  [ID_WIDTH-1:0]   axi_awid;
    reg  [ADDR_WIDTH-1:0] axi_awaddr;
    reg                   axi_awvalid;
    wire                  axi_awready;

    reg  [DATA_WIDTH-1:0] axi_wdata;
    reg  [STRB_WIDTH-1:0] axi_wstrb;
    reg                   axi_wvalid;
    wire                  axi_wready;

    wire [ID_WIDTH-1:0]   axi_bid;
    wire [1:0]            axi_bresp;
    wire                  axi_bvalid;
    reg                   axi_bready;

    reg  [ID_WIDTH-1:0]   axi_arid;
    reg  [ADDR_WIDTH-1:0] axi_araddr;
    reg                   axi_arvalid;
    wire                  axi_arready;

    wire [ID_WIDTH-1:0]   axi_rid;
    wire [DATA_WIDTH-1:0] axi_rdata;
    wire [1:0]            axi_rresp;
    wire                  axi_rvalid;
    reg                   axi_rready;

    wire                  timer_irq_o;

    // DUT
    axi_timer_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .axi_aclk    (axi_aclk),
        .axi_aresetn (axi_aresetn),
        .axi_awid    (axi_awid),
        .axi_awaddr  (axi_awaddr),
        .axi_awvalid (axi_awvalid),
        .axi_awready (axi_awready),
        .axi_wdata   (axi_wdata),
        .axi_wstrb   (axi_wstrb),
        .axi_wvalid  (axi_wvalid),
        .axi_wready  (axi_wready),
        .axi_bid     (axi_bid),
        .axi_bresp   (axi_bresp),
        .axi_bvalid  (axi_bvalid),
        .axi_bready  (axi_bready),
        .axi_arid    (axi_arid),
        .axi_araddr  (axi_araddr),
        .axi_arvalid (axi_arvalid),
        .axi_arready (axi_arready),
        .axi_rid     (axi_rid),
        .axi_rdata   (axi_rdata),
        .axi_rresp   (axi_rresp),
        .axi_rvalid  (axi_rvalid),
        .axi_rready  (axi_rready),
        .timer_irq_o (timer_irq_o)
    );

    // Clock Generation
    initial begin
        axi_aclk = 0;
        forever #(CLK_PERIOD/2) axi_aclk = ~axi_aclk;
    end

    // Tasks
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(posedge axi_aclk);
            axi_awaddr  <= addr;
            axi_awvalid <= 1'b1;
            axi_wdata   <= data;
            axi_wstrb   <= 4'hF;
            axi_wvalid  <= 1'b1;
            axi_bready  <= 1'b1;
            wait (axi_awready && axi_wready);
            @(posedge axi_aclk);
            axi_awvalid <= 1'b0;
            axi_wvalid  <= 1'b0;
            wait (axi_bvalid);
            @(posedge axi_aclk);
            axi_bready  <= 1'b0;
        end
    endtask

    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        begin
            @(posedge axi_aclk);
            axi_araddr  <= addr;
            axi_arvalid <= 1'b1;
            axi_rready  <= 1'b1;
            wait (axi_arready);
            @(posedge axi_aclk);
            axi_arvalid <= 1'b0;
            wait (axi_rvalid);
            data = axi_rdata;
            @(posedge axi_aclk);
            axi_rready  <= 1'b0;
        end
    endtask

    reg [31:0] rdata;
    initial begin
        axi_aresetn = 0;
        axi_awid = 0; axi_awaddr = 0; axi_awvalid = 0;
        axi_wdata = 0; axi_wstrb = 0; axi_wvalid = 0;
        axi_bready = 0;
        axi_arid = 0; axi_araddr = 0; axi_arvalid = 0;
        axi_rready = 0;

        #(CLK_PERIOD * 5);
        axi_aresetn = 1;
        #(CLK_PERIOD * 5);

        // Read CTRL default
        axi_read(32'h04, rdata);
        $display("[TB_TIMER] CTRL default = 0x%08h", rdata);

        // Configure Prescaler=0, Step=1 (CFG0 at 0x10C)
        axi_write(32'h10C, 32'h0001_0000);

        // Set compare lower = 10
        axi_write(32'h118, 32'd10);
        axi_write(32'h11C, 32'd0);

        // Enable interrupt (INTR_ENABLE0 at 0x100)
        axi_write(32'h100, 32'd1);

        // Enable Timer in CTRL
        axi_write(32'h04, 32'd1);

        // Wait and observe
        wait(timer_irq_o);
        $display("[TB_TIMER] Timer interrupt triggered successfully!");

        // Read mtime
        axi_read(32'h110, rdata);
        $display("[TB_TIMER] mtime_lower = %0d", rdata);

        // Clear interrupt (INTR_STATE0 at 0x104)
        axi_write(32'h104, 32'd1);
        #(CLK_PERIOD * 2);
        $display("[TB_TIMER] Timer test completed successfully.");
        $finish;
    end

endmodule
