class uart.vip_sequencer extends uvm_sequencer #(uart.vip_item);
`uvm_component_utils(uart.vip_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
