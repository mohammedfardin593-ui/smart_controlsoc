class uart.vip_env extends uvm_env;
uart.vip_agent agent; uart.vip_scoreboard sb;
`uvm_component_utils(uart.vip_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=uart.vip_agent::type_id::create("agent",this); sb=uart.vip_scoreboard::type_id::create("sb",this); endfunction
endclass
