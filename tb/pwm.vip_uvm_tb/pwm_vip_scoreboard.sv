// =============================================================================
// PWM VIP Scoreboard: pwm_vip_scoreboard
// Compares measured PWM waveform period and duty cycle against expected register setting
// =============================================================================

`ifndef PWM_VIP_SCOREBOARD_SV
`define PWM_VIP_SCOREBOARD_SV

class pwm_vip_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(pwm_vip_scoreboard)

  uvm_analysis_imp #(pwm_vip_item, pwm_vip_scoreboard) mon_imp;

  int match_count    = 0;
  int mismatch_count = 0;
  pwm_vip_item last_item;

  function new(string n, uvm_component p);
    super.new(n, p);
    mon_imp = new("mon_imp", this);
  endfunction

  virtual function void write(pwm_vip_item item);
    last_item = item;
  endfunction

  function void check_pwm_waveform(int exp_high_cycles, int exp_period_cycles);
    if (last_item == null) begin
      `uvm_error(get_type_name(), "[SCOREBOARD FAIL] No PWM waveform detected by monitor!")
      mismatch_count++;
      return;
    end

    if (last_item.period_cycles == exp_period_cycles && last_item.high_cycles == exp_high_cycles) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD PASS] PWM Waveform Match! Period=%0d cycles, High=%0d cycles (Duty: %0.2f%%)", 
          last_item.period_cycles, last_item.high_cycles, last_item.duty_cycle_pct), UVM_LOW)
      match_count++;
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD FAIL] PWM Waveform Mismatch! Expected: High=%0d, Period=%0d; Observed: High=%0d, Period=%0d", 
          exp_high_cycles, exp_period_cycles, last_item.high_cycles, last_item.period_cycles))
      mismatch_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "                PWM SCOREBOARD SUMMARY                            ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Matches    : %0d", match_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Mismatches : %0d", mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    if (mismatch_count > 0) begin
      `uvm_error(get_type_name(), "PWM Verification Failed!")
    end else if (match_count > 0) begin
      `uvm_info(get_type_name(), "PWM Verification Completed Successfully!", UVM_LOW)
    end
  endfunction
endclass : pwm_vip_scoreboard

`endif // PWM_VIP_SCOREBOARD_SV
