class pwm.vip_env extends uvm_env;
pwm.vip_agent agent; pwm.vip_scoreboard sb;
`uvm_component_utils(pwm.vip_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=pwm.vip_agent::type_id::create("agent",this); sb=pwm.vip_scoreboard::type_id::create("sb",this); endfunction
endclass
