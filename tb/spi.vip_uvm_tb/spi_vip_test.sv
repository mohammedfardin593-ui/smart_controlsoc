class spi_vip_test extends uvm_test;
  spi_vip_env env;
  `uvm_component_utils(spi_vip_test)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spi_vip_env::type_id::create("env", this);
  endfunction
endclass
