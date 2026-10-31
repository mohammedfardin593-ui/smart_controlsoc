class uart_vip_sequencer extends uvm_sequencer #(uart_vip_item);
  `uvm_component_utils(uart_vip_sequencer)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
