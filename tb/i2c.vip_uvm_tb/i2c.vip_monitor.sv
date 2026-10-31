class i2c.vip_monitor extends uvm_monitor;
virtual i2c.vip_if vif;
uvm_analysis_port #(i2c.vip_item) ap;
`uvm_component_utils(i2c.vip_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
