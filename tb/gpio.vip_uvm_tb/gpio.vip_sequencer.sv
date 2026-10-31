class gpio.vip_sequencer extends uvm_sequencer #(gpio.vip_item);
`uvm_component_utils(gpio.vip_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
