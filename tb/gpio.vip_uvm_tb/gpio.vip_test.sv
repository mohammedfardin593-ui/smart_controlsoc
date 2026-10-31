class gpio.vip_test extends uvm_test;
gpio.vip_env env;
`uvm_component_utils(gpio.vip_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=gpio.vip_env::type_id::create("env",this); endfunction
endclass
