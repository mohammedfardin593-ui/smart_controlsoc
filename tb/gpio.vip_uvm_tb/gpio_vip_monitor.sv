// =============================================================================
// GPIO VIP Monitor: gpio_vip_monitor
// Observes transitions on gpio_io[31:0] and broadcasts transactions
// =============================================================================

`ifndef GPIO_VIP_MONITOR_SV
`define GPIO_VIP_MONITOR_SV

class gpio_vip_monitor extends uvm_monitor;
  virtual gpio_vip_if vif;
  uvm_analysis_port #(gpio_vip_item) ap;

  `uvm_component_utils(gpio_vip_monitor)

  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface gpio_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] prev_val;
    gpio_vip_item item;

    wait (vif.rst_n === 1'b1);
    `uvm_info(get_type_name(), "GPIO VIP Monitor active.", UVM_LOW)
    prev_val = vif.gpio_io;

    forever begin
      @(posedge vif.clk);
      if (vif.gpio_io !== prev_val) begin
        prev_val = vif.gpio_io;
        item = gpio_vip_item::type_id::create("item");
        item.sampled_gpio = vif.gpio_io;
        ap.write(item);
      end
    end
  endtask
endclass : gpio_vip_monitor

`endif // GPIO_VIP_MONITOR_SV
