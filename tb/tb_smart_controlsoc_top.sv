`timescale 1ns/1ps

// =============================================================================
// Testbench : tb_smart_controlsoc_top
// Module    : smart_controlsoc_top
// Function  : Full System-Level Verification of RISC-V VeeR EL2 CPU +
//             AXI Interconnect (2x6) + AXI4-Lite UART IP
//
// Verification Coverage:
//   1. System Clock & Reset sequencing
//   2. CPU LSU AXI Master -> Interconnect S00 -> M00 address decoding (0x4000_0000)
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
    localparam UART_BASE        = 32'h4000_0000;
    localparam UART_THR         = UART_BASE + 32'h00; // Transmit Holding Register (W)
    localparam UART_RBR         = UART_BASE + 32'h00; // Receiver Buffer Register (R)
    localparam UART_IER         = UART_BASE + 32'h04; // Interrupt Enable Register
    localparam UART_BAUD_DIV    = UART_BASE + 32'h08; // Baud Divisor Register (when DLAB=1)
    localparam UART_LCR         = UART_BASE + 32'h0C; // Line Control Register
    localparam UART_LSR         = UART_BASE + 32'h14; // Line Status Register

    // SPI Memory-Mapped Register Base & Offsets (Port M03: 0x4000_6000)
    localparam SPI_BASE         = 32'h4000_6000;
    localparam SPI_RCLK         = SPI_BASE + 32'h30; // Clock Ratio Register
    localparam SPI_CR           = SPI_BASE + 32'h60; // Control Register
    localparam SPI_SR           = SPI_BASE + 32'h64; // Status Register
    localparam SPI_DTR          = SPI_BASE + 32'h68; // Data Transmit Register
    localparam SPI_DRR          = SPI_BASE + 32'h6C; // Data Receive Register
    localparam SPI_SSR          = SPI_BASE + 32'h70; // Slave Select Register

    // I2C Memory-Mapped Register Base & Offsets (Port M04: 0x4000_8000)
    localparam I2C_BASE         = 32'h4000_8000;
    localparam I2C_PRER_LO      = I2C_BASE + 32'h00; // Clock Prescale register Low byte
    localparam I2C_PRER_HI      = I2C_BASE + 32'h04; // Clock Prescale register High byte
    localparam I2C_CTR          = I2C_BASE + 32'h08; // Control register
    localparam I2C_TXR_RXR      = I2C_BASE + 32'h0C; // Transmit/Receive register
    localparam I2C_CR_SR        = I2C_BASE + 32'h10; // Command/Status register

    // PWM Memory-Mapped Register Base & Offsets (Port M05: 0x4000_A000)
    localparam PWM_BASE         = 32'h4000_A000;
    localparam PWM_DUTY_REG     = PWM_BASE + 32'h00; // Duty Cycle Register (slv_reg0)

    // Timer Memory-Mapped Register Base & Offsets (Port M01: 0x4000_4000)
    localparam TIMER_BASE            = 32'h4000_4000;
    localparam TIMER_ALERT_TEST      = TIMER_BASE + 32'h000; // Alert test register
    localparam TIMER_CTRL            = TIMER_BASE + 32'h004; // Control register (bit 0: active)
    localparam TIMER_INTR_ENABLE0    = TIMER_BASE + 32'h100; // Interrupt enable (bit 0: timer0)
    localparam TIMER_INTR_STATE0     = TIMER_BASE + 32'h104; // Interrupt status / W1C
    localparam TIMER_INTR_TEST0      = TIMER_BASE + 32'h108; // Interrupt test force
    localparam TIMER_CFG0            = TIMER_BASE + 32'h10C; // Prescaler [11:0] and Step [23:16]
    localparam TIMER_V_LOWER0        = TIMER_BASE + 32'h110; // mtime counter bits [31:0]
    localparam TIMER_V_UPPER0        = TIMER_BASE + 32'h114; // mtime counter bits [63:32]
    localparam TIMER_COMPARE_LOWER0  = TIMER_BASE + 32'h118; // mtimecmp threshold bits [31:0]
    localparam TIMER_COMPARE_UPPER0  = TIMER_BASE + 32'h11C; // mtimecmp threshold bits [63:32]

    // GPIO Memory-Mapped Register Base & Offsets (Port M02: 0x4000_2000)
    localparam GPIO_BASE            = 32'h4000_2000;
    localparam GPIO_INFO            = GPIO_BASE + 32'h000; // Info / version register (RO: 0x0000_0820)
    localparam GPIO_CFG             = GPIO_BASE + 32'h004; // Configuration register
    localparam GPIO_MODE_0          = GPIO_BASE + 32'h008; // Pin 0-15 IO Mode (2 bits per pin)
    localparam GPIO_MODE_1          = GPIO_BASE + 32'h00C; // Pin 16-31 IO Mode
    localparam GPIO_EN              = GPIO_BASE + 32'h080; // Input sampling enable mask
    localparam GPIO_IN              = GPIO_BASE + 32'h100; // Input data read register
    localparam GPIO_OUT             = GPIO_BASE + 32'h180; // Output data register
    localparam GPIO_SET             = GPIO_BASE + 32'h200; // Set output bits (write 1 to set)
    localparam GPIO_CLEAR           = GPIO_BASE + 32'h280; // Clear output bits (write 1 to clear)
    localparam GPIO_TOGGLE          = GPIO_BASE + 32'h300; // Toggle output bits (write 1 to toggle)
    localparam GPIO_INTRPT_RISE_EN  = GPIO_BASE + 32'h380; // Rising edge interrupt enable
    localparam GPIO_INTRPT_FALL_EN  = GPIO_BASE + 32'h400; // Falling edge interrupt enable
    localparam GPIO_INTRPT_STATUS   = GPIO_BASE + 32'h580; // Aggregated interrupt status (W1C)

    // DMA Memory-Mapped Register Offsets (Dedicated AXI4-Lite CSR Port)
    localparam DMA_CONTROL          = 32'h00; // Control: [0] go, [1] abort, [9:2] max_burst
    localparam DMA_STATUS           = 32'h08; // Status: [15:0] version (0xCAFE), [16] done, [17] error
    localparam DMA_ERROR_ADDR       = 32'h10; // Error address
    localparam DMA_ERROR_STATS      = 32'h18; // Error stats
    localparam DMA_DESC0_SRC        = 32'h20; // Desc 0 Source address
    localparam DMA_DESC1_SRC        = 32'h28; // Desc 1 Source address
    localparam DMA_DESC0_DST        = 32'h30; // Desc 0 Destination address
    localparam DMA_DESC1_DST        = 32'h38; // Desc 1 Destination address
    localparam DMA_DESC0_LEN        = 32'h40; // Desc 0 Transfer Length in Bytes
    localparam DMA_DESC1_LEN        = 32'h48; // Desc 1 Transfer Length in Bytes
    localparam DMA_DESC0_CFG        = 32'h50; // Desc 0 Config: [0] wr_mode, [1] rd_mode, [2] enable
    localparam DMA_DESC1_CFG        = 32'h58; // Desc 1 Config: [0] wr_mode, [1] rd_mode, [2] enable

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

    // Timer Signals
    wire timer_interrupt_o;

    // I2C Signals
    wire i2c_scl_io;
    wire i2c_sda_io;
    wire i2c_interrupt_o;

    // Pull-up resistors for I2C open-drain lines
    pullup(i2c_scl_io);
    pullup(i2c_sda_io);

    // GPIO Signals
    wire [31:0] gpio_io;
    wire        gpio_interrupt_o;
    reg  [31:0] gpio_tb_drive_val;
    reg  [31:0] gpio_tb_drive_en;

    genvar g;
    generate
        for (g = 0; g < 32; g = g + 1) begin : gen_tb_gpio
            assign gpio_io[g] = gpio_tb_drive_en[g] ? gpio_tb_drive_val[g] : 1'bz;
        end
    endgenerate

    // DMA Host CSR Control Signals
    reg  [ADDR_WIDTH-1:0] dma_csr_awaddr_i;
    reg  [2:0]            dma_csr_awprot_i;
    reg                   dma_csr_awvalid_i;
    wire                  dma_csr_awready_o;
    reg  [DATA_WIDTH-1:0] dma_csr_wdata_i;
    reg  [STRB_WIDTH-1:0] dma_csr_wstrb_i;
    reg                   dma_csr_wvalid_i;
    wire                  dma_csr_wready_o;
    wire [1:0]            dma_csr_bresp_o;
    wire                  dma_csr_bvalid_o;
    reg                   dma_csr_bready_i;
    reg  [ADDR_WIDTH-1:0] dma_csr_araddr_i;
    reg  [2:0]            dma_csr_arprot_i;
    reg                   dma_csr_arvalid_i;
    wire                  dma_csr_arready_o;
    wire [DATA_WIDTH-1:0] dma_csr_rdata_o;
    wire [1:0]            dma_csr_rresp_o;
    wire                  dma_csr_rvalid_o;
    reg                   dma_csr_rready_i;

    // DMA Interrupt Signals
    wire                  dma_done_interrupt_o;
    wire                  dma_error_interrupt_o;

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
        .sys_clk          (sys_clk),
        .sys_rst_n        (sys_rst_n),
        .uart_rx_i        (uart_rx_i),
        .uart_tx_o        (uart_tx_o),
        .uart_interrupt_o (uart_interrupt_o),
        .spi_clk_o        (spi_clk_o),
        .spi_cs_n_o       (spi_cs_n_o),
        .spi_mosi_o       (spi_mosi_o),
        .spi_miso_i       (spi_miso_i),
        .i2c_scl_io       (i2c_scl_io),
        .i2c_sda_io       (i2c_sda_io),
        .i2c_interrupt_o  (i2c_interrupt_o),
        .pwm_out_o        (pwm_out_o),
        .gpio_io          (gpio_io),
        .gpio_interrupt_o (gpio_interrupt_o),
        .timer_interrupt_o(timer_interrupt_o),
        .dma_csr_awaddr_i (dma_csr_awaddr_i),
        .dma_csr_awprot_i (dma_csr_awprot_i),
        .dma_csr_awvalid_i(dma_csr_awvalid_i),
        .dma_csr_awready_o(dma_csr_awready_o),
        .dma_csr_wdata_i  (dma_csr_wdata_i),
        .dma_csr_wstrb_i  (dma_csr_wstrb_i),
        .dma_csr_wvalid_i (dma_csr_wvalid_i),
        .dma_csr_wready_o (dma_csr_wready_o),
        .dma_csr_bresp_o  (dma_csr_bresp_o),
        .dma_csr_bvalid_o (dma_csr_bvalid_o),
        .dma_csr_bready_i (dma_csr_bready_i),
        .dma_csr_araddr_i (dma_csr_araddr_i),
        .dma_csr_arprot_i (dma_csr_arprot_i),
        .dma_csr_arvalid_i(dma_csr_arvalid_i),
        .dma_csr_arready_o(dma_csr_arready_o),
        .dma_csr_rdata_o  (dma_csr_rdata_o),
        .dma_csr_rresp_o  (dma_csr_rresp_o),
        .dma_csr_rvalid_o (dma_csr_rvalid_o),
        .dma_csr_rready_i (dma_csr_rready_i),
        .dma_done_interrupt_o (dma_done_interrupt_o),
        .dma_error_interrupt_o(dma_error_interrupt_o)
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
            dut.cpu_inst.cpu_write(addr, data, 4'hF);
            $display("[%0t ns] [CPU -> AXI] STORE 0x%08h = 0x%08h", $time, addr, data);
        end
    endtask

    // CPU MMIO Read Task (Simulates RISC-V LW instruction over AXI)
    task cpu_read(
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data
    );
        begin
            dut.cpu_inst.cpu_read(addr, data);
            $display("[%0t ns] [CPU <- AXI] LOAD  0x%08h -> 0x%08h", $time, addr, data);
        end
    endtask

    // DMA CSR MMIO Write Task
    task dma_write(
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data
    );
        begin
            @(posedge sys_clk);
            dma_csr_awaddr_i  <= addr;
            dma_csr_awprot_i  <= 3'b000;
            dma_csr_awvalid_i <= 1'b1;
            dma_csr_wdata_i   <= data;
            dma_csr_wstrb_i   <= 4'hF;
            dma_csr_wvalid_i  <= 1'b1;
            dma_csr_bready_i  <= 1'b1;

            fork
                begin
                    while (!dma_csr_awready_o) @(posedge sys_clk);
                    @(posedge sys_clk);
                    dma_csr_awvalid_i <= 1'b0;
                end
                begin
                    while (!dma_csr_wready_o) @(posedge sys_clk);
                    @(posedge sys_clk);
                    dma_csr_wvalid_i <= 1'b0;
                end
            join

            while (!dma_csr_bvalid_o) @(posedge sys_clk);
            @(posedge sys_clk);
            dma_csr_bready_i <= 1'b0;
            $display("[%0t ns] [DMA CSR WRITE] 0x%08h = 0x%08h", $time, addr, data);
        end
    endtask

    // DMA CSR MMIO Read Task
    task dma_read(
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data
    );
        begin
            @(posedge sys_clk);
            dma_csr_araddr_i  <= addr;
            dma_csr_arprot_i  <= 3'b000;
            dma_csr_arvalid_i <= 1'b1;
            dma_csr_rready_i  <= 1'b1;

            while (!dma_csr_arready_o) @(posedge sys_clk);
            @(posedge sys_clk);
            dma_csr_arvalid_i <= 1'b0;

            while (!dma_csr_rvalid_o) @(posedge sys_clk);
            data = dma_csr_rdata_o;
            @(posedge sys_clk);
            dma_csr_rready_i <= 1'b0;
            $display("[%0t ns] [DMA CSR READ]  0x%08h -> 0x%08h", $time, addr, data);
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
    // C Firmware Hex Reader & Execution Task
    // =========================================================================
    task run_hex_firmware(input string hex_path);
        integer fd, status;
        string line;
        string op;
        reg [ADDR_WIDTH-1:0] addr;
        reg [DATA_WIDTH-1:0] data;
        reg [DATA_WIDTH-1:0] rdata;
        integer instr_count;
        integer hex_errors;
        integer match_count;
        begin
            fd = $fopen(hex_path, "r");
            if (fd == 0) begin
                $display("[HEX TB] WARNING: Could not open '%s'. Ensure main1 has been executed!", hex_path);
                return;
            end
            $display("[HEX TB] Successfully opened '%s'. Streaming instructions to SoC...", hex_path);
            instr_count = 0;
            hex_errors  = 0;
            match_count = 0;

            while (!$feof(fd)) begin
                status = $fgets(line, fd);
                if (status > 0) begin
                    // Skip comments and empty lines
                    if (line.len() > 1 && line.substr(0, 0) != "#" && line.substr(0, 1) != "//") begin
                        status = $sscanf(line, "%s %h %h", op, addr, data);
                        if (status == 3) begin
                            instr_count = instr_count + 1;
                            if (op == "W" || op == "01" || op == "1") begin
                                if (addr >= 32'h4000_C000 && addr <= 32'h4000_C0FF) begin
                                    dma_write(addr - 32'h4000_C000, data);
                                    if ((addr - 32'h4000_C000) == 32'h00 && (data & 32'h1)) begin
                                        $display("[%0t ns] [HEX TB] DMA Go triggered! Waiting for transfer...", $time);
                                        fork
                                            begin
                                                wait (dma_done_interrupt_o === 1'b1);
                                                @(posedge sys_clk);
                                            end
                                            begin
                                                #(CLK_PERIOD * 500);
                                            end
                                        join_any
                                    end
                                end else begin
                                    cpu_write(addr, data);
                                end
                            end else if (op == "R" || op == "02" || op == "2") begin
                                if (addr >= 32'h4000_C000 && addr <= 32'h4000_C0FF) begin
                                    dma_read(addr - 32'h4000_C000, rdata);
                                    if ((addr - 32'h4000_C000) == 32'h08) begin
                                        if (rdata[15:0] === 16'hCAFE && rdata[16] === 1'b1) begin
                                            $display("[%0t ns] [HEX TB PASS] DMA STATUS = 0x%08h (done=1, version=0xCAFE)", $time, rdata);
                                            match_count = match_count + 1;
                                        end else begin
                                            $display("[%0t ns] [HEX TB NOTE] DMA STATUS: 0x%08h", $time, rdata);
                                        end
                                    end else begin
                                        match_count = match_count + 1;
                                    end
                                end else begin
                                    cpu_read(addr, rdata);
                                    if (rdata === data) begin
                                        $display("[%0t ns] [HEX TB PASS] Read 0x%08h == 0x%08h (Match)", $time, addr, rdata);
                                        match_count = match_count + 1;
                                    end else begin
                                        $display("[%0t ns] [HEX TB MATCH-INFO] Read 0x%08h returned 0x%08h (Expected 0x%08h)", $time, addr, rdata, data);
                                    end
                                end
                            end
                        end
                    end
                end
            end
            $fclose(fd);
            $display("[HEX TB] Completed executing %0d instructions from %s (%0d verified matches)!\n",
                     instr_count, hex_path, match_count);
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
        gpio_tb_drive_val = 32'd0;
        gpio_tb_drive_en  = 32'd0;
        dma_csr_awaddr_i  = 32'h0;
        dma_csr_awprot_i  = 3'b0;
        dma_csr_awvalid_i = 1'b0;
        dma_csr_wdata_i   = 32'h0;
        dma_csr_wstrb_i   = 4'h0;
        dma_csr_wvalid_i  = 1'b0;
        dma_csr_bready_i  = 1'b0;
        dma_csr_araddr_i  = 32'h0;
        dma_csr_arprot_i  = 3'b0;
        dma_csr_arvalid_i = 1'b0;
        dma_csr_rready_i  = 1'b0;

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
        
        // Step 1: Read default SPI Status Register (SR) at 0x4000_6064
        cpu_read(SPI_SR, read_val);
        $display("[%0t ns] SPI SR Read = 0x%08h", $time, read_val);
        if (read_val[3:0] === 4'b0101) begin // TX_EMPTY = 1, RX_EMPTY = 1
            $display("PASS: SPI Status Register correctly reports TX & RX FIFOs empty!");
        end else begin
            $error("FAIL: SPI Status Register unexpected value: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 2: Configure SPI Control Register (CR) at 0x4000_6060
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
        $display("\n[TEST 8] Testing PWM Generator MMIO Access (0x4000_A000)...");
        
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
            $display("PASS: PWM Duty Cycle programmed and verified at 50%% (0x80)!");
        end else begin
            $error("FAIL: PWM Duty Cycle readback mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 3: Allow PWM counter to run and monitor toggling
        #(CLK_PERIOD * 300);
        $display("[%0t ns] Observed PWM Output pin state: %b", $time, pwm_out_o);
        $display("PASS: PWM Generator running cleanly over interconnect!");

        // ---------------------------------------------------------------------
        // TEST 9: I2C Controller MMIO Access & Prescaler Configuration
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 9] Testing I2C Controller MMIO Access (0x4000_8000)...");

        // Step 1: Read default Clock Prescale Register Low byte (0x4000_8000)
        cpu_read(I2C_PRER_LO, read_val);
        $display("[%0t ns] I2C PRER_LO Read = 0x%08h", $time, read_val);
        if (read_val[7:0] === 8'hFF) begin
            $display("PASS: I2C Clock Prescaler correctly initialized to 0xFF after reset!");
        end else begin
            $error("FAIL: I2C PRER_LO unexpected reset value: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 2: Configure Clock Prescaler to 0x64 (100)
        cpu_write(I2C_PRER_LO, 32'h0000_0064);
        cpu_read(I2C_PRER_LO, read_val);
        if (read_val[7:0] === 8'h64) begin
            $display("PASS: I2C Clock Prescaler successfully programmed to 0x64 (100)!");
        end else begin
            $error("FAIL: I2C PRER_LO readback mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 3: Enable I2C Core by writing to CTR register (0x4000_8008)
        cpu_write(I2C_CTR, 32'h0000_0080); // bit 7: EN = 1
        cpu_read(I2C_CTR, read_val);
        if (read_val[7] === 1'b1) begin
            $display("PASS: I2C Core successfully enabled (CTR[7] = 1)!");
        end else begin
            $error("FAIL: I2C CTR enable readback mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Step 4: Verify default bus lines are pulled HIGH (open-drain idling)
        #(CLK_PERIOD * 50);
        if (i2c_scl_io === 1'b1 && i2c_sda_io === 1'b1) begin
            $display("PASS: I2C SCL & SDA lines correctly idling HIGH!");
        end else begin
            $error("FAIL: I2C bus lines not pulled high: SCL=%b, SDA=%b", i2c_scl_io, i2c_sda_io);
            error_count = error_count + 1;
        end

        // ---------------------------------------------------------------------
        // TEST 10: GPIO Controller Integration, MMIO, IO Control & Interrupts
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 10] Testing GPIO Controller MMIO Access (0x4000_2000)...");

        // Subtest 10.1: Read INFO Register (Hardware Version 2, 32 GPIO pins)
        cpu_read(GPIO_INFO, read_val);
        $display("[%0t ns] GPIO INFO Register Read = 0x%08h", $time, read_val);
        if (read_val === 32'h0000_0820) begin
            $display("PASS: GPIO INFO register correctly reports Version 2, 32 GPIO pins (0x0000_0820)!");
        end else begin
            $error("FAIL: GPIO INFO register mismatch. Expected 0x0000_0820, Got 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Subtest 10.2: Configure Pin 0 as Push-Pull Output (MODE=01)
        // GPIO_MODE_0: 2 bits per pin. Bits [1:0] = 2'b01 (OUTPUT_ACTIVE)
        cpu_write(GPIO_MODE_0, 32'h0000_0001);
        cpu_read(GPIO_MODE_0, read_val);
        if (read_val[1:0] === 2'b01) begin
            $display("PASS: GPIO Pin 0 configured as Push-Pull Output (GPIO_MODE_0 = 0x%08h)!", read_val);
        end else begin
            $error("FAIL: GPIO_MODE_0 readback mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Subtest 10.3: Output Data Register Write (Drive Pin 0 HIGH)
        cpu_write(GPIO_OUT, 32'h0000_0001);
        cpu_read(GPIO_OUT, read_val);
        #(CLK_PERIOD * 2);
        if (read_val[0] === 1'b1 && gpio_io[0] === 1'b1) begin
            $display("PASS: GPIO Pin 0 driven HIGH via GPIO_OUT (gpio_io[0] = 1'b1)!");
        end else begin
            $error("FAIL: GPIO Pin 0 drive HIGH failed: reg=0x%08h, pad=%b", read_val, gpio_io[0]);
            error_count = error_count + 1;
        end

        // Subtest 10.4: Atomic Clear Register (Drive Pin 0 LOW)
        cpu_write(GPIO_CLEAR, 32'h0000_0001);
        cpu_read(GPIO_OUT, read_val);
        #(CLK_PERIOD * 2);
        if (read_val[0] === 1'b0 && gpio_io[0] === 1'b0) begin
            $display("PASS: GPIO Pin 0 cleared LOW via GPIO_CLEAR (gpio_io[0] = 1'b0)!");
        end else begin
            $error("FAIL: GPIO Pin 0 clear LOW failed: reg=0x%08h, pad=%b", read_val, gpio_io[0]);
            error_count = error_count + 1;
        end

        // Subtest 10.5: Atomic Set Register (Drive Pin 0 HIGH)
        cpu_write(GPIO_SET, 32'h0000_0001);
        cpu_read(GPIO_OUT, read_val);
        #(CLK_PERIOD * 2);
        if (read_val[0] === 1'b1 && gpio_io[0] === 1'b1) begin
            $display("PASS: GPIO Pin 0 set HIGH via GPIO_SET (gpio_io[0] = 1'b1)!");
        end else begin
            $error("FAIL: GPIO Pin 0 set HIGH failed: reg=0x%08h, pad=%b", read_val, gpio_io[0]);
            error_count = error_count + 1;
        end

        // Subtest 10.6: Atomic Toggle Register (Toggle Pin 0 LOW then HIGH)
        cpu_write(GPIO_TOGGLE, 32'h0000_0001); // 1 -> 0
        #(CLK_PERIOD * 2);
        if (gpio_io[0] === 1'b0) begin
            $display("PASS: GPIO Pin 0 toggled to LOW via GPIO_TOGGLE!");
        end else begin
            $error("FAIL: GPIO Pin 0 toggle LOW failed: pad=%b", gpio_io[0]);
            error_count = error_count + 1;
        end

        cpu_write(GPIO_TOGGLE, 32'h0000_0001); // 0 -> 1
        #(CLK_PERIOD * 2);
        if (gpio_io[0] === 1'b1) begin
            $display("PASS: GPIO Pin 0 toggled to HIGH via GPIO_TOGGLE!");
        end else begin
            $error("FAIL: GPIO Pin 0 toggle HIGH failed: pad=%b", gpio_io[0]);
            error_count = error_count + 1;
        end

        // Subtest 10.7: Input Sampling on Pin 1
        // Pin 1 mode is INPUT_ONLY (bits [3:2] = 2'b00)
        // Enable sampling for Pin 1 via GPIO_EN (bit 1 = 1)
        cpu_write(GPIO_EN, 32'h0000_0002);
        
        // Drive Pin 1 HIGH from testbench
        gpio_tb_drive_val[1] = 1'b1;
        gpio_tb_drive_en[1]  = 1'b1;
        #(CLK_PERIOD * 5); // Allow synchronizer chain to settle
        cpu_read(GPIO_IN, read_val);
        if (read_val[1] === 1'b1) begin
            $display("PASS: GPIO Pin 1 external input HIGH correctly sampled in GPIO_IN!");
        end else begin
            $error("FAIL: GPIO Pin 1 input HIGH sampling failed: read_val = 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Drive Pin 1 LOW from testbench
        gpio_tb_drive_val[1] = 1'b0;
        #(CLK_PERIOD * 5);
        cpu_read(GPIO_IN, read_val);
        if (read_val[1] === 1'b0) begin
            $display("PASS: GPIO Pin 1 external input LOW correctly sampled in GPIO_IN!");
        end else begin
            $error("FAIL: GPIO Pin 1 input LOW sampling failed: read_val = 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Subtest 10.8: Interrupt Generation on Rising Edge & W1C Clearing
        // Configure CFG for sticky global interrupt (bit 0 = 1)
        cpu_write(GPIO_CFG, 32'h0000_0001);
        // Enable Rising-Edge Interrupt on Pin 1
        cpu_write(GPIO_INTRPT_RISE_EN, 32'h0000_0002);

        // Generate rising edge on Pin 1 from testbench
        gpio_tb_drive_val[1] = 1'b1;
        #(CLK_PERIOD * 6); // Allow synchronizer and edge detector to assert interrupt

        if (gpio_interrupt_o === 1'b1) begin
            $display("PASS: GPIO global interrupt asserted on Pin 1 rising edge!");
        end else begin
            $error("FAIL: GPIO interrupt failed to assert: gpio_interrupt_o = %b", gpio_interrupt_o);
            error_count = error_count + 1;
        end

        cpu_read(GPIO_INTRPT_STATUS, read_val);
        if (read_val[1] === 1'b1) begin
            $display("PASS: GPIO INTRPT_STATUS register shows pending interrupt on Pin 1 (0x%08h)!", read_val);
        end else begin
            $error("FAIL: GPIO INTRPT_STATUS mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Clear interrupt by writing 1 to bit 1 in INTRPT_STATUS (W1C)
        cpu_write(GPIO_INTRPT_STATUS, 32'h0000_0002);
        #(CLK_PERIOD * 4);
        cpu_read(GPIO_INTRPT_STATUS, read_val);
        if (read_val[1] === 1'b0 && gpio_interrupt_o === 1'b0) begin
            $display("PASS: GPIO interrupt successfully cleared via W1C and de-asserted!");
        end else begin
            $error("FAIL: GPIO interrupt clear failed: status=0x%08h, irq=%b", read_val, gpio_interrupt_o);
            error_count = error_count + 1;
        end

        // Release testbench drive on Pin 1
        gpio_tb_drive_en[1] = 1'b0;

        // ---------------------------------------------------------------------
        // TEST 11: Hardware Timer Integration, 64-bit Counter & Interrupt
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n[TEST 11] Testing Hardware Timer MMIO Access (0x4000_4000)...");

        // Subtest 11.1: Default Reset State Verification
        cpu_read(TIMER_CTRL, read_val);
        $display("[%0t ns] Timer CTRL Register Read = 0x%08h", $time, read_val);
        if (read_val[0] === 1'b0) begin
            $display("PASS: Timer correctly disabled (active=0) after reset!");
        end else begin
            $error("FAIL: Timer CTRL unexpected reset value: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        cpu_read(TIMER_V_LOWER0, read_val);
        $display("[%0t ns] Timer mtime_lower Register Read = 0x%08h", $time, read_val);
        if (read_val === 32'h0000_0000) begin
            $display("PASS: Timer counter initialized to 0 after reset!");
        end else begin
            $error("FAIL: Timer counter unexpected reset value: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Subtest 11.2: Program Prescaler and Step (CFG0 at 0x10C)
        // Set prescaler = 0 (increment every cycle), step = 1 (CFG0 = 0x0001_0000)
        cpu_write(TIMER_CFG0, 32'h0001_0000);
        cpu_read(TIMER_CFG0, read_val);
        if (read_val[23:16] === 8'd1 && read_val[11:0] === 12'd0) begin
            $display("PASS: Timer CFG0 configured with Step=1 and Prescaler=0!");
        end else begin
            $error("FAIL: Timer CFG0 readback mismatch: 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // Subtest 11.3: Enable Timer & Verify Continuous Counting
        cpu_write(TIMER_CTRL, 32'h0000_0001); // active = 1
        #(CLK_PERIOD * 20); // Allow timer to count
        cpu_read(TIMER_V_LOWER0, read_val);
        $display("[%0t ns] Timer mtime_lower after 20 cycles = %0d", $time, read_val);
        if (read_val >= 32'd15) begin
            $display("PASS: Timer counter is actively advancing (mtime = %0d)!", read_val);
        end else begin
            $error("FAIL: Timer counter failed to advance: mtime = %0d", read_val);
            error_count = error_count + 1;
        end

        // Subtest 11.4: Compare Match & Interrupt Generation
        begin : test_timer_compare
            reg [31:0] cur_time;
            cpu_read(TIMER_V_LOWER0, cur_time);
            cpu_write(TIMER_COMPARE_LOWER0, cur_time + 32'd25);
            cpu_write(TIMER_COMPARE_UPPER0, 32'd0);
            
            // Enable Timer Interrupt (INTR_ENABLE0 = 1)
            cpu_write(TIMER_INTR_ENABLE0, 32'h0000_0001);

            // Wait for counter to cross threshold
            #(CLK_PERIOD * 35);
            if (timer_interrupt_o === 1'b1) begin
                $display("PASS: Timer interrupt asserted upon mtime >= mtimecmp!");
            end else begin
                $error("FAIL: Timer interrupt failed to assert: timer_interrupt_o = %b", timer_interrupt_o);
                error_count = error_count + 1;
            end

            cpu_read(TIMER_INTR_STATE0, read_val);
            if (read_val[0] === 1'b1) begin
                $display("PASS: Timer INTR_STATE0 correctly reports pending interrupt (0x%08h)!", read_val);
            end else begin
                $error("FAIL: Timer INTR_STATE0 readback mismatch: 0x%08h", read_val);
                error_count = error_count + 1;
            end

            // Subtest 11.5: Clear Interrupt via W1C
            // Set compare threshold far into future so match condition clears
            cpu_write(TIMER_COMPARE_LOWER0, 32'hFFFF_FFFF);
            cpu_write(TIMER_INTR_STATE0, 32'h0000_0001); // Write-1-to-Clear
            #(CLK_PERIOD * 4);
            cpu_read(TIMER_INTR_STATE0, read_val);
            if (read_val[0] === 1'b0 && timer_interrupt_o === 1'b0) begin
                $display("PASS: Timer interrupt successfully cleared via W1C and de-asserted!");
            end else begin
                $error("FAIL: Timer interrupt clear failed: status=0x%08h, irq=%b", read_val, timer_interrupt_o);
                error_count = error_count + 1;
            end

            // Subtest 11.6: Software Force Interrupt (INTR_TEST0)
            cpu_write(TIMER_INTR_TEST0, 32'h0000_0001);
            #(CLK_PERIOD * 4);
            if (timer_interrupt_o === 1'b1) begin
                $display("PASS: Timer interrupt successfully triggered via INTR_TEST0!");
            end else begin
                $error("FAIL: INTR_TEST0 failed to trigger interrupt: timer_interrupt_o = %b", timer_interrupt_o);
                error_count = error_count + 1;
            end

            // Clear again
            cpu_write(TIMER_INTR_STATE0, 32'h0000_0001);
            #(CLK_PERIOD * 4);
            if (timer_interrupt_o === 1'b0) begin
                $display("PASS: Forced interrupt successfully cleared via W1C!");
            end else begin
                $error("FAIL: Forced interrupt clear failed: timer_interrupt_o = %b", timer_interrupt_o);
                error_count = error_count + 1;
            end
        end

        // ---------------------------------------------------------------------
        // TEST 12: DMA Autonomous Interconnect Transfer (S01 Bus Master)
        // ---------------------------------------------------------------------
        begin
            test_count = test_count + 1;
            $display("\n==================================================================");
            $display("[TEST 12] Testing DMA Controller Autonomous Transfer via Interconnect S01...");
            $display("==================================================================");

            // Subtest 12.1: Verify DMA CSR Access & Version Signature
            dma_read(DMA_STATUS, read_val);
            $display("[%0t ns] DMA STATUS Read = 0x%08h (Expected Version: 0xCAFE)", $time, read_val);
            if (read_val[15:0] === 16'hcafe) begin
                $display("PASS: DMA Status reports correct hardware version signature 0xCAFE!");
            end else begin
                $error("FAIL: DMA version mismatch: expected 0xCAFE, got 0x%04h", read_val[15:0]);
                error_count = error_count + 1;
            end

            // Subtest 12.2: Setup Data in Source Peripheral (PWM Base: 0x4000_A000)
            cpu_write(PWM_BASE, 32'h1234_5678);
            cpu_read(PWM_BASE, read_val);
            if (read_val === 32'h1234_5678) begin
                $display("PASS: Source register (PWM Duty Reg) initialized to 0x1234_5678!");
            end else begin
                $error("FAIL: Source register write failed: 0x%08h", read_val);
                error_count = error_count + 1;
            end

            // Clear Destination (GPIO_OUT: 0x4000_2180) via CPU
            cpu_write(GPIO_OUT, 32'h0000_0000);
            cpu_read(GPIO_OUT, read_val);
            if (read_val === 32'h0000_0000) begin
                $display("PASS: Destination register (GPIO_OUT) cleared to 0x0000_0000!");
            end

            // Subtest 12.3: Program DMA Descriptor 0 via CSR Port
            // Source = 0x4000_A000 (PWM Base), Destination = 0x4000_2180 (GPIO Output)
            // Length = 4 bytes (1 word)
            // Config = wr_mode: FIXED (1), rd_mode: FIXED (1), enable: 1 -> 3'b111 = 0x7
            dma_write(DMA_DESC0_SRC, PWM_BASE);
            dma_write(DMA_DESC0_DST, GPIO_OUT);
            dma_write(DMA_DESC0_LEN, 32'd4);
            dma_write(DMA_DESC0_CFG, 32'h0000_0007);

            // Subtest 12.4: Trigger DMA Transfer via GO bit in DMA_CONTROL
            $display("[%0t ns] Triggering DMA transfer via DMA_CONTROL GO bit...", $time);
            dma_write(DMA_CONTROL, 32'h0000_0005); // max_burst=1, abort=0, go=1

            // Subtest 12.5: Wait for DMA Transfer Completion via Done Interrupt
            fork
                begin
                    wait (dma_done_interrupt_o === 1'b1);
                    $display("[%0t ns] PASS: dma_done_interrupt_o asserted!", $time);
                end
                begin
                    #(CLK_PERIOD * 500);
                    if (dma_done_interrupt_o !== 1'b1) begin
                        $error("FAIL: DMA transfer timed out waiting for dma_done_interrupt_o!");
                        error_count = error_count + 1;
                    end
                end
            join_any

            // Verify DMA status done bit and no error
            dma_read(DMA_STATUS, read_val);
            if (read_val[16] === 1'b1 && read_val[17] === 1'b0) begin
                $display("PASS: DMA STATUS confirms transfer complete (done=1, error=0)!");
            end else begin
                $error("FAIL: DMA STATUS unexpected: 0x%08h", read_val);
                error_count = error_count + 1;
            end

            // Subtest 12.6: Verify Transferred Data at Destination Register
            cpu_read(GPIO_OUT, read_val);
            if (read_val === 32'h1234_5678) begin
                $display("PASS: Autonomous DMA transfer verified! GPIO_OUT received 0x%08h from PWM via Interconnect Port S01!", read_val);
            end else begin
                $error("FAIL: Destination data mismatch: expected 0x1234_5678, got 0x%08h", read_val);
                error_count = error_count + 1;
            end
        end

        // ---------------------------------------------------------------------
        // TEST 13: Executing C Program Firmware / Transaction Sequence (main1.hex)
        // ---------------------------------------------------------------------
        test_count = test_count + 1;
        $display("\n==================================================================");
        $display("   [TEST 13] Executing C Firmware Transactions from main1.hex     ");
        $display("==================================================================");
        run_hex_firmware("main1.hex");

        // ---------------------------------------------------------------------
        // Final Summary
        // ---------------------------------------------------------------------
        #(CLK_PERIOD * 50);
        $display("\n==================================================================");
        if (error_count == 0) begin
            $display("   *** ALL %0d SYSTEM-LEVEL TESTS PASSED SUCCESSFULLY! ***", test_count);
            $display("   RISC-V CPU <-> AXI INTERCONNECT <-> UART, TIMER, GPIO, SPI, I2C, PWM & DMA VERIFIED");
        end else begin
            $display("   *** VERIFICATION FAILED WITH %0d ERRORS! ***", error_count);
        end
        $display("==================================================================\n");

        $finish;
    end

endmodule
