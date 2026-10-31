class uart.vip_item extends uvm_sequence_item;

  rand bit uart_rx_i;
  bit uart_tx_o;

  `uvm_object_utils(uart.vip_item)

  function new(string name="uart.vip_item"); super.new(name); endfunction
endclass
