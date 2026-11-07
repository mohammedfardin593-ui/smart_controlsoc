// =============================================================================
// SPI VIP Scoreboard: spi_vip_scoreboard
// Verifies full-duplex MOSI transmission and MISO reception across CPU/AXI
// =============================================================================

`ifndef SPI_VIP_SCOREBOARD_SV
`define SPI_VIP_SCOREBOARD_SV

`uvm_analysis_imp_decl(_spi_mon)
`uvm_analysis_imp_decl(_spi_drv)

class spi_vip_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_vip_scoreboard)

  uvm_analysis_imp_spi_mon #(spi_vip_item, spi_vip_scoreboard) mon_imp;
  uvm_analysis_imp_spi_drv #(spi_vip_item, spi_vip_scoreboard) drv_imp;

  int match_count    = 0;
  int mismatch_count = 0;
  spi_vip_item last_mon_item;

  function new(string n, uvm_component p);
    super.new(n, p);
    mon_imp = new("mon_imp", this);
    drv_imp = new("drv_imp", this);
  endfunction

  virtual function void write_spi_mon(spi_vip_item item);
    last_mon_item = item;
  endfunction

  virtual function void write_spi_drv(spi_vip_item item);
    `uvm_info(get_type_name(), $sformatf("[SPI SLAVE DRV] Slave prepared MISO byte: 0x%02h", item.miso_data), UVM_LOW)
  endfunction

  function void check_spi_transfer(bit [7:0] exp_mosi, bit [7:0] exp_miso, bit [7:0] actual_drr);
    bit pass = 1'b1;

    if (last_mon_item == null) begin
      `uvm_error(get_type_name(), "[SCOREBOARD FAIL] No SPI transfer captured by monitor!")
      mismatch_count++;
      return;
    end

    // Verify MOSI data on bus
    if (last_mon_item.mosi_data === exp_mosi) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD PASS] MOSI match! Expected=0x%02h, Observed=0x%02h", 
          exp_mosi, last_mon_item.mosi_data), UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD FAIL] MOSI mismatch! Expected=0x%02h, Observed=0x%02h", 
          exp_mosi, last_mon_item.mosi_data))
      pass = 1'b0;
    end

    // Verify MISO data received by DUT CPU/AXI in DRR
    if (actual_drr === exp_miso) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD PASS] MISO CPU Readback match! Expected=0x%02h, Read=0x%02h", 
          exp_miso, actual_drr), UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD FAIL] MISO CPU Readback mismatch! Expected=0x%02h, Read=0x%02h", 
          exp_miso, actual_drr))
      pass = 1'b0;
    end

    if (pass) begin
      match_count++;
    end else begin
      mismatch_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "                SPI SCOREBOARD SUMMARY                            ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Matches    : %0d", match_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Mismatches : %0d", mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    if (mismatch_count > 0) begin
      `uvm_error(get_type_name(), "SPI Verification Failed!")
    end else if (match_count > 0) begin
      `uvm_info(get_type_name(), "SPI Verification Completed Successfully!", UVM_LOW)
    end
  endfunction
endclass : spi_vip_scoreboard

`endif // SPI_VIP_SCOREBOARD_SV
