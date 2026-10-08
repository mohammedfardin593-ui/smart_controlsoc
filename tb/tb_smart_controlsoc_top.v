`timescale 1ns/1ps

module tb_smart_controlsoc_top;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter STRB_WIDTH = (DATA_WIDTH/8);
    parameter ID_WIDTH   = 12;

    // Clock and Reset
    reg sys_clk;
    reg sys_rst_n;

    // AXI Slave 0 Interface (Drive into Top Level)
    reg  [ID_WIDTH-1:0]      s00_axi_awid;
    reg  [ADDR_WIDTH-1:0]    s00_axi_awaddr;
    reg  [7:0]               s00_axi_awlen;
    reg  [2:0]               s00_axi_awsize;
    reg  [1:0]               s00_axi_awburst;
    reg                      s00_axi_awlock;
    reg  [3:0]               s00_axi_awcache;
    reg  [2:0]               s00_axi_awprot;
    reg                      s00_axi_awvalid;
    wire                     s00_axi_awready;
    reg  [DATA_WIDTH-1:0]    s00_axi_wdata;
    reg  [STRB_WIDTH-1:0]    s00_axi_wstrb;
    reg                      s00_axi_wlast;
    reg                      s00_axi_wvalid;
    wire                     s00_axi_wready;
    wire [ID_WIDTH-1:0]      s00_axi_bid;
    wire [1:0]               s00_axi_bresp;
    wire                     s00_axi_bvalid;
    reg                      s00_axi_bready;
    reg  [ID_WIDTH-1:0]      s00_axi_arid;
    reg  [ADDR_WIDTH-1:0]    s00_axi_araddr;
    reg  [7:0]               s00_axi_arlen;
    reg  [2:0]               s00_axi_arsize;
    reg  [1:0]               s00_axi_arburst;
    reg                      s00_axi_arlock;
    reg  [3:0]               s00_axi_arcache;
    reg  [2:0]               s00_axi_arprot;
    reg                      s00_axi_arvalid;
    wire                     s00_axi_arready;
    wire [ID_WIDTH-1:0]      s00_axi_rid;
    wire [DATA_WIDTH-1:0]    s00_axi_rdata;
    wire [1:0]               s00_axi_rresp;
    wire                     s00_axi_rlast;
    wire                     s00_axi_rvalid;
    reg                      s00_axi_rready;

    // UART External Pins
    reg  uart_rx_i;
    wire uart_tx_o;
    wire uart_interrupt_o;

    // Instantiate Top Level
    smart_controlsoc_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .s00_axi_awid(s00_axi_awid), .s00_axi_awaddr(s00_axi_awaddr), .s00_axi_awlen(s00_axi_awlen), .s00_axi_awsize(s00_axi_awsize), .s00_axi_awburst(s00_axi_awburst), .s00_axi_awlock(s00_axi_awlock), .s00_axi_awcache(s00_axi_awcache), .s00_axi_awprot(s00_axi_awprot), .s00_axi_awvalid(s00_axi_awvalid), .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata), .s00_axi_wstrb(s00_axi_wstrb), .s00_axi_wlast(s00_axi_wlast), .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
        .s00_axi_bid(s00_axi_bid), .s00_axi_bresp(s00_axi_bresp), .s00_axi_bvalid(s00_axi_bvalid), .s00_axi_bready(s00_axi_bready),
        .s00_axi_arid(s00_axi_arid), .s00_axi_araddr(s00_axi_araddr), .s00_axi_arlen(s00_axi_arlen), .s00_axi_arsize(s00_axi_arsize), .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock), .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot), .s00_axi_arvalid(s00_axi_arvalid), .s00_axi_arready(s00_axi_arready),
        .s00_axi_rid(s00_axi_rid), .s00_axi_rdata(s00_axi_rdata), .s00_axi_rresp(s00_axi_rresp), .s00_axi_rlast(s00_axi_rlast), .s00_axi_rvalid(s00_axi_rvalid), .s00_axi_rready(s00_axi_rready),
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),
        .uart_interrupt_o(uart_interrupt_o)
    );

    // Clock Generation (100 MHz)
    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk;
    end

    // AXI Write Task
    task axi_write;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge sys_clk);
            s00_axi_awaddr = addr;
            s00_axi_awvalid = 1;
            s00_axi_wdata = data;
            s00_axi_wvalid = 1;
            s00_axi_bready = 1;

            // Wait for awready
            wait(s00_axi_awready);
            @(negedge sys_clk);
            s00_axi_awvalid = 0;

            // Wait for wready
            wait(s00_axi_wready);
            @(negedge sys_clk);
            s00_axi_wvalid = 0;

            // Wait for bvalid
            wait(s00_axi_bvalid);
            @(negedge sys_clk);
            s00_axi_bready = 0;
            
            $display("[%0t] AXI Write to 0x%h: 0x%h", $time, addr, data);
        end
    endtask

    // UART Serial Capture
    reg [7:0] captured_byte;
    task capture_uart_tx;
        integer i;
        begin
            @(negedge uart_tx_o); // wait for start bit
            #400; // go to middle of start bit
            #400; // skip start bit
            for(i=0; i<8; i=i+1) begin
                captured_byte[i] = uart_tx_o;
                #400; // wait 1 bit period
            end
            $display("[%0t] UART TX Captured: 0x%h ('%c')", $time, captured_byte, captured_byte);
        end
    endtask

    initial begin
        // Initialize AXI signals
        s00_axi_awid = 0; s00_axi_awlen = 0; s00_axi_awsize = 2; s00_axi_awburst = 1; 
        s00_axi_awlock = 0; s00_axi_awcache = 0; s00_axi_awprot = 0;
        s00_axi_awaddr = 0; s00_axi_awvalid = 0;
        s00_axi_wdata = 0; s00_axi_wstrb = 4'hF; s00_axi_wlast = 1; s00_axi_wvalid = 0;
        s00_axi_bready = 0;
        
        s00_axi_arid = 0; s00_axi_arlen = 0; s00_axi_arsize = 2; s00_axi_arburst = 1; 
        s00_axi_arlock = 0; s00_axi_arcache = 0; s00_axi_arprot = 0;
        s00_axi_araddr = 0; s00_axi_arvalid = 0;
        s00_axi_rready = 0;

        uart_rx_i = 1;

        // Reset
        sys_rst_n = 0;
        #50;
        sys_rst_n = 1;
        #100;

        $display("--- Starting System-Level Interconnect + UART Test ---");

        // 1. Configure UART LCR (Line Control Register) to enable DLAB
        // UART Base is 0x2000_0000. LCR offset is 0x0C.
        axi_write(32'h2000_000C, 32'h0000_0080); // LCR[7] = 1 (DLAB)

        // 2. Set Baud Rate Divisor (DLL, DLM)
        // Set divisor to 40 (0x28). Offset 0x00 and 0x04 when DLAB=1.
        axi_write(32'h2000_0008, 32'h0000_0028); // BAUD DIVISOR (wait, the IP defines BAUD_DIV at 3'd2 -> offset 0x08)
        
        // Wait, looking at tb_axi_uart_top.v, BAUD_DIV is offset 0x08 (when DLAB doesn't matter or is 1).
        // Let's just use 0x08 for BAUD_DIV
        // The original tb: axi_write(ADDR_BAUD_DIV, 40, 12'h003); ADDR_BAUD_DIV is 0x08.
        
        // 3. Clear DLAB in LCR
        axi_write(32'h2000_000C, 32'h0000_0000); 

        // 4. Write data 'A' (0x41) to THR (Transmit Holding Register). Offset 0x00.
        fork
            begin
                axi_write(32'h2000_0000, 32'h0000_0041);
            end
            begin
                capture_uart_tx();
                if (captured_byte == 8'h41) $display("TEST PASSED: Correct byte 'A' received over UART TX!");
                else $display("TEST FAILED: Incorrect byte.");
            end
        join

        #1000;
        $display("--- Simulation Complete ---");
        $finish;
    end

endmodule
