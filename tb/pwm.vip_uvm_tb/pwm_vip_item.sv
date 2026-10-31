class pwm_vip_item extends uvm_sequence_item;
  bit pwm_out_o;

  `uvm_object_utils(pwm_vip_item)

  function new(string name="pwm_vip_item");
    super.new(name);
  endfunction
endclass
