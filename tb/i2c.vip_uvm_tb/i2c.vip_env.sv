class i2c.vip_env extends uvm_env;
i2c.vip_agent agent; i2c.vip_scoreboard sb;
`uvm_component_utils(i2c.vip_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=i2c.vip_agent::type_id::create("agent",this); sb=i2c.vip_scoreboard::type_id::create("sb",this); endfunction
endclass
