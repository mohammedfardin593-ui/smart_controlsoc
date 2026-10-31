class gpio.vip_item extends uvm_sequence_item;

  bit [31:0] gpio_io;

  `uvm_object_utils(gpio.vip_item)

  function new(string name="gpio.vip_item"); super.new(name); endfunction
endclass
