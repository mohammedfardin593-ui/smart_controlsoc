/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : tb_uart_transmitter.v
 * Description    : Testbench for uart_transmitter module
 * -----------------------------------------------------------------------------
 * Simulation settings:
 *   CLK  = 100 MHz (10 ns period)
 *   BAUD_DIV = 20  (fast baud for short simulation)
 *   Bit period = 20 * 10 ns = 200 ns
 *
 * Test cases:
 *   TC1 : Async reset - tx_o=1 (idle), busy=1 initially -> reset -> busy=0
 *   TC2 : Transmit 0x55 (no parity, 1 stop bit) - verify serial stream
 *   TC3 : Transmit 0xA5 with even parity, 1 stop bit
 *   TC4 : Transmit 0xFF with odd parity, 1 stop bit
 *   TC5 : Transmit 0x42 with no parity, 2 stop bits
 *   TC6 : tx_ready_o asserts after transmission completes
 *   TC7 : busy_o asserted during transmission, deasserted when done
 *   TC8 : UART disabled (en_i=0) - tx_send_i ignored
 *   TC9 : Back-to-back transmissions
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_uart_transmitter;

  // -------------------------------------------------------------------------
  // Timing parameters
  // -------------------------------------------------------------------------
  localparam CLK_PERIOD = 10;           // 10 ns
  localparam DIV_SIZE   = 16;
  localparam DATA_UART  = 8;
  localparam BAUD_DIV   = 20;           // baud divisor (fast for sim)
  localparam BIT_TICKS  = BAUD_DIV;     // clock cycles per bit

  // -------------------------------------------------------------------------
  // DUT ports
  // -------------------------------------------------------------------------
  reg                   clk_i;
  reg                   rstn_i;
  reg                   en_i;
  reg                   stop_bits_i;       // 0=1 stop, 1=2 stop
  reg                   parity_bit_i;      // 0=no parity, 1=parity
  reg                   parity_bit_mode_i; // 0=odd, 1=even
  reg  [DIV_SIZE-1:0]   baud_div_i;
  wire                  tx_o;
  reg  [DATA_UART-1:0]  tx_data_i;
  reg                   tx_send_i;
  wire                  tx_ready_o;
  wire                  busy_o;

  // -------------------------------------------------------------------------
  // Instantiate DUT
  // -------------------------------------------------------------------------
  uart_transmitter #(
    .DIV_SIZE  (DIV_SIZE),
    .DATA_UART (DATA_UART)
  ) dut (
    .clk_i             (clk_i),
    .rstn_i            (rstn_i),
    .en_i              (en_i),
    .stop_bits_i       (stop_bits_i),
    .parity_bit_i      (parity_bit_i),
    .parity_bit_mode_i (parity_bit_mode_i),
    .baud_div_i        (baud_div_i),
    .tx_o              (tx_o),
    .tx_data_i         (tx_data_i),
    .tx_send_i         (tx_send_i),
    .tx_ready_o        (tx_ready_o),
    .busy_o            (busy_o)
  );

  // -------------------------------------------------------------------------
  // Clock
  // -------------------------------------------------------------------------
  initial clk_i = 1'b0;
  always #(CLK_PERIOD/2) clk_i = ~clk_i;

  // -------------------------------------------------------------------------
  // Shift register to capture received bits from tx_o
  // -------------------------------------------------------------------------
  reg  [DATA_UART-1:0] rx_shift;
  reg  [3:0]           rx_bitcount;
  reg                  capturing;
  reg                  rx_parity_captured;

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
    begin
      if (actual === expected) begin
        $display("PASS  TC%0d : tx_data = 0x%02h (expected 0x%02h)", tc_num, actual, expected);
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL  TC%0d : tx_data = 0x%02h (expected 0x%02h)", tc_num, actual, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: send one byte via DUT and capture the serial output
  //   Returns captured data byte and parity bit
  // -------------------------------------------------------------------------
  reg  [DATA_UART-1:0] captured_data;
  reg                  captured_parity;
  reg                  captured_start;
  reg  [1:0]           captured_stop_count;

  task transmit_and_capture;
    input [DATA_UART-1:0] data;
    input                 par_en;
    input                 par_mode;  // 0=odd, 1=even
    input                 stop2;     // 0=1 stop, 1=2 stops
    integer               b;
    integer               half;
    begin
      // Setup
      parity_bit_i      = par_en;
      parity_bit_mode_i = par_mode;
      stop_bits_i       = stop2;

      // Assert tx_send_i for one clock
      @(negedge clk_i);
      tx_data_i = data;
      tx_send_i = 1'b1;
      @(posedge clk_i); #1;
      tx_send_i = 1'b0;

      // Wait for start bit (tx_o should go low)
      // The transmitter drives start bit when tx_send seen and en_i=1
      // Sample in the middle of each bit (half baud period in)
      half = BIT_TICKS / 2;

      // Wait for start bit low
      @(negedge tx_o);

      // Sample start bit in middle
      #(CLK_PERIOD * half);
      captured_start = tx_o;

      // Sample 8 data bits
      for (b = 0; b < DATA_UART; b = b + 1) begin
        #(CLK_PERIOD * BIT_TICKS);
        captured_data[b] = tx_o;
      end

      // Capture parity bit if enabled
      if (par_en) begin
        #(CLK_PERIOD * BIT_TICKS);
        captured_parity = tx_o;
      end

      // Count stop bits
      captured_stop_count = 0;
      #(CLK_PERIOD * BIT_TICKS);
      if (tx_o === 1'b1) captured_stop_count = captured_stop_count + 1;
      if (stop2) begin
        #(CLK_PERIOD * BIT_TICKS);
        if (tx_o === 1'b1) captured_stop_count = captured_stop_count + 1;
      end

      // Wait until tx_ready_o
      @(posedge tx_ready_o);
      @(posedge clk_i); #1;
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: wait for transmission to complete
  // -------------------------------------------------------------------------
  task wait_ready;
    input [31:0] timeout_cycles;
    integer cnt;
    begin
      cnt = 0;
      while (tx_ready_o !== 1'b1 && cnt < timeout_cycles) begin
        @(posedge clk_i); #1;
        cnt = cnt + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Parity functions
  // -------------------------------------------------------------------------
  function parity_odd;
    input [DATA_UART-1:0] d;
    begin
      parity_odd = ~(^d);
    end
  endfunction

  function parity_even;
    input [DATA_UART-1:0] d;
    begin
      parity_even = ^d;
    end
  endfunction

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin
    pass_count        = 0;
    fail_count        = 0;
    rstn_i            = 1'b0;
    en_i              = 1'b1;
    stop_bits_i       = 1'b0;
    parity_bit_i      = 1'b0;
    parity_bit_mode_i = 1'b0;
    baud_div_i        = BAUD_DIV;
    tx_data_i         = 8'h00;
    tx_send_i         = 1'b0;

    // Release reset
    #(CLK_PERIOD * 4);
    rstn_i = 1'b1;
    #(CLK_PERIOD * 5);

    // =======================================================================
    // TC1: After reset - tx_o=1 (idle high), busy_o=0
    // =======================================================================
    $display("--- TC1: After reset ---");
    check_bit(tx_o,     1'b1, 64'd1, "tx_idle");
    check_bit(busy_o,   1'b0, 64'd1, "not_busy");
    check_bit(tx_ready_o, 1'b0, 64'd1, "not_ready");

    // =======================================================================
    // TC2: Transmit 0x55, no parity, 1 stop bit
    // =======================================================================
    $display("--- TC2: Transmit 0x55, no parity, 1 stop bit ---");
    transmit_and_capture(8'h55, 0, 0, 0);
    check_byte(captured_data, 8'h55, 64'd2);
    check_bit(captured_start, 1'b0, 64'd2, "start_bit");
    check_bit(captured_stop_count[0], 1'b1, 64'd2, "stop_bit");

    // =======================================================================
    // TC3: Transmit 0xA5 with even parity, 1 stop bit
    // =======================================================================
    $display("--- TC3: Transmit 0xA5, even parity ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    transmit_and_capture(8'hA5, 1, 1, 0);
    check_byte(captured_data, 8'hA5, 64'd3);
    check_bit(captured_parity, parity_even(8'hA5), 64'd3, "even_parity");

    // =======================================================================
    // TC4: Transmit 0xFF with odd parity, 1 stop bit
    // =======================================================================
    $display("--- TC4: Transmit 0xFF, odd parity ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    transmit_and_capture(8'hFF, 1, 0, 0);
    check_byte(captured_data, 8'hFF, 64'd4);
    check_bit(captured_parity, parity_odd(8'hFF), 64'd4, "odd_parity");

    // =======================================================================
    // TC5: Transmit 0x42, no parity, 2 stop bits
    // =======================================================================
    $display("--- TC5: Transmit 0x42, 2 stop bits ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    transmit_and_capture(8'h42, 0, 0, 1);
    check_byte(captured_data, 8'h42, 64'd5);
    // Both stop bits should be 1
    check_bit(captured_stop_count[0], 1'b1, 64'd5, "stop1");
    check_bit(captured_stop_count[1], 1'b1, 64'd5, "stop2");

    // =======================================================================
    // TC6: tx_ready_o asserts after transmission
    // =======================================================================
    $display("--- TC6: tx_ready_o asserted after TX ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    @(negedge clk_i);
    tx_data_i = 8'hCC;
    tx_send_i = 1'b1;
    parity_bit_i = 1'b0;
    stop_bits_i  = 1'b0;
    @(posedge clk_i); #1;
    tx_send_i = 1'b0;
    wait_ready(BIT_TICKS * 20);
    check_bit(tx_ready_o, 1'b1, 64'd6, "tx_ready");
    @(posedge clk_i); #1;

    // =======================================================================
    // TC7: busy_o asserted during TX, deasserted when done
    // =======================================================================
    $display("--- TC7: busy_o during and after TX ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    @(negedge clk_i);
    tx_data_i = 8'hBB;
    tx_send_i = 1'b1;
    @(posedge clk_i); #1;
    tx_send_i = 1'b0;
    // After trigger, busy should assert
    #(CLK_PERIOD * 5);
    check_bit(busy_o, 1'b1, 64'd7, "busy_during_tx");
    wait_ready(BIT_TICKS * 20);
    @(posedge clk_i); #1;
    check_bit(busy_o, 1'b0, 64'd7, "busy_after_tx");

    // =======================================================================
    // TC8: UART disabled - tx_send_i ignored
    // =======================================================================
    $display("--- TC8: UART disabled ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    en_i = 1'b0;
    @(negedge clk_i);
    tx_data_i = 8'h99;
    tx_send_i = 1'b1;
    @(posedge clk_i); #1;
    tx_send_i = 1'b0;
    #(CLK_PERIOD * BIT_TICKS * 5);
    // tx_o must stay idle high when disabled
    check_bit(tx_o, 1'b1, 64'd8, "tx_idle_disabled");
    check_bit(busy_o, 1'b0, 64'd8, "not_busy_disabled");
    en_i = 1'b1;

    // =======================================================================
    // TC9: Back-to-back transmissions
    // =======================================================================
    $display("--- TC9: Back-to-back transmissions ---");
    #(CLK_PERIOD * BIT_TICKS * 2);
    transmit_and_capture(8'h11, 0, 0, 0);
    check_byte(captured_data, 8'h11, 64'd9);
    transmit_and_capture(8'h22, 0, 0, 0);
    check_byte(captured_data, 8'h22, 64'd9);

    // =======================================================================
    // Summary
    // =======================================================================
    #(CLK_PERIOD * BIT_TICKS * 3);
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
    #20_000_000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
