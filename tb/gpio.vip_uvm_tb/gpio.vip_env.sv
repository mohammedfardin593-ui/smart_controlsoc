class gpio.vip_env extends uvm_env;
gpio.vip_agent agent; gpio.vip_scoreboard sb;
`uvm_component_utils(gpio.vip_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=gpio.vip_agent::type_id::create("agent",this); sb=gpio.vip_scoreboard::type_id::create("sb",this); endfunction
endclass
