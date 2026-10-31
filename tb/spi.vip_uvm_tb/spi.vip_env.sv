class spi.vip_env extends uvm_env;
spi.vip_agent agent; spi.vip_scoreboard sb;
`uvm_component_utils(spi.vip_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=spi.vip_agent::type_id::create("agent",this); sb=spi.vip_scoreboard::type_id::create("sb",this); endfunction
endclass
