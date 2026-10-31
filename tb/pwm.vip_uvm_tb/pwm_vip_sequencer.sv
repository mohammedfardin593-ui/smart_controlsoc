class pwm_vip_sequencer extends uvm_sequencer #(pwm_vip_item);
  `uvm_component_utils(pwm_vip_sequencer)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
