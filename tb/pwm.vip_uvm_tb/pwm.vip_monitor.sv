class pwm.vip_monitor extends uvm_monitor;
virtual pwm.vip_if vif;
uvm_analysis_port #(pwm.vip_item) ap;
`uvm_component_utils(pwm.vip_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
