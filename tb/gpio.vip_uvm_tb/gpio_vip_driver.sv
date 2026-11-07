// =============================================================================
// GPIO VIP Driver: gpio_vip_driver
// Drives external GPIO pins according to transaction mask
// =============================================================================

`ifndef GPIO_VIP_DRIVER_SV
`define GPIO_VIP_DRIVER_SV

class gpio_vip_driver extends uvm_driver #(gpio_vip_item);
  virtual gpio_vip_if vif;
  uvm_analysis_port #(gpio_vip_item) drv_ap;

  `uvm_component_utils(gpio_vip_driver)

  function new(string n, uvm_component p);
    super.new(n, p);
    drv_ap = new("drv_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface gpio_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.release_pins();
    wait (vif.rst_n === 1'b1);
    `uvm_info(get_type_name(), "GPIO VIP Driver active.", UVM_LOW)

    forever begin
      seq_item_port.get_next_item(req);
      vif.drive_pins(req.gpio_data, req.gpio_mask);
      drv_ap.write(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass : gpio_vip_driver

`endif // GPIO_VIP_DRIVER_SV
