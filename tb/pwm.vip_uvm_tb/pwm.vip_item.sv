class pwm.vip_item extends uvm_sequence_item;

  bit pwm_out_o;

  `uvm_object_utils(pwm.vip_item)

  function new(string name="pwm.vip_item"); super.new(name); endfunction
endclass
