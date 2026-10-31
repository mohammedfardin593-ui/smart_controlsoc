class gpio_vip_env extends uvm_env;
  gpio_vip_agent agent;
  gpio_vip_scoreboard sb;
  `uvm_component_utils(gpio_vip_env)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = gpio_vip_agent::type_id::create("agent", this);
    sb    = gpio_vip_scoreboard::type_id::create("sb", this);
  endfunction
endclass
