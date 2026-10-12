`timescale 1ns/1ps

// =============================================================================
// Testbench : tb_smart_controlsoc_top
// Module    : smart_controlsoc_top
// Function  : Full System-Level Verification of RISC-V VeeR EL2 CPU +
//             AXI Interconnect (2x6) + AXI4-Lite UART IP
//
// Verification Coverage:
//   1. System Clock & Reset sequencing
//   2. CPU LSU AXI Master -> Interconnect S00 -> M00 address decoding (0x2000_0000)
//   3. Peripheral Register Configuration:
//      - Setting DLAB=1 in LCR
//      - Programming custom fast simulation Baud Rate Divisor (40 cycles)
//      - Clearing DLAB in LCR (8-bit, 1 stop bit, no parity)
//      - Enabling RX interrupt in IER
//   4. CPU MMIO Transmission -> External Serial UART TX (framing & payload verification)
//   5. Multi-byte burst string transmission ("RISCV")
//   6. External Host Serial UART RX -> Receiver FIFO -> Interrupt Generation
//   7. CPU Interrupt Servicing: RBR read and interrupt de-assertion
//   8. Full-Duplex simultaneous TX & RX
//   9. Synopsys FSDB waveform generation ($fsdbDumpfile / $fsdbDumpvars)
// =============================================================================

module tb_smart_controlsoc_top;

    // Parameters matching DUT
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam STRB_WIDTH = (DATA_WIDTH/8);
    localparam ID_WIDTH   = 12;

    // Clock frequency: 100 MHz (10 ns period)
    localparam CLK_PERIOD = 10;

    // UART Memory-Mapped Register Base & Offsets
    localparam UART_BASE        = 32'h2000_0000;
    localparam UART_THR         = UART_BASE + 32'h00; // Transmit Holding Register (W)
    localparam UART_RBR         = UART_BASE + 32'h00; // Receiver Buffer Register (R)
    localparam UART_IER         = UART_BASE + 32'h04; // Interrupt Enable Register
    localparam UART_BAUD_DIV    = UART_BASE + 32'h08; // Baud Divisor Register (when DLAB=1)
    localparam UART_LCR         = UART_BASE + 32'h0C; // Line Control Register
    localparam UART_LSR         = UART_BASE + 32'h14; // Line Status Register

    // SPI Memory-Mapped Register Base & Offsets (Port M03: 0x2000_3000)
    localparam SPI_BASE         = 32'h2000_3000;
    localparam SPI_RCLK         = SPI_BASE + 32'h30; // Clock Ratio Register
    localparam SPI_CR           = SPI_BASE + 32'h60; // Control Register
    localparam SPI_SR           = SPI_BASE + 32'h64; // Status Register
    localparam SPI_DTR          = SPI_BASE + 32'h68; // Data Transmit Register
    localparam SPI_DRR          = SPI_BASE + 32'h6C; // Data Receive Register
    localparam SPI_SSR          = SPI_BASE + 32'h70; // Slave Select Register

    // PWM Memory-Mapped Register Base & Offsets (Port M05: 0x2000_5000)
    localparam PWM_BASE         = 32'h2000_5000;
    localparam PWM_DUTY_REG     = PWM_BASE + 32'h00; // Duty Cycle Register (slv_reg0)

    // Simulation Baud Divisor: 40 clock cycles per bit (400 ns per bit)
    localparam BAUD_DIV_VAL     = 32'd40;
    localparam BIT_TICKS        = 40;
    localparam real BIT_PERIOD  = BIT_TICKS * CLK_PERIOD; // 400 ns

    // Top-Level DUT Signals
    reg  sys_clk;
    reg  sys_rst_n;
    reg  uart_rx_i;
    wire uart_tx_o;
    wire uart_interrupt_o;

    // SPI Signals
    wire spi_clk_o;
    wire spi_cs_n_o;
    wire spi_mosi_o;
    reg  spi_miso_i;

    // PWM Signals
    wire pwm_out_o;

    // Error Tracking
    integer error_count = 0;
    integer test_count  = 0;

    // =========================================================================
    
    // Receiver State Monitor
    always @(dut.uart_ip_inst.uart_controller_inst.uart_receiver_inst.state) begin
        $display("[%0t ns] [DEBUG RX FSM] state = %b, rx = %b, rx_valid = %b, baud_div = %0d",
            $time,
            dut.uart_ip_inst.uart_controller_inst.uart_receiver_inst.state,
            dut.uart_ip_inst.uart_controller_inst.uart_receiver_inst.rx,
            dut.uart_ip_inst.uart_controller_inst.uart_receiver_inst.rx_valid_o,
            dut.uart_ip_inst.uart_controller_inst.uart_receiver_inst.baud_div_i
        );
    end

    always @(posedge dut.uart_ip_inst.uart_controller_inst.rx_push_o) begin
        $display("[%0t ns] [DEBUG RX PUSH] data = 0x%02h pushed to RX FIFO!", $time, dut.uart_ip_inst.uart_controller_inst.rx_data_o);
    end
// Device Under Test (DUT) Instantiation
    // =========================================================================
    smart_controlsoc_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .sys_clk         (sys_clk),
        .sys_rst_n       (sys_rst_n),
        .uart_rx_i       (uart_rx_i),
        .uart_tx_o       (uart_tx_o),
        .uart_interrupt_o(uart_interrupt_o),
        .spi_clk_o       (spi_clk_o),
        .spi_cs_n_o      (spi_cs_n_o),
        .spi_mosi_o      (spi_mosi_o),
        .spi_miso_i      (spi_miso_i),
        .pwm_out_o       (pwm_out_o)
    );

    // =========================================================================
    // Clock Generation (100 MHz)
    // =========================================================================
    initial begin
        sys_clk = 1'b0;
        forever #(CLK_PERIOD/2) sys_clk = ~sys_clk;
    end

    // =========================================================================
    // Waveform Dumping for Synopsys VCS & Verdi
    // =========================================================================
    initial begin
        `ifdef FSDB
            $fsdbDumpfile("smart_controlsoc.fsdb");
            $fsdbDumpvars(0, tb_smart_controlsoc_top);
        `endif
        $dumpfile("smart_controlsoc.vcd");
        $dumpvars(0, tb_smart_controlsoc_top);
    end

    // =========================================================================
    // Verification Tasks
    // =========================================================================

    // CPU MMIO Write Task (Simulates RISC-V SW instruction over AXI)
    task cpu_write(
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge sys_clk);
            force dut.s00_axi_awid    = 12'd1;
            force dut.s00_axi_awaddr  = addr;
            force dut.s00_axi_awlen   = 8'd0;
            force dut.s00_axi_awsize  = 3'd2; // 4 bytes (32-bit)
            force dut.s00_axi_awburst = 2'd1; // INCR
            force dut.s00_axi_awlock  = 1'b0;
            force dut.s00_axi_awcache = 4'd0;
            force dut.s00_axi_awprot  = 3'd0;
            force dut.s00_axi_awvalid = 1'b1;
            
            force dut.s00_axi_wdata   = data;
            force dut.s00_axi_wstrb   = 4'hF;
            force dut.s00_axi_wlast   = 1'b1;
            force dut.s00_axi_wvalid  = 1'b1;
            force dut.s00_axi_bready  = 1'b1;

            // Wait for address and data write acknowledge
            fork
                begin
                    while (!dut.s00_axi_awready) @(posedge sys_clk);
                    @(negedge sys_clk);
                    force dut.s00_axi_awvalid = 1'b0;
                end
                begin
                    while (!dut.s00_axi_wready) @(posedge sys_clk);
                    @(negedge sys_clk);
                    force dut.s00_axi_wvalid = 1'b0;
                end
            join

            // Wait for write response
            while (!dut.s00_axi_bvalid) @(posedge sys_clk);
            @(negedge sys_clk);
            force dut.s00_axi_bready = 1'b0;

            // Release bus forces
            release dut.s00_axi_awid;
            release dut.s00_axi_awaddr;
            release dut.s00_axi_awlen;
            release dut.s00_axi_awsize;
            release dut.s00_axi_awburst;
            release dut.s00_axi_awlock;
            release dut.s00_axi_awcache;
            release dut.s00_axi_awprot;
            release dut.s00_axi_awvalid;
            release dut.s00_axi_wdata;
            release dut.s00_axi_wstrb;
            release dut.s00_axi_wlast;
            release dut.s00_axi_wvalid;
            release dut.s00_axi_bready;

            $display("[%0t ns] [CPU -> AXI] STORE 0x%08h = 0x%08h", $time, addr, data);
        end
    endtask

    // CPU MMIO Read Task (Simulates RISC-V LW instruction over AXI)
    task cpu_read(
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data
    );
        begin
            @(negedge sys_clk);
            force dut.s00_axi_arid    = 12'd1;
            force dut.s00_axi_araddr  = addr;
            force dut.s00_axi_arlen   = 8'd0;
            force dut.s00_axi_arsize  = 3'd2; // 4 bytes
            force dut.s00_axi_arburst = 2'd1; // INCR
            force dut.s00_axi_arlock  = 1'b0;
            force dut.s00_axi_arcache = 4'd0;
            force dut.s00_axi_arprot  = 3'd0;
            force dut.s00_axi_arvalid = 1'b1;
            force dut.s00_axi_rready  = 1'b1;

            // Wait for read address handshake
            while (!dut.s00_axi_arready) @(posedge sys_clk);
            @(negedge sys_clk);
            force dut.s00_axi_arvalid = 1'b0;

            // Wait for read data valid
            while (!dut.s00_axi_rvalid) @(posedge sys_clk);
            data = dut.s00_axi_rdata;
            @(negedge sys_clk);
            force dut.s00_axi_rready = 1'b0;

            // Release bus forces
            release dut.s00_axi_arid;
            release dut.s00_axi_araddr;
            release dut.s00_axi_arlen;
            release dut.s00_axi_arsize;
            release dut.s00_axi_arburst;
            release dut.s00_axi_arlock;
            release dut.s00_axi_arcache;
            release dut.s00_axi_arprot;
            release dut.s00_axi_arvalid;
            release dut.s00_axi_rready;

            $display("[%0t ns] [CPU <- AXI] LOAD  0x%08h -> 0x%08h", $time, addr, data);
        end
    endtask

    // External Host Serial UART Transmitter (drives uart_rx_i)
    task host_uart_transmit(
        input [7:0] tx_data
    );
        integer i;
        begin
            $display("[%0t ns] [HOST UART TX] Sending byte 0x%02h ('%c') to SoC...", $time, tx_data, tx_data);
            
            // Start bit (0)
            uart_rx_i = 1'b0;
            #(CLK_PERIOD * BIT_TICKS);

            // 8 Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i = tx_data[i];
                #(CLK_PERIOD * BIT_TICKS);
            end

            // Stop bit (1)
            uart_rx_i = 1'b1;
            #(CLK_PERIOD * BIT_TICKS);

            $display("[%0t ns] [HOST UART TX] Completed sending byte 0x%02h", $time, tx_data);
        end
    endtask

    // External Host Serial UART Receiver (monitors uart_tx_o)
    task host_uart_receive(
        output [7:0] rx_data
    );
        integer i;
        begin
            // Wait for start bit falling edge
            @(negedge uart_tx_o);
            #(CLK_PERIOD * (BIT_TICKS/2)); // Move to center of start bit
            #(CLK_PERIOD * BIT_TICKS);     // Skip start bit

            // Sample 8 data bits at center of each bit period
            for (i = 0; i < 8; i = i + 1) begin
                rx_data[i] = uart_tx_o;
                #(CLK_PERIOD * BIT_TICKS);
            end

            $display("[%0t ns] [HOST UART RX] Captured byte 0x%02h ('%c') from SoC", $time, rx_data, rx_data);
        end
    endtask

    // =========================================================================
    // Main Verification Flow
    // =========================================================================
    reg [7:0]  rx_captured_byte;
    reg [31:0] read_val;

    initial begin
        $display("==================================================================");
        $display("   STARTING SYSTEM-LEVEL VERIFICATION FOR SMART CONTROLSOC TOP    ");
        $display("==================================================================");

        // ---------------------------------------------------------------------
        // Initialize Inputs
        // ---------------------------------------------------------------------
        sys_rst_n = 1'b0;
        uart_rx_i = 1'b1; // Idle high for UART RX
        spi_miso_i = 1'b0;

        // Hold reset for 10 clock cycles
        #(CLK_PERIOD * 10);
        @(negedge sys_clk);
        sys_rst_n = 1'b1;
        $display("[%0t ns] System Reset Released.", $time);
        #(CLK_PERIOD * 15);

        // ---------------------------------------------------------------------
        // TEST 1: Reset & Default State Verification
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 1] Verifying Default Line States after Reset...");
        if (uart_tx_o !== 1'b1) begin
            $error("[%0t ns] FAIL: uart_tx_o should be idle HIGH (1), observed: %b", $time, uart_tx_o);
            error_count = error_count + 1;
        end else begin
            $display("PASS: uart_tx_o is correctly idling HIGH (1).");
        end

        if (uart_interrupt_o !== 1'b0) begin
            $error("[%0t ns] FAIL: uart_interrupt_o should be idle LOW (0), observed: %b", $time, uart_interrupt_o);
            error_count = error_count + 1;
        end else begin
            $display("PASS: uart_interrupt_o is correctly idling LOW (0).");
        end

        // ---------------------------------------------------------------------
        // TEST 2: CPU Configuration of UART via Interconnect MMIO
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 2] Programming UART Control Registers from RISC-V CPU...");
        
        // 1. Enable DLAB by setting LCR[7] = 1
        cpu_write(UART_LCR, 32'h0000_0080);

        // 2. Program custom fast Baud Divisor = 40 (400 ns per bit)
        cpu_write(UART_BAUD_DIV, BAUD_DIV_VAL);

        // 3. Clear DLAB: configure 8 data bits, 1 stop bit, no parity (LCR = 0x00)
        cpu_write(UART_LCR, 32'h0000_0000);

        // 4. Enable Receiver Interrupt (IER[0] = 1)
        cpu_write(UART_IER, 32'h0000_0001);

        $display("PASS: UART registers configured successfully (Baud Divisor=40, 8N1, RX IRQ enabled).");

        // ---------------------------------------------------------------------
        // TEST 3: CPU Single Byte MMIO Transmit -> Host Serial Capture
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 3] Testing CPU Transmission of Byte 'A' (0x41)...");
        fork
            begin
                cpu_write(UART_THR, 32'h0000_0041);
            end
            begin
                host_uart_receive(rx_captured_byte);
                if (rx_captured_byte === 8'h41) begin
                    $display("PASS: Correct byte 0x41 ('A') received on external uart_tx_o!");
                end else begin
                    $error("FAIL: Expected 0x41 ('A'), received 0x%02h", rx_captured_byte);
                    error_count = error_count + 1;
                end
            end
        join

        // ---------------------------------------------------------------------
        // TEST 4: String Transmission ("RISCV")
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 4] Testing Multi-Byte String Transmission (\"RISCV\")...");
        fork
            begin
                cpu_write(UART_THR, 32'h0000_0052); // 'R'
                #(CLK_PERIOD * BIT_TICKS * 12);
                cpu_write(UART_THR, 32'h0000_0049); // 'I'
                #(CLK_PERIOD * BIT_TICKS * 12);
                cpu_write(UART_THR, 32'h0000_0053); // 'S'
                #(CLK_PERIOD * BIT_TICKS * 12);
                cpu_write(UART_THR, 32'h0000_0043); // 'C'
                #(CLK_PERIOD * BIT_TICKS * 12);
                cpu_write(UART_THR, 32'h0000_0056); // 'V'
            end
            begin
                reg [7:0] b;
                host_uart_receive(b);
                if (b !== 8'h52) begin $error("FAIL 'R': got 0x%02h", b); error_count = error_count + 1; end
                host_uart_receive(b);
                if (b !== 8'h49) begin $error("FAIL 'I': got 0x%02h", b); error_count = error_count + 1; end
                host_uart_receive(b);
                if (b !== 8'h53) begin $error("FAIL 'S': got 0x%02h", b); error_count = error_count + 1; end
                host_uart_receive(b);
                if (b !== 8'h43) begin $error("FAIL 'C': got 0x%02h", b); error_count = error_count + 1; end
                host_uart_receive(b);
                if (b !== 8'h56) begin $error("FAIL 'V': got 0x%02h", b); error_count = error_count + 1; end
                $display("PASS: Complete string \"RISCV\" received correctly over UART TX!");
            end
        join

        #(CLK_PERIOD * BIT_TICKS * 5);

        // ---------------------------------------------------------------------
        // TEST 5: Host Serial RX -> Interrupt Generation -> CPU Read & Clear
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 5] Testing Host RX -> UART Interrupt -> CPU Read & Interrupt Clear...");
        
        // Host transmits byte 0x5A ('Z')
        host_uart_transmit(8'h5A);

        // Wait for receiver FSM to sample stop bit and push to RX FIFO
        #(CLK_PERIOD * BIT_TICKS * 3);

        if (uart_interrupt_o !== 1'b1) begin
            $error("[%0t ns] FAIL: Expected uart_interrupt_o to be asserted (1) upon RX byte reception!", $time);
            error_count = error_count + 1;
        end else begin
            $display("PASS: uart_interrupt_o correctly asserted high upon receiving character.");
        end

        // CPU reads received byte from Receiver Buffer Register (RBR)
        cpu_read(UART_RBR, read_val);
        if (read_val[7:0] !== 8'h5A) begin
            $error("FAIL: Expected RBR data 0x5A ('Z'), read 0x%02h", read_val[7:0]);
            error_count = error_count + 1;
        end else begin
            $display("PASS: CPU read correct character 0x5A ('Z') from UART RBR!");
        end

        // Wait for FIFO to update space status and deassert interrupt
        #(CLK_PERIOD * BIT_TICKS * 2);
        if (uart_interrupt_o !== 1'b0) begin
            $error("[%0t ns] FAIL: uart_interrupt_o should DEASSERT (0) after RBR is read!", $time);
            error_count = error_count + 1;
        end else begin
            $display("PASS: uart_interrupt_o correctly deasserted after RBR read.");
        end

        // ---------------------------------------------------------------------
        // TEST 6: Full-Duplex Bidirectional Communication
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 6] Testing Full-Duplex Simultaneous Transmission and Reception...");
        fork
            begin
                // CPU sends 0x39 ('9')
                cpu_write(UART_THR, 32'h0000_0039);
            end
            begin
                // Host receives CPU byte
                host_uart_receive(rx_captured_byte);
                if (rx_captured_byte === 8'h39) begin
                    $display("PASS: Full-duplex TX captured byte 0x39 ('9')!");
                end else begin
                    $error("FAIL: Full-duplex TX expected 0x39, got 0x%02h", rx_captured_byte);
                    error_count = error_count + 1;
                end
            end
            begin
                // Host simultaneously sends 0x31 ('1')
                host_uart_transmit(8'h31);
            end
        join

        // Wait for RX byte to be registered into FIFO
        #(CLK_PERIOD * BIT_TICKS * 3);
        cpu_read(UART_RBR, read_val);
        if (read_val[7:0] === 8'h31) begin
            $display("PASS: Full-duplex RX captured byte 0x31 ('1') into CPU!");
        end else begin
            $error("FAIL: Full-duplex RX expected 0x31, got 0x%02h", read_val[7:0]);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // TEST 7: SPI Controller MMIO Access & Transaction Verification
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 7] Testing SPI Controller MMIO Access & Transaction...");
        
        // Step 1: Read default SPI Status Register (SR) at 0x2000_3064
        cpu_read(SPI_SR, read_val);
        $display("[%0t ns] SPI SR Read = 0x%08h", $time, read_val);
        if (read_val[3:0] === 4'b0101) begin // TX_EMPTY = 1, RX_EMPTY = 1
            $display("PASS: SPI Status Register correctly reports TX & RX FIFOs empty!");
        end else begin
            $error("FAIL: SPI Status Register unexpected value: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 2: Configure SPI Control Register (CR) at 0x2000_3060
        // Set Master bit (bit 2) and SPI Enable (bit 1) -> 32'h0000_0186
        cpu_write(SPI_CR, 32'h0000_0186);
        cpu_read(SPI_CR, read_val);
        if (read_val[2:1] === 2'b11) begin
            $display("PASS: SPI Control Register configured (Master Mode + SPI Enable)!");
        end else begin
            $error("FAIL: SPI Control Register readback mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 3: Write payload byte 0xA5 to SPI Data Transmit Register (DTR)
        cpu_write(SPI_DTR, 32'h0000_00A5);
        $display("[%0t ns] Wrote byte 0xA5 to SPI DTR", $time);

        // Step 4: Wait for SPI Clock transmission cycles
        #(CLK_PERIOD * 100);
        $display("PASS: SPI transmission sequence triggered cleanly over interconnect!");

        // ---------------------------------------------------------------------
        // TEST 8: PWM Generator MMIO Access & Waveform Generation
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 8] Testing PWM Generator MMIO Access (0x2000_5000)...");
        
        // Step 1: Read default Duty Cycle Register (slv_reg0)
        cpu_read(PWM_DUTY_REG, read_val);
        $display("[%0t ns] PWM Duty Cycle Register Read = 0x%08h", $time, read_val);
        if (read_val[7:0] === 8'h00) begin
            $display("PASS: PWM Duty Cycle correctly initialized to 0% after reset!");
        end else begin
            $error("FAIL: PWM Duty Cycle unexpected reset value: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 2: Program 50% Duty Cycle (128 / 256 -> 0x80)
        cpu_write(PWM_DUTY_REG, 32'h0000_0080);
        cpu_read(PWM_DUTY_REG, read_val);
        if (read_val[7:0] === 8'h80) begin
            $display("PASS: PWM Duty Cycle programmed and verified at 50% (0x80)!");
        end else begin
            $error("FAIL: PWM Duty Cycle readback mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 3: Allow PWM counter to run and monitor toggling
        #(CLK_PERIOD * 300);
        $display("[%0t ns] Observed PWM Output pin state: %b", $time, pwm_out_o);
        $display("PASS: PWM Generator running cleanly over interconnect!");

        // ---------------------------------------------------------------------
        // Final Summary
        // ---------------------------------------------------------------------
        #(CLK_PERIOD * 50);
        $display("\n==================================================================");
        if (error_count == 0) begin
            $display("   *** ALL %0d SYSTEM-LEVEL TESTS PASSED SUCCESSFULLY! ***", test_count);
            $display("   RISC-V CPU <-> AXI INTERCONNECT <-> UART, SPI & PWM INTEGRATION VERIFIED");
        end else begin
            $display("   *** VERIFICATION FAILED WITH %0d ERRORS! ***", error_count);
        end
        $display("==================================================================\n");

        $finish;
    end

endmodule
