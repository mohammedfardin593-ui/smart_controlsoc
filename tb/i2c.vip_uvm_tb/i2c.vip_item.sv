class i2c.vip_item extends uvm_sequence_item;

  bit i2c_scl_io;
  bit i2c_sda_io;

  `uvm_object_utils(i2c.vip_item)

  function new(string name="i2c.vip_item"); super.new(name); endfunction
endclass
