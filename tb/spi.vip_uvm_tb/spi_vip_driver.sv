// =============================================================================
// SPI VIP Driver: spi_vip_driver
// Acts as external SPI Slave responder, driving MISO on SPI clock edges
// =============================================================================

`ifndef SPI_VIP_DRIVER_SV
`define SPI_VIP_DRIVER_SV

class spi_vip_driver extends uvm_driver #(spi_vip_item);
  virtual spi_vip_if vif;
  uvm_analysis_port #(spi_vip_item) drv_ap;

  `uvm_component_utils(spi_vip_driver)

  function new(string n, uvm_component p);
    super.new(n, p);
    drv_ap = new("drv_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface spi_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.spi_miso_i <= 1'b0;
    wait (vif.rst_n === 1'b1);
    `uvm_info(get_type_name(), "SPI VIP Slave Driver active.", UVM_LOW)

    forever begin
      seq_item_port.get_next_item(req);

      // Wait for CS to be asserted LOW
      wait (vif.spi_cs_n_o === 1'b0);

      // Drive MSB immediately for first clock sample
      vif.spi_miso_i <= req.miso_data[7];

      // Shift out remaining bits on consecutive falling clock edges
      for (int i = 6; i >= 0; i--) begin
        @(negedge vif.spi_clk_o);
        vif.spi_miso_i <= req.miso_data[i];
      end

      // Wait for 8th clock cycle falling edge (completing the full 8-pulse burst)
      @(negedge vif.spi_clk_o);
      drv_ap.write(req);
      seq_item_port.item_done();
    end
  endtask
endclass : spi_vip_driver

`endif // SPI_VIP_DRIVER_SV
