// =============================================================================
// UART VIP Scoreboard: uart_vip_scoreboard
// Verifies end-to-end data integrity: Driver TX vs Monitor RX vs DUT RX vs CPU Read
// =============================================================================

`ifndef UART_VIP_SCOREBOARD_SV
`define UART_VIP_SCOREBOARD_SV

`uvm_analysis_imp_decl(_drv)
`uvm_analysis_imp_decl(_mon)

class uart_vip_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_vip_scoreboard)

  uvm_analysis_imp_drv #(uart_vip_item, uart_vip_scoreboard) drv_imp;
  uvm_analysis_imp_mon #(uart_vip_item, uart_vip_scoreboard) mon_imp;

  uart_vip_item drv_q[$];
  uart_vip_item mon_q[$];

  int unsigned num_driver_tx   = 0;
  int unsigned num_monitor_rx  = 0;
  int unsigned num_dut_rx      = 0;
  int unsigned num_cpu_reads   = 0;
  int unsigned num_matches     = 0;
  int unsigned num_mismatches  = 0;

  bit [7:0] last_expected_byte = 8'h00;
  bit [7:0] last_dut_byte      = 8'h00;
  bit [7:0] last_cpu_byte      = 8'h00;
  bit       dut_rx_passed      = 0;
  bit       cpu_read_passed    = 0;
  bit       check_enabled      = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    drv_imp = new("drv_imp", this);
    mon_imp = new("mon_imp", this);
  endfunction

  virtual function void write_drv(uart_vip_item item);
    uart_vip_item cloned;
    $cast(cloned, item.clone());
    drv_q.push_back(cloned);
    num_driver_tx++;
    last_expected_byte = item.data;
    check_enabled = 1;
    `uvm_info(get_type_name(), $sformatf("[SCOREBOARD] Recorded Driver TX item: 0x%02h", item.data), UVM_LOW)
  endfunction

  virtual function void write_mon(uart_vip_item item);
    uart_vip_item cloned;
    $cast(cloned, item.clone());
    mon_q.push_back(cloned);
    num_monitor_rx++;
    `uvm_info(get_type_name(), $sformatf("[SCOREBOARD] Recorded Monitor RX item: 0x%02h (framing_err=%0b)", item.data, item.framing_error), UVM_LOW)

    if (drv_q.size() > 0) begin
      uart_vip_item exp_item = drv_q.pop_front();
      if (exp_item.data === item.data && !item.framing_error) begin
        `uvm_info(get_type_name(), $sformatf("[SCOREBOARD MATCH] Driver TX (0x%02h) == Monitor RX (0x%02h)", exp_item.data, item.data), UVM_LOW)
        num_matches++;
      end else begin
        `uvm_error(get_type_name(), $sformatf("[SCOREBOARD MISMATCH] Driver TX (0x%02h) != Monitor RX (0x%02h) or framing error=%0b", exp_item.data, item.data, item.framing_error))
        num_mismatches++;
      end
    end
  endfunction

  virtual function void record_dut_rx(bit [7:0] data);
    num_dut_rx++;
    last_dut_byte = data;
    if (data === last_expected_byte) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD DUT MATCH] Peripheral RX FIFO received 0x%02h (matches expected 0x%02h)", data, last_expected_byte), UVM_LOW)
      dut_rx_passed = 1;
      num_matches++;
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD DUT MISMATCH] Peripheral RX FIFO received 0x%02h (expected 0x%02h)", data, last_expected_byte))
      dut_rx_passed = 0;
      num_mismatches++;
    end
  endfunction

  virtual function void record_cpu_read(bit [7:0] data);
    num_cpu_reads++;
    last_cpu_byte = data;
    if (data === last_expected_byte) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD CPU MATCH] CPU AXI readback from UART_RBR = 0x%02h (matches expected 0x%02h)", data, last_expected_byte), UVM_LOW)
      cpu_read_passed = 1;
      num_matches++;
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD CPU MISMATCH] CPU AXI readback 0x%02h != Expected 0x%02h", data, last_expected_byte))
      cpu_read_passed = 0;
      num_mismatches++;
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (num_mismatches > 0) begin
      `uvm_error(get_type_name(), $sformatf("Scoreboard check failed with %0d mismatches!", num_mismatches))
    end
    if (check_enabled && num_driver_tx == 0) begin
      `uvm_error(get_type_name(), "Scoreboard check failed: No transactions were driven by the UART VIP!")
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if (check_enabled || num_driver_tx > 0) begin
      `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
      `uvm_info(get_type_name(), "              UART END-TO-END SCOREBOARD SUMMARY                 ", UVM_LOW)
      `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("  Driver Frames Transmitted   : %0d (Target: 0x%02h)", num_driver_tx, last_expected_byte), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("  Monitor Frames Reconstructed: %0d", num_monitor_rx), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("  DUT RX FIFO Bytes Captured  : %0d (Observed: 0x%02h) [%s]", num_dut_rx, last_dut_byte, dut_rx_passed ? "PASS" : "FAIL"), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("  CPU AXI Readback Bytes      : %0d (Observed: 0x%02h) [%s]", num_cpu_reads, last_cpu_byte, cpu_read_passed ? "PASS" : "FAIL"), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Matches    : %0d", num_matches), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Mismatches : %0d", num_mismatches), UVM_LOW)
      `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    end
  endfunction

endclass : uart_vip_scoreboard

`endif // UART_VIP_SCOREBOARD_SV
