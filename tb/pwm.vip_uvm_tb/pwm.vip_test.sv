class pwm.vip_test extends uvm_test;
pwm.vip_env env;
`uvm_component_utils(pwm.vip_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=pwm.vip_env::type_id::create("env",this); endfunction
endclass
