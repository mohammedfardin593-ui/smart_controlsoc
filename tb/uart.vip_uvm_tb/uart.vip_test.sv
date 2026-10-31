class uart.vip_test extends uvm_test;
uart.vip_env env;
`uvm_component_utils(uart.vip_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=uart.vip_env::type_id::create("env",this); endfunction
endclass
