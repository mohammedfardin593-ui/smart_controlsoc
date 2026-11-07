// =============================================================================
// SPI VIP Monitor: spi_vip_monitor
// Passively reconstructs full-duplex SPI bytes on posedge spi_clk_o
// =============================================================================

`ifndef SPI_VIP_MONITOR_SV
`define SPI_VIP_MONITOR_SV

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
    if (!uvm_config_db#(virtual spi_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface spi_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    spi_vip_item item;
    bit [7:0] mosi_byte;
    bit [7:0] miso_byte;

    wait (vif.rst_n === 1'b1);
    `uvm_info(get_type_name(), "SPI VIP Monitor active and listening...", UVM_LOW)

    forever begin
      // Wait for CS active LOW
      wait (vif.spi_cs_n_o === 1'b0);

      // Sample 8 bits on posedge of SPI clock (MSB first)
      mosi_byte = 8'h00;
      miso_byte = 8'h00;
      for (int i = 7; i >= 0; i--) begin
        @(posedge vif.spi_clk_o);
        mosi_byte[i] = vif.spi_mosi_o;
        miso_byte[i] = vif.spi_miso_i;
      end

      item = spi_vip_item::type_id::create("item");
      item.mosi_data = mosi_byte;
      item.miso_data = miso_byte;

      `uvm_info(get_type_name(), $sformatf("[SPI TRANSFER MON] MOSI: 0x%02h, MISO: 0x%02h", 
          item.mosi_data, item.miso_data), UVM_LOW)

      ap.write(item);
    end
  endtask
endclass : spi_vip_monitor

`endif // SPI_VIP_MONITOR_SV
