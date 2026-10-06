/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : tb_uart_parity_bit_compute.v
 * Description    : Testbench for uart_parity_bit_compute module
 * -----------------------------------------------------------------------------
 * Test cases:
 *   TC1 : Asynchronous reset check
 *   TC2 : Odd parity - single '1' bit  -> parity_bit_o = 1
 *   TC3 : Odd parity - two '1' bits    -> parity_bit_o = 0
 *   TC4 : Even parity - single '1' bit -> parity_bit_o = 1
 *   TC5 : Even parity - two '1' bits   -> parity_bit_o = 0
 *   TC6 : valid=0 does not advance counter (ignored bits)
 *   TC7 : Synchronous soft reset clears counter
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_uart_parity_bit_compute;

  // -------------------------------------------------------------------------
  // DUT Ports
  // -------------------------------------------------------------------------
  reg  clk_i;
  reg  arstn_i;
  reg  rst_i;
  reg  data_i;
  reg  valid_i;
  reg  mode_i;       // 0 = odd, 1 = even
  wire parity_bit_o;

  // -------------------------------------------------------------------------
  // Instantiate DUT
  // -------------------------------------------------------------------------
  uart_parity_bit_compute dut (
    .clk_i       (clk_i),
    .arstn_i     (arstn_i),
    .rst_i       (rst_i),
    .data_i      (data_i),
    .valid_i     (valid_i),
    .mode_i      (mode_i),
    .parity_bit_o(parity_bit_o)
  );

  // -------------------------------------------------------------------------
  // Clock generation : 100 MHz -> 10 ns period
  // -------------------------------------------------------------------------
  initial clk_i = 1'b0;
  always #5 clk_i = ~clk_i;

  // -------------------------------------------------------------------------
  // Task: apply one valid bit
  // -------------------------------------------------------------------------
  task send_bit;
    input bit_val;
    begin
      @(negedge clk_i);
      data_i  = bit_val;
      valid_i = 1'b1;
      @(posedge clk_i); #1;
      valid_i = 1'b0;
    end
  endtask

  // -------------------------------------------------------------------------
  // Task: check expected output
  // -------------------------------------------------------------------------
  integer pass_count;
  integer fail_count;

  task check;
    input        expected;
    input [63:0] tc_num;
    begin
      if (parity_bit_o === expected) begin
        $display("PASS  TC%0d : parity_bit_o = %b (expected %b)", tc_num, parity_bit_o, expected);
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL  TC%0d : parity_bit_o = %b (expected %b)", tc_num, parity_bit_o, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin
    // Init
    pass_count = 0;
    fail_count = 0;
    arstn_i = 1'b0;
    rst_i   = 1'b0;
    data_i  = 1'b0;
    valid_i = 1'b0;
    mode_i  = 1'b0;   // odd parity mode

    // ------- TC1 : asynchronous reset -------
    // Counter should be 0 after async reset.
    // Odd mode: parity_bit_o = ~counter = 1
    @(negedge clk_i);
    arstn_i = 1'b1;
    @(posedge clk_i); #1;
    check(1'b1, 64'd1);   // odd parity, 0 ones seen -> parity=1

    // ------- TC2 : odd parity, 1 one -------
    // After one valid '1', counter=1 -> parity_bit_o = ~1 = 0
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b0, 64'd2);

    // ------- TC3 : odd parity, 2 ones -------
    // After another valid '1', counter=0 -> parity_bit_o = ~0 = 1
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b1, 64'd3);

    // ------- TC4 : even parity, 1 one -------
    // Switch to even mode. Reset first.
    @(negedge clk_i);
    rst_i  = 1'b1;
    mode_i = 1'b1;   // even parity mode
    @(posedge clk_i); #1;
    rst_i  = 1'b0;
    // counter=0 -> even parity_bit_o = counter = 0  (0 ones -> need 0 for even)
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b1, 64'd4);   // 1 one seen, counter=1 -> even parity_bit_o = 1

    // ------- TC5 : even parity, 2 ones -------
    send_bit(1'b1);
    @(posedge clk_i); #1;
    check(1'b0, 64'd5);   // 2 ones, counter=0 -> even parity_bit_o = 0

    // ------- TC6 : valid=0 does not advance counter -------
    // Still in even mode, counter=0. Send data=1 but valid=0
    @(negedge clk_i);
    data_i  = 1'b1;
    valid_i = 1'b0;
    @(posedge clk_i); #1;
    check(1'b0, 64'd6);   // counter unchanged -> parity_bit_o = 0

    // ------- TC7 : synchronous soft reset -------
    @(negedge clk_i);
    rst_i = 1'b1;
    @(posedge clk_i); #1;
    rst_i = 1'b0;
    // even mode, counter reset to 0 -> parity_bit_o = 0
    @(posedge clk_i); #1;
    check(1'b0, 64'd7);

    // ------- TC8 : asynchronous reset mid-operation -------
    send_bit(1'b1);      // counter = 1
    @(negedge clk_i);
    arstn_i = 1'b0;      // assert async reset
    #3;
    // counter must be 0 immediately (asynchronous)
    // even mode, counter=0 -> parity_bit_o = 0
    if (parity_bit_o === 1'b0)
      $display("PASS  TC8 : async reset mid-operation OK, parity_bit_o = %b", parity_bit_o);
    else
      $display("FAIL  TC8 : async reset mid-operation, parity_bit_o = %b (expected 0)", parity_bit_o);
    arstn_i = 1'b1;

    // ------- Summary -------
    #20;
    $display("-------------------------------");
    $display("Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
    $display("-------------------------------");
    if (fail_count == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");
    $finish;
  end

  // Simulation timeout
  initial begin
    #10000;
    $display("TIMEOUT: simulation did not finish in time");
    $finish;
  end

endmodule
