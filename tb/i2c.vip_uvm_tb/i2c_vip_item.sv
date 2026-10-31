class i2c_vip_item extends uvm_sequence_item;
  rand bit i2c_scl_io;
  rand bit i2c_sda_io;

  `uvm_object_utils(i2c_vip_item)

  function new(string name="i2c_vip_item");
    super.new(name);
  endfunction
endclass
