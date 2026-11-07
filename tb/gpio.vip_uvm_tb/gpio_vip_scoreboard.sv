// =============================================================================
// GPIO VIP Scoreboard: gpio_vip_scoreboard
// =============================================================================

`ifndef GPIO_VIP_SCOREBOARD_SV
`define GPIO_VIP_SCOREBOARD_SV

`uvm_analysis_imp_decl(_gpio_mon)
`uvm_analysis_imp_decl(_gpio_drv)

class gpio_vip_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(gpio_vip_scoreboard)

  uvm_analysis_imp_gpio_mon #(gpio_vip_item, gpio_vip_scoreboard) mon_imp;
  uvm_analysis_imp_gpio_drv #(gpio_vip_item, gpio_vip_scoreboard) drv_imp;

  int match_count = 0;
  int mismatch_count = 0;
  logic [31:0] last_mon_val = 32'h0;

  function new(string n, uvm_component p);
    super.new(n, p);
    mon_imp = new("mon_imp", this);
    drv_imp = new("drv_imp", this);
  endfunction

  virtual function void write_gpio_mon(gpio_vip_item item);
    last_mon_val = item.sampled_gpio;
    `uvm_info(get_type_name(), $sformatf("[GPIO PIN MON] Observed GPIO pin transition: 0x%08h", item.sampled_gpio), UVM_LOW)
  endfunction

  virtual function void write_gpio_drv(gpio_vip_item item);
    `uvm_info(get_type_name(), $sformatf("[GPIO PIN DRV] Driver applied: data=0x%08h, mask=0x%08h", item.gpio_data, item.gpio_mask), UVM_LOW)
  endfunction

  // Check function to verify output pins match expected CPU output
  function void check_gpio_output(logic [31:0] exp_val, logic [31:0] mask);
    logic [31:0] actual = last_mon_val & mask;
    logic [31:0] expected = exp_val & mask;
    if (actual === expected) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD PASS] Output match! Expected=0x%08h, Observed=0x%08h (mask=0x%08h)", expected, actual, mask), UVM_LOW)
      match_count++;
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD FAIL] Output mismatch! Expected=0x%08h, Observed=0x%08h (mask=0x%08h)", expected, actual, mask))
      mismatch_count++;
    end
  endfunction

  // Check function to verify CPU readback matches what VIP driver drove
  function void check_cpu_readback(logic [31:0] exp_val, logic [31:0] read_val, logic [31:0] mask);
    logic [31:0] actual = read_val & mask;
    logic [31:0] expected = exp_val & mask;
    if (actual === expected) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD PASS] CPU readback match! Expected=0x%08h, Read=0x%08h (mask=0x%08h)", expected, actual, mask), UVM_LOW)
      match_count++;
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD FAIL] CPU readback mismatch! Expected=0x%08h, Read=0x%08h (mask=0x%08h)", expected, actual, mask))
      mismatch_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "               GPIO SCOREBOARD SUMMARY                            ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Matches    : %0d", match_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Mismatches : %0d", mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    if (mismatch_count > 0) begin
      `uvm_error(get_type_name(), "GPIO Verification Failed!")
    end else if (match_count > 0) begin
      `uvm_info(get_type_name(), "GPIO Verification Completed Successfully!", UVM_LOW)
    end
  endfunction
endclass : gpio_vip_scoreboard

`endif // GPIO_VIP_SCOREBOARD_SV
