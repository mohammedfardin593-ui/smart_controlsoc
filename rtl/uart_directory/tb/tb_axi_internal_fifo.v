/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : tb_axi_internal_fifo.v
 * Description    : Testbench for axi_internal_fifo module
 * -----------------------------------------------------------------------------
 * Test cases:
 *   TC1 : Async reset - FIFO starts empty, data_o = 0
 *   TC2 : Push single entry and verify data_o reflects it
 *   TC3 : Push multiple entries then pull them in FIFO order
 *   TC4 : Pull from empty FIFO - data_o remains 0, space unchanged
 *   TC5 : Fill FIFO to capacity (16 entries) - full flag asserted
 *   TC6 : Simultaneous push and pull (PP case)
 *   TC7 : Overflow - push into full FIFO overwrites oldest entry
 *   TC8 : Synchronous soft reset clears FIFO
 *   TC9 : available_write_space flag behavior (PORT_EN=3'b111)
 *   TC10: load flag asserted when FIFO is non-empty
 * -----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tb_axi_internal_fifo;

  // -------------------------------------------------------------------------
  // Parameters matching DUT defaults
  // -------------------------------------------------------------------------
  localparam FIFO_SIZE    = 16;
  localparam DATA_SIZE    = 8;
  localparam INDEX_LENGTH = 4;
  localparam PORT_EN      = 3'b111;  // load | full | available_space
  // STATUS_WIDTH = INDEX_LENGTH + EN_AVAILABLE + EN_FULL + EN_LOAD = 4+1+1+1 = 7
  // status_o is [STATUS_WIDTH:0] = [7:0] = 8 bits
  localparam STATUS_WIDTH = INDEX_LENGTH + 3; // 7

  // -------------------------------------------------------------------------
  // DUT ports
  // -------------------------------------------------------------------------
  reg                     clk_i;
  reg                     arstn_i;
  reg                     rst_i;
  reg                     push_i;
  reg                     pull_i;
  reg  [DATA_SIZE-1:0]    data_i;
  wire [DATA_SIZE-1:0]    data_o;
  wire [STATUS_WIDTH:0]   status_o;

  // -------------------------------------------------------------------------
  // Convenience status field extractions (PORT_EN = 3'b111)
  // status_o = {load, full, available_write_space, space[INDEX_LENGTH:0]}
  // -------------------------------------------------------------------------
  wire [INDEX_LENGTH:0] space_w              = status_o[INDEX_LENGTH:0];
  wire                  available_space_w    = status_o[INDEX_LENGTH+1];
  wire                  full_w               = status_o[INDEX_LENGTH+2];
  wire                  load_w               = status_o[INDEX_LENGTH+3];

  // -------------------------------------------------------------------------
  // Instantiate DUT
  // -------------------------------------------------------------------------
  axi_internal_fifo #(
    .FIFO_SIZE    (FIFO_SIZE),
    .DATA_SIZE    (DATA_SIZE),
    .INDEX_LENGTH (INDEX_LENGTH),
    .PORT_EN      (PORT_EN)
  ) dut (
    .clk_i    (clk_i),
    .arstn_i  (arstn_i),
    .rst_i    (rst_i),
    .push_i   (push_i),
    .pull_i   (pull_i),
    .data_i   (data_i),
    .data_o   (data_o),
    .status_o (status_o)
  );

  // -------------------------------------------------------------------------
  // Clock: 100 MHz
  // -------------------------------------------------------------------------
  initial clk_i = 1'b0;
  always #5 clk_i = ~clk_i;

  // -------------------------------------------------------------------------
  // Test counters
  // -------------------------------------------------------------------------
  integer pass_count;
  integer fail_count;
  integer i;

  // -------------------------------------------------------------------------
  // Tasks
  // -------------------------------------------------------------------------
  task do_push;
    input [DATA_SIZE-1:0] val;
    begin
      @(negedge clk_i);
      data_i = val;
      push_i = 1'b1;
      pull_i = 1'b0;
      @(posedge clk_i); #1;
      push_i = 1'b0;
    end
  endtask

  task do_pull;
    begin
      @(negedge clk_i);
      push_i = 1'b0;
      pull_i = 1'b1;
      @(posedge clk_i); #1;
      pull_i = 1'b0;
    end
  endtask

  task do_push_pull;
    input [DATA_SIZE-1:0] val;
    begin
      @(negedge clk_i);
      data_i = val;
      push_i = 1'b1;
      pull_i = 1'b1;
      @(posedge clk_i); #1;
      push_i = 1'b0;
      pull_i = 1'b0;
    end
  endtask

  task idle_cycle;
    begin
      @(negedge clk_i);
      push_i = 1'b0;
      pull_i = 1'b0;
      @(posedge clk_i); #1;
    end
  endtask

  task check_val;
    input [DATA_SIZE-1:0] actual;
    input [DATA_SIZE-1:0] expected;
    input [63:0]          tc_num;
    input [63:0]          sub;
    begin
      if (actual === expected) begin
        $display("PASS  TC%0d.%0d : got 0x%02h (expected 0x%02h)", tc_num, sub, actual, expected);
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL  TC%0d.%0d : got 0x%02h (expected 0x%02h)", tc_num, sub, actual, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  task check_bit;
    input        actual;
    input        expected;
    input [63:0] tc_num;
    input [127:0] label;
    begin
      if (actual === expected) begin
        $display("PASS  TC%0d [%s] : got %b (expected %b)", tc_num, label, actual, expected);
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL  TC%0d [%s] : got %b (expected %b)", tc_num, label, actual, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin
    pass_count = 0;
    fail_count = 0;
    arstn_i    = 1'b0;
    rst_i      = 1'b0;
    push_i     = 1'b0;
    pull_i     = 1'b0;
    data_i     = 8'h00;

    // Release async reset
    #15;
    arstn_i = 1'b1;
    @(posedge clk_i); #1;

    // =======================================================================
    // TC1: After reset - FIFO empty
    // =======================================================================
    $display("--- TC1: After async reset ---");
    check_val(data_o,  8'h00, 64'd1, 64'd1);  // data_o = 0 when empty
    check_bit(load_w,  1'b0,  64'd1, "load");   // no valid data to load
    check_val(space_w, FIFO_SIZE[INDEX_LENGTH:0], 64'd1, 64'd2); // space = FIFO_SIZE

    // =======================================================================
    // TC2: Push one entry, read back
    // =======================================================================
    $display("--- TC2: Push single entry ---");
    do_push(8'hAB);
    idle_cycle;
    check_val(data_o, 8'hAB, 64'd2, 64'd1);
    check_bit(load_w, 1'b1,  64'd2, "load");

    // =======================================================================
    // TC3: Push multiple then pull in order
    // =======================================================================
    $display("--- TC3: FIFO ordering ---");
    // FIFO already has 0xAB at head. Push more entries.
    do_push(8'hCD);
    do_push(8'hEF);
    idle_cycle;
    // Head should still be 0xAB
    check_val(data_o, 8'hAB, 64'd3, 64'd1);
    do_pull;           // remove 0xAB
    idle_cycle;
    check_val(data_o, 8'hCD, 64'd3, 64'd2);
    do_pull;           // remove 0xCD
    idle_cycle;
    check_val(data_o, 8'hEF, 64'd3, 64'd3);
    do_pull;           // remove 0xEF
    idle_cycle;

    // =======================================================================
    // TC4: Pull from empty FIFO - data_o = 0
    // =======================================================================
    $display("--- TC4: Pull from empty FIFO ---");
    check_val(data_o, 8'h00, 64'd4, 64'd1);
    check_bit(load_w, 1'b0, 64'd4, "load");
    do_pull;           // pull on empty - must not change space
    idle_cycle;
    check_val(space_w, FIFO_SIZE[INDEX_LENGTH:0], 64'd4, 64'd2);

    // =======================================================================
    // TC5: Fill FIFO to capacity -> full flag asserted
    // =======================================================================
    $display("--- TC5: Fill FIFO to capacity ---");
    for (i = 0; i < FIFO_SIZE; i = i + 1)
      do_push(i[DATA_SIZE-1:0]);
    idle_cycle;
    check_bit(full_w, 1'b1, 64'd5, "full");
    check_val(space_w, 5'd0, 64'd5, "space");

    // Drain FIFO
    for (i = 0; i < FIFO_SIZE; i = i + 1)
      do_pull;
    idle_cycle;

    // =======================================================================
    // TC6: Simultaneous push and pull
    // =======================================================================
    $display("--- TC6: Simultaneous push & pull ---");
    do_push(8'h11);
    idle_cycle;
    // FIFO has 0x11 at head; now push 0x22 and pull simultaneously
    do_push_pull(8'h22);
    idle_cycle;
    // head should have advanced to 0x22
    check_val(data_o, 8'h22, 64'd6, 64'd1);

    // =======================================================================
    // TC7: Overflow - push into full FIFO overwrites oldest
    // =======================================================================
    $display("--- TC7: Overflow push ---");
    // Reset first for clean state
    @(negedge clk_i);
    rst_i = 1'b1;
    @(posedge clk_i); #1;
    rst_i = 1'b0;
    idle_cycle;
    // Fill FIFO
    for (i = 0; i < FIFO_SIZE; i = i + 1)
      do_push(i[DATA_SIZE-1:0]);
    idle_cycle;
    check_bit(full_w, 1'b1, 64'd7, "full_before_overflow");
    // Push one more (overflow)
    do_push(8'hFF);
    idle_cycle;
    // FIFO is still full
    check_bit(full_w, 1'b1, 64'd7, "full_after_overflow");
    // Drain
    for (i = 0; i < FIFO_SIZE; i = i + 1)
      do_pull;
    idle_cycle;

    // =======================================================================
    // TC8: Synchronous soft reset clears FIFO
    // =======================================================================
    $display("--- TC8: Synchronous soft reset ---");
    do_push(8'hDE);
    do_push(8'hAD);
    idle_cycle;
    check_bit(load_w, 1'b1, 64'd8, "load_before_rst");
    @(negedge clk_i);
    rst_i = 1'b1;
    @(posedge clk_i); #1;
    rst_i = 1'b0;
    idle_cycle;
    check_val(data_o,  8'h00, 64'd8, 64'd1);
    check_bit(load_w,  1'b0,  64'd8, "load_after_rst");
    check_val(space_w, FIFO_SIZE[INDEX_LENGTH:0], 64'd8, 64'd2);

    // =======================================================================
    // TC9: available_write_space (FIFO_THRESHOLD = 90% of 16 = ~14 entries)
    // =======================================================================
    $display("--- TC9: available_write_space flag ---");
    // Fresh FIFO - space=16 >= threshold(~14) -> available=1
    check_bit(available_space_w, 1'b1, 64'd9, "avail_space_empty");
    // Push 15 entries (space=1 < threshold) -> available=0
    for (i = 0; i < 15; i = i + 1)
      do_push(i[DATA_SIZE-1:0]);
    idle_cycle;
    check_bit(available_space_w, 1'b0, 64'd9, "avail_space_near_full");
    // Drain
    for (i = 0; i < 15; i = i + 1)
      do_pull;
    idle_cycle;

    // =======================================================================
    // TC10: load flag asserted when FIFO is non-empty
    // =======================================================================
    $display("--- TC10: load flag ---");
    check_bit(load_w, 1'b0, 64'd10, "load_empty");
    do_push(8'h55);
    idle_cycle;
    check_bit(load_w, 1'b1, 64'd10, "load_nonempty");

    // =======================================================================
    // Summary
    // =======================================================================
    #50;
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
    #500000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
