class spi_vip_monitor extends uvm_monitor;
  virtual spi_vip_if vif;
  uvm_analysis_port #(spi_vip_item) ap;
  `uvm_component_utils(spi_vip_monitor)

  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual spi_vip_if)::get(this, "", "vif", vif));
  endfunction

  task run_phase(uvm_phase phase);
    // Monitor interface signals
  endtask
endclass
