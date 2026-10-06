/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : tb_uart_controller.v
 * Description    : Testbench for uart_controller module
 * -----------------------------------------------------------------------------
 * The uart_controller instantiates uart_transmitter and uart_receiver
 * internally. This testbench exercises the controller FSM by:
 *   - Feeding tx_data via tx_load_i/tx_data_i and verifying the serial
 *     output on uart_tx_o.
 *   - Injecting a UART frame on uart_rx_i and verifying rx_data_o/rx_push_o.
 *   - Loopback test: connect tx output back to rx input.
 *
 * Simulation settings:
 *   CLK      = 100 MHz
 *   BAUD_DIV = 40  (fast baud divisor for short simulation)
 *
 * Test cases:
 *   TC1 : Async reset - tx_pull_o=0, uart_tx_o=1 (idle)
 *   TC2 : Transmit single byte via controller FSM
 *   TC3 : tx_pull_o asserts for one cycle when data loaded from FIFO
 *   TC4 : Receive single byte - rx_push_o asserts and rx_data_o is correct
 *   TC5 : Loopback - TX output wired to RX input
 *   TC6 : tx_load_i deasserted while busy - controller waits correctly
 *   TC7 : Multiple consecutive transmissions
 *   TC8 : Receive back-to-back bytes
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_uart_controller;

  // -------------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------------
  localparam CLK_PERIOD = 10;          // 10 ns  -> 100 MHz
  localparam DATA_UART  = 8;
  localparam DATA_SIZE  = 32;
  localparam DIV_SIZE   = 16;
  localparam BAUD_DIV   = 40;
  localparam BIT_TICKS  = BAUD_DIV;

  // -------------------------------------------------------------------------
  // DUT ports
  // -------------------------------------------------------------------------
  reg                    clk_i;
  reg                    rstn_i;
  reg                    uart_en_i;
  reg                    uart_stop_bits_i;
  reg                    uart_parity_bit_i;
  reg                    uart_parity_bit_mode_i;
  reg  [DIV_SIZE-1:0]    uart_baudrate_div_i;
  reg                    uart_rx_i;
  wire                   uart_tx_o;
  wire [DATA_UART-1:0]   rx_data_o;
  wire                   rx_push_o;
  reg                    tx_load_i;
  reg  [DATA_UART-1:0]   tx_data_i;
  wire                   tx_pull_o;

  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------
  uart_controller #(
    .DATA_UART (DATA_UART),
    .DATA_SIZE (DATA_SIZE),
    .DIV_SIZE  (DIV_SIZE)
  ) dut (
    .clk_i                  (clk_i),
    .rstn_i                 (rstn_i),
    .uart_en_i              (uart_en_i),
    .uart_stop_bits_i       (uart_stop_bits_i),
    .uart_parity_bit_i      (uart_parity_bit_i),
    .uart_parity_bit_mode_i (uart_parity_bit_mode_i),
    .uart_baudrate_div_i    (uart_baudrate_div_i),
    .uart_rx_i              (uart_rx_i),
    .uart_tx_o              (uart_tx_o),
    .rx_data_o              (rx_data_o),
    .rx_push_o              (rx_push_o),
    .tx_load_i              (tx_load_i),
    .tx_data_i              (tx_data_i),
    .tx_pull_o              (tx_pull_o)
  );

  // -------------------------------------------------------------------------
  // Clock
  // -------------------------------------------------------------------------
  initial clk_i = 1'b0;
  always #(CLK_PERIOD/2) clk_i = ~clk_i;

  // -------------------------------------------------------------------------
  // Test tracking
  // -------------------------------------------------------------------------
  integer pass_count;
  integer fail_count;

  task check_bit;
    input        actual;
    input        expected;
    input [63:0] tc_num;
    input [127:0] label;
    begin
      if (actual === expected) begin
        $display("PASS  TC%0d [%s] : %b (expected %b)", tc_num, label, actual, expected);
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL  TC%0d [%s] : %b (expected %b)", tc_num, label, actual, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  task check_byte;
    input [DATA_UART-1:0] actual;
    input [DATA_UART-1:0] expected;
    input [63:0]          tc_num;
    input [127:0]         label;
    begin
      if (actual === expected) begin
        $display("PASS  TC%0d [%s] : 0x%02h (expected 0x%02h)", tc_num, label, actual, expected);
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL  TC%0d [%s] : 0x%02h (expected 0x%02h)", tc_num, label, actual, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: inject a UART byte on uart_rx_i
  // -------------------------------------------------------------------------
  task rx_inject_byte;
    input [DATA_UART-1:0] data;
    input                 parity_en;
    input                 parity_val;
    input integer         stop_cnt;
    integer b;
    begin
      // Start bit
      uart_rx_i = 1'b0;
      #(CLK_PERIOD * BIT_TICKS);
      // Data bits
      for (b = 0; b < DATA_UART; b = b + 1) begin
        uart_rx_i = data[b];
        #(CLK_PERIOD * BIT_TICKS);
      end
      // Parity
      if (parity_en) begin
        uart_rx_i = parity_val;
        #(CLK_PERIOD * BIT_TICKS);
      end
      // Stop bits
      repeat (stop_cnt) begin
        uart_rx_i = 1'b1;
        #(CLK_PERIOD * BIT_TICKS);
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: trigger controller to transmit (simulates FIFO presenting data)
  //   The controller FSM requires tx_load_i asserted and busy=0
  // -------------------------------------------------------------------------
  task ctrl_tx_send;
    input [DATA_UART-1:0] data;
    begin
      @(negedge clk_i);
      tx_data_i  = data;
      tx_load_i  = 1'b1;
      @(posedge clk_i); #1;
      tx_load_i  = 1'b0;
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: capture serial bits from uart_tx_o (used for loopback validation)
  // -------------------------------------------------------------------------
  reg  [DATA_UART-1:0] tx_captured;

  task capture_tx_byte;
    integer b;
    integer half;
    begin
      half = BIT_TICKS / 2;
      // Wait for start bit
      @(negedge uart_tx_o);
      // Skip to middle of start bit
      #(CLK_PERIOD * half);
      // Skip start bit duration
      #(CLK_PERIOD * BIT_TICKS);
      // Sample 8 data bits
      for (b = 0; b < DATA_UART; b = b + 1) begin
        tx_captured[b] = uart_tx_o;
        #(CLK_PERIOD * BIT_TICKS);
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Wait for rx_push_o with timeout
  // -------------------------------------------------------------------------
  task wait_rx_push;
    input [31:0] timeout_cycles;
    integer cnt;
    begin
      cnt = 0;
      while (rx_push_o !== 1'b1 && cnt < timeout_cycles) begin
        @(posedge clk_i); #1;
        cnt = cnt + 1;
      end
      if (cnt >= timeout_cycles)
        $display("WARN : wait_rx_push timed out");
    end
  endtask

  // -------------------------------------------------------------------------
  // Wait for tx_pull_o with timeout
  // -------------------------------------------------------------------------
  task wait_tx_pull;
    input [31:0] timeout_cycles;
    integer cnt;
    begin
      cnt = 0;
      while (tx_pull_o !== 1'b1 && cnt < timeout_cycles) begin
        @(posedge clk_i); #1;
        cnt = cnt + 1;
      end
      if (cnt >= timeout_cycles)
        $display("WARN : wait_tx_pull timed out");
    end
  endtask

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin
    pass_count             = 0;
    fail_count             = 0;
    rstn_i                 = 1'b0;
    uart_en_i              = 1'b1;
    uart_stop_bits_i       = 1'b0;
    uart_parity_bit_i      = 1'b0;
    uart_parity_bit_mode_i = 1'b0;
    uart_baudrate_div_i    = BAUD_DIV;
    uart_rx_i              = 1'b1;   // idle high
    tx_load_i              = 1'b0;
    tx_data_i              = 8'h00;

    // Release reset
    #(CLK_PERIOD * 5);
    rstn_i = 1'b1;
    #(CLK_PERIOD * 5);

    // =======================================================================
    // TC1: After reset - tx idle, tx_pull deasserted
    // =======================================================================
    $display("--- TC1: After reset ---");
    check_bit(uart_tx_o, 1'b1, 64'd1, "tx_idle");
    check_bit(tx_pull_o, 1'b0, 64'd1, "tx_pull");
    check_bit(rx_push_o, 1'b0, 64'd1, "rx_push");

    // =======================================================================
    // TC2: Transmit 0x5A via controller FSM
    // =======================================================================
    $display("--- TC2: Transmit 0x5A via controller ---");
    uart_stop_bits_i  = 1'b0;
    uart_parity_bit_i = 1'b0;
    ctrl_tx_send(8'h5A);
    // Wait for TX to complete (wait for uart_tx_o to return idle after stop bit)
    #(CLK_PERIOD * BIT_TICKS * (DATA_UART + 3));   // enough time for full frame
    check_bit(uart_tx_o, 1'b1, 64'd2, "tx_back_idle");

    // =======================================================================
    // TC3: tx_pull_o asserts for one cycle
    // =======================================================================
    $display("--- TC3: tx_pull_o one-cycle pulse ---");
    #(CLK_PERIOD * BIT_TICKS * 3);
    ctrl_tx_send(8'hAA);
    wait_tx_pull(BIT_TICKS * 5);
    check_bit(tx_pull_o, 1'b1, 64'd3, "tx_pull_asserted");
    @(posedge clk_i); #1;
    check_bit(tx_pull_o, 1'b0, 64'd3, "tx_pull_deasserted");
    // wait for frame to finish
    #(CLK_PERIOD * BIT_TICKS * (DATA_UART + 3));

    // =======================================================================
    // TC4: Receive single byte
    // =======================================================================
    $display("--- TC4: Receive 0x37 ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    uart_parity_bit_i = 1'b0;
    uart_stop_bits_i  = 1'b0;
    rx_inject_byte(8'h37, 0, 0, 1);
    wait_rx_push(BIT_TICKS * 15);
    check_bit(rx_push_o, 1'b1, 64'd4, "rx_push");
    check_byte(rx_data_o, 8'h37, 64'd4, "rx_data");
    @(posedge clk_i); #1;

    // =======================================================================
    // TC5: Loopback - TX output fed to RX input
    // =======================================================================
    $display("--- TC5: Loopback test ---");
    #(CLK_PERIOD * BIT_TICKS * 3);
    // Connect TX to RX
    // (we use a continuous assign override via a wire)
    // For this TB: after tx triggers we monitor uart_tx_o and
    // simultaneously feed it back into uart_rx_i
    fork
      begin
        ctrl_tx_send(8'hC3);
      end
      begin
        // Feed back tx to rx (loopback): capture as it comes out
        // Wait for TX start bit, then forward every bit to rx_i
        @(negedge uart_tx_o);  // start bit
        forever begin
          @(clk_i);
          uart_rx_i = uart_tx_o;
        end
      end
    join_none
    wait_rx_push(BIT_TICKS * 20);
    check_bit(rx_push_o, 1'b1, 64'd5, "rx_push_loopback");
    check_byte(rx_data_o, 8'hC3, 64'd5, "rx_data_loopback");
    // Stop loopback
    disable fork;
    uart_rx_i = 1'b1;
    #(CLK_PERIOD * BIT_TICKS * (DATA_UART + 5));

    // =======================================================================
    // TC6: tx_load_i deasserted quickly - controller still transmits
    // =======================================================================
    $display("--- TC6: tx_load presented for one cycle ---");
    #(CLK_PERIOD * BIT_TICKS * 3);
    @(negedge clk_i);
    tx_data_i = 8'hBE;
    tx_load_i = 1'b1;
    @(posedge clk_i); #1;
    tx_load_i = 1'b0;
    // Verify transmission still occurs
    @(negedge uart_tx_o);   // start bit detected
    check_bit(uart_tx_o, 1'b0, 64'd6, "start_bit");
    #(CLK_PERIOD * BIT_TICKS * (DATA_UART + 3));
    check_bit(uart_tx_o, 1'b1, 64'd6, "tx_back_idle");

    // =======================================================================
    // TC7: Multiple consecutive transmissions
    // =======================================================================
    $display("--- TC7: Multiple consecutive transmissions ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    fork
      begin
        capture_tx_byte;
        check_byte(tx_captured, 8'h11, 64'd7, "tx_byte1");
        capture_tx_byte;
        check_byte(tx_captured, 8'h22, 64'd7, "tx_byte2");
      end
      begin
        ctrl_tx_send(8'h11);
        // Wait until not busy before next
        #(CLK_PERIOD * BIT_TICKS * (DATA_UART + 4));
        ctrl_tx_send(8'h22);
      end
    join

    // =======================================================================
    // TC8: Receive back-to-back bytes
    // =======================================================================
    $display("--- TC8: Receive back-to-back bytes ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    rx_inject_byte(8'hAB, 0, 0, 1);
    wait_rx_push(BIT_TICKS * 15);
    check_byte(rx_data_o, 8'hAB, 64'd8, "rx_byte1");
    rx_inject_byte(8'hCD, 0, 0, 1);
    wait_rx_push(BIT_TICKS * 15);
    check_byte(rx_data_o, 8'hCD, 64'd8, "rx_byte2");

    // =======================================================================
    // Summary
    // =======================================================================
    #(CLK_PERIOD * BIT_TICKS * 5);
    $display("-------------------------------");
    $display("Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
    $display("-------------------------------");
    if (fail_count == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");
    $finish;
  end

  initial begin
    #50_000_000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
