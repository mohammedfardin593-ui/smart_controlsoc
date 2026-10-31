class spi.vip_monitor extends uvm_monitor;
virtual spi.vip_if vif;
uvm_analysis_port #(spi.vip_item) ap;
`uvm_component_utils(spi.vip_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
