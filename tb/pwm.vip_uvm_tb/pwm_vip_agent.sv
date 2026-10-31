class pwm_vip_agent extends uvm_agent;
  pwm_vip_driver drv;
  pwm_vip_monitor mon;
  pwm_vip_sequencer seqr;
  `uvm_component_utils(pwm_vip_agent)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = pwm_vip_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      drv = pwm_vip_driver::type_id::create("drv", this);
      seqr = pwm_vip_sequencer::type_id::create("seqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass
