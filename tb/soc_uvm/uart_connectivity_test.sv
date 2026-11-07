// =============================================================================
// UART Connectivity Test: uart_connectivity_test
// Performs Phase 2 End-to-End UART functional verification on Smart Control SoC
// Transmits 8'hA5 from UART VIP Driver -> SoC UART RX -> DUT RX FIFO -> CPU Read
// =============================================================================

`ifndef UART_CONNECTIVITY_TEST_SV
`define UART_CONNECTIVITY_TEST_SV

class uart_connectivity_test extends soc_test;
    `uvm_component_utils(uart_connectivity_test)

    function new(string name = "uart_connectivity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Building uart_connectivity_test...", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        uart_connectivity_sequence uart_seq;
        bit [31:0] rdata;
        bit [7:0]  dut_rx_byte;
        bit        timeout = 0;

        localparam [31:0] UART_BASE     = 32'h4000_0000;
        localparam [31:0] UART_RBR      = UART_BASE + 32'h00;
        localparam [31:0] UART_THR      = UART_BASE + 32'h00;
        localparam [31:0] UART_IER      = UART_BASE + 32'h04;
        localparam [31:0] UART_BAUD_DIV = UART_BASE + 32'h08;
        localparam [31:0] UART_LCR      = UART_BASE + 32'h0C;
        localparam [31:0] UART_LSR      = UART_BASE + 32'h14;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 2: UART END-TO-END FUNCTIONAL VERIFICATION START        ", UVM_LOW)
        `uvm_info(get_type_name(), "   DUT: smart_controlsoc_top (instance: soc_dut)                 ", UVM_LOW)
        `uvm_info(get_type_name(), "   Target Byte   : 0xA5 (10100101b, LSB first)                    ", UVM_LOW)
        `uvm_info(get_type_name(), "   Configuration : 115200 Baud, 8 Data Bits, No Parity, 1 Stop    ", UVM_LOW)
        `uvm_info(get_type_name(), "   Bit Duration  : 868 clock cycles (8680 ns @ 100MHz)            ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 1: Wait for Reset De-assertion and Line Stabilization
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 1] Waiting for system reset deassertion...", UVM_LOW)
        wait (cfg.uart_vif.rst_n === 1'b1);
        #200ns;

        // Verify initial line states
        if (cfg.uart_vif.uart_rx_i !== 1'b1) begin
            `uvm_error(get_type_name(), $sformatf("Default uart_rx_i should be idle HIGH (1), observed: %b", cfg.uart_vif.uart_rx_i))
        end else begin
            `uvm_info(get_type_name(), "PASS: uart_rx_i is correctly idling HIGH (1).", UVM_LOW)
        end

        if (cfg.uart_vif.uart_interrupt_o !== 1'b0) begin
            `uvm_error(get_type_name(), $sformatf("Default uart_interrupt_o should be idle LOW (0), observed: %b", cfg.uart_vif.uart_interrupt_o))
        end else begin
            `uvm_info(get_type_name(), "PASS: uart_interrupt_o is correctly idling LOW (0).", UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // Step 2: Configure UART Peripheral Registers via CPU LSU AXI Master Port
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 2] Programming UART Control Registers via CPU AXI Master (Port S00)...", UVM_LOW)
        
        // 1. Enable DLAB (LCR[7] = 1) to access Baud Divisor
        cfg.cpu_vif.cpu_write(UART_LCR, 32'h0000_0080);
        `uvm_info(get_type_name(), "  [CPU -> AXI] Wrote UART_LCR = 0x0000_0080 (DLAB Enable)", UVM_LOW)

        // 2. Program Baud Divisor = 868 (115200 baud @ 100MHz)
        cfg.cpu_vif.cpu_write(UART_BAUD_DIV, 32'd868);
        `uvm_info(get_type_name(), "  [CPU -> AXI] Wrote UART_BAUD_DIV = 868 (115200 Baud)", UVM_LOW)

        // 3. Clear DLAB & Configure 8-N-1 (LCR = 0x00: 8 data bits, 1 stop bit, no parity)
        cfg.cpu_vif.cpu_write(UART_LCR, 32'h0000_0000);
        `uvm_info(get_type_name(), "  [CPU -> AXI] Wrote UART_LCR = 0x0000_0000 (8-N-1, DLAB Clear)", UVM_LOW)

        // 4. Enable Receiver Interrupt (IER[0] = 1)
        cfg.cpu_vif.cpu_write(UART_IER, 32'h0000_0001);
        `uvm_info(get_type_name(), "  [CPU -> AXI] Wrote UART_IER = 0x0000_0001 (RX Data Ready Interrupt Enable)", UVM_LOW)

        // Read back IER and LCR to verify register configuration
        cfg.cpu_vif.cpu_read(UART_IER, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback UART_IER = 0x%08h (Expected: 0x00000001)", rdata), UVM_LOW)
        if (rdata[0] !== 1'b1) begin
            `uvm_error(get_type_name(), "UART_IER bit 0 not set!")
        end

        // ---------------------------------------------------------------------
        // Step 3: Launch UART VIP Sequence (Transmit 8'hA5 via Driver into RX pin)
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 3] Launching UART VIP Sequence to inject 8'hA5 into soc_dut.uart_rx_i...", UVM_LOW)
        uart_seq = uart_connectivity_sequence::type_id::create("uart_seq");
        uart_seq.tx_data   = 8'hA5;
        uart_seq.baud_rate = 115200;

        // Start sequence on UART VIP sequencer
        uart_seq.start(env.uart_agent.seqr);
        `uvm_info(get_type_name(), "  UART VIP Driver completed serial frame transmission for 8'hA5.", UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 4: Verify Peripheral-Level Reception inside DUT UART IP
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 4] Waiting for DUT UART IP reception and uart_interrupt_o assertion...", UVM_LOW)
        
        // Wait for uart_interrupt_o to assert or timeout after 50 us
        fork
            begin
                wait (cfg.uart_vif.uart_interrupt_o === 1'b1);
            end
            begin
                #50us;
                timeout = 1;
            end
        join_any

        if (timeout) begin
            `uvm_error(get_type_name(), "TIMEOUT: uart_interrupt_o failed to assert within 50 us after frame completion!")
        end else begin
            `uvm_info(get_type_name(), $sformatf("PASS: uart_interrupt_o asserted HIGH at %0t ns!", $time), UVM_LOW)
        end

        // Sample internal DUT RX FIFO output byte
        dut_rx_byte = cfg.cpu_vif.get_dut_uart_rx_fifo_data();
        `uvm_info(get_type_name(), $sformatf("  [DUT RX FIFO] Captured internal byte = 0x%02h", dut_rx_byte), UVM_LOW)
        env.uart_sb.record_dut_rx(dut_rx_byte);

        // ---------------------------------------------------------------------
        // Step 5: CPU-Level Readback across AXI Interconnect (Port M00)
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 5] CPU Reading UART Line Status (LSR) and Receiver Buffer (RBR)...", UVM_LOW)

        // Read UART_LSR to verify DATA_READY bit is set
        cfg.cpu_vif.cpu_read(UART_LSR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read UART_LSR = 0x%08h (DATA_READY = %b)", rdata, rdata[0]), UVM_LOW)
        if (rdata[0] !== 1'b1) begin
            `uvm_error(get_type_name(), "UART_LSR DATA_READY bit is not asserted!")
        end else begin
            `uvm_info(get_type_name(), "PASS: UART_LSR DATA_READY bit correctly set.", UVM_LOW)
        end

        // CPU reads received byte from Receiver Buffer Register (RBR)
        cfg.cpu_vif.cpu_read(UART_RBR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read UART_RBR = 0x%08h (Received byte: 0x%02h)", rdata, rdata[7:0]), UVM_LOW)
        env.uart_sb.record_cpu_read(rdata[7:0]);

        // ---------------------------------------------------------------------
        // Step 6: Verify Interrupt De-assertion upon Reading RBR
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 6] Verifying uart_interrupt_o deassertion after RBR read...", UVM_LOW)
        #500ns;
        if (cfg.uart_vif.uart_interrupt_o !== 1'b0) begin
            `uvm_error(get_type_name(), $sformatf("FAIL: uart_interrupt_o should DEASSERT (0) after RBR read, observed: %b", cfg.uart_vif.uart_interrupt_o))
        end else begin
            `uvm_info(get_type_name(), "PASS: uart_interrupt_o correctly deasserted LOW after RBR read.", UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // Step 7: Completion & Settlement
        // ---------------------------------------------------------------------
        #500ns;
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 2: UART END-TO-END FUNCTIONAL VERIFICATION COMPLETED     ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : uart_connectivity_test

`endif // UART_CONNECTIVITY_TEST_SV
