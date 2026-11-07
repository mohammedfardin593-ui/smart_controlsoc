// =============================================================================
// PWM VIP Sequence Item: pwm_vip_item
// Contains measured PWM waveform characteristics: period, high time, duty cycle
// =============================================================================

`ifndef PWM_VIP_ITEM_SV
`define PWM_VIP_ITEM_SV

class pwm_vip_item extends uvm_sequence_item;
  int  high_cycles;
  int  low_cycles;
  int  period_cycles;
  real duty_cycle_pct;

  `uvm_object_utils_begin(pwm_vip_item)
    `uvm_field_int(high_cycles, UVM_ALL_ON)
    `uvm_field_int(low_cycles, UVM_ALL_ON)
    `uvm_field_int(period_cycles, UVM_ALL_ON)
    `uvm_field_real(duty_cycle_pct, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pwm_vip_item");
    super.new(name);
  endfunction
endclass : pwm_vip_item

`endif // PWM_VIP_ITEM_SV
