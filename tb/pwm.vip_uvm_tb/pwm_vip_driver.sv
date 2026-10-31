class pwm_vip_driver extends uvm_driver #(pwm_vip_item);
  virtual pwm_vip_if vif;
  `uvm_component_utils(pwm_vip_driver)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual pwm_vip_if)::get(this, "", "vif", vif));
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass
