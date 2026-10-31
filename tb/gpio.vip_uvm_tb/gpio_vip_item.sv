class gpio_vip_item extends uvm_sequence_item;
  rand bit [31:0] gpio_io;

  `uvm_object_utils(gpio_vip_item)

  function new(string name="gpio_vip_item");
    super.new(name);
  endfunction
endclass
