class i2c.vip_sequencer extends uvm_sequencer #(i2c.vip_item);
`uvm_component_utils(i2c.vip_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
