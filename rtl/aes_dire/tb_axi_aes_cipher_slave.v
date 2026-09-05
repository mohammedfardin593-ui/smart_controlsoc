`timescale 1ns/1ps

module tb_axi_aes_cipher_slave;

    reg clk, resetn;

    reg [5:0] awaddr;
    reg awvalid;
    wire awready;

    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg wvalid;
    wire wready;

    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    reg [5:0] araddr;
    reg arvalid;
    wire arready;

    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    reg rready;

    integer errors;
    integer poll_count;

    localparam [127:0] TEST_KEY =
        128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] TEST_PT =
        128'h00112233445566778899aabbccddeeff;
    localparam [127:0] EXPECTED_CT =
        128'h69c4e0d86a7b0430d8cdb78070b4c55a;

    axi_aes_cipher_slave dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (resetn),

        .s_axi_awaddr (awaddr),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata  (wdata),
        .s_axi_wstrb  (wstrb),
        .s_axi_wvalid (wvalid),
        .s_axi_wready (wready),

        .s_axi_bresp  (bresp),
        .s_axi_bvalid (bvalid),
        .s_axi_bready (bready),

        .s_axi_araddr (araddr),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rdata  (rdata),
        .s_axi_rresp  (rresp),
        .s_axi_rvalid (rvalid),
        .s_axi_rready (rready)
    );

    always #5 clk = ~clk;

    task automatic axi_write;
        input [5:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            awaddr  <= addr;
            awvalid <= 1'b1;
            wdata   <= data;
            wstrb   <= 4'hF;
            wvalid  <= 1'b1;

            wait (awready && wready);
            @(posedge clk);
            awvalid <= 1'b0;
            wvalid  <= 1'b0;

            bready <= 1'b1;
            wait (bvalid);
            @(posedge clk);
            bready <= 1'b0;
        end
    endtask

    task automatic axi_read;
        input [5:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            araddr  <= addr;
            arvalid <= 1'b1;

            wait (arready);
            @(posedge clk);
            arvalid <= 1'b0;

            rready <= 1'b1;
            wait (rvalid);
            data = rdata;
            @(posedge clk);
            rready <= 1'b0;
        end
    endtask

    reg [31:0] rd0, rd1, rd2, rd3, status;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;

        awaddr = 0; awvalid = 0;
        wdata = 0; wstrb = 0; wvalid = 0;
        bready = 0;
        araddr = 0; arvalid = 0; rready = 0;
        errors = 0;

        repeat(5) @(posedge clk);
        resetn = 1'b1;
        repeat(2) @(posedge clk);

        $display("");
        $display("==============================================");
        $display(" AXI4-Lite AES CIPHER SLAVE TEST");
        $display("==============================================");

        // KEY = {KEY3, KEY2, KEY1, KEY0}
        axi_write(6'h04, TEST_KEY[31:0]);
        axi_write(6'h08, TEST_KEY[63:32]);
        axi_write(6'h0C, TEST_KEY[95:64]);
        axi_write(6'h10, TEST_KEY[127:96]);

        // TEXT_IN = {TIN3, TIN2, TIN1, TIN0}
        axi_write(6'h14, TEST_PT[31:0]);
        axi_write(6'h18, TEST_PT[63:32]);
        axi_write(6'h1C, TEST_PT[95:64]);
        axi_write(6'h20, TEST_PT[127:96]);

        axi_read(6'h04, rd0);
        if (rd0 !== TEST_KEY[31:0]) begin
            $display("ERROR: KEY0 readback mismatch");
            errors = errors + 1;
        end

        // CIPHER_CSR[0] = LD
        axi_write(6'h00, 32'h00000001);

        // Poll CIPHER_CSR[31] = DONE
        status = 32'h0;
        for (poll_count = 0; poll_count < 30; poll_count = poll_count + 1) begin
            axi_read(6'h00, status);
            if (status[31])
                break;
        end

        if (!status[31]) begin
            $display("ERROR: AES DONE timeout");
            errors = errors + 1;
        end
        else begin
            $display("INFO: AES DONE detected");
        end

        axi_read(6'h24, rd0);
        axi_read(6'h28, rd1);
        axi_read(6'h2C, rd2);
        axi_read(6'h30, rd3);

        $display("KEY       = %032h", TEST_KEY);
        $display("PLAINTEXT  = %032h", TEST_PT);
        $display("EXPECTED   = %032h", EXPECTED_CT);
        $display("READBACK   = %08h%08h%08h%08h", rd3,rd2,rd1,rd0);

        if ({rd3,rd2,rd1,rd0} !== EXPECTED_CT) begin
            $display("ERROR: AES CIPHERTEXT MISMATCH");
            errors = errors + 1;
        end
        else begin
            $display("PASS: AES ciphertext matches expected value");
        end

        $display("");
        if (errors == 0)
            $display("TEST DONE: 0 ERRORS - AXI AES SLAVE PASS");
        else
            $display("TEST DONE: %0d ERRORS - AXI AES SLAVE FAIL", errors);

        $finish;
    end

    initial begin
        $fsdbDumpfile("axi_aes.fsdb");
        $fsdbDumpvars(0,tb_axi_aes_cipher_slave);
    end

endmodule
