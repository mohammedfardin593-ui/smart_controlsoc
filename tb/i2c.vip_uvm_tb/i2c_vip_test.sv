class i2c_vip_test extends uvm_test;
  i2c_vip_env env;
  `uvm_component_utils(i2c_vip_test)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = i2c_vip_env::type_id::create("env", this);
  endfunction
endclass
