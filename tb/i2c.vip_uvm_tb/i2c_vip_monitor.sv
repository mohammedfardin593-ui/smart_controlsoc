class i2c_vip_monitor extends uvm_monitor;
  virtual i2c_vip_if vif;
  uvm_analysis_port #(i2c_vip_item) ap;
  `uvm_component_utils(i2c_vip_monitor)

  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual i2c_vip_if)::get(this, "", "vif", vif));
  endfunction

  task run_phase(uvm_phase phase);
    // Monitor interface signals
  endtask
endclass
