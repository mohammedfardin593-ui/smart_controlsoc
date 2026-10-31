class uart.vip_monitor extends uvm_monitor;
virtual uart.vip_if vif;
uvm_analysis_port #(uart.vip_item) ap;
`uvm_component_utils(uart.vip_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
