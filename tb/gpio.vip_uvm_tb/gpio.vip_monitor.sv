class gpio.vip_monitor extends uvm_monitor;
virtual gpio.vip_if vif;
uvm_analysis_port #(gpio.vip_item) ap;
`uvm_component_utils(gpio.vip_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
