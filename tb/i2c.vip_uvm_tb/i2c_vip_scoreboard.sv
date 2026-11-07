// =============================================================================
// I2C VIP Scoreboard: i2c_vip_scoreboard
// Verifies I2C transactions, slave addressing, write and readback integrity
// =============================================================================

`ifndef I2C_VIP_SCOREBOARD_SV
`define I2C_VIP_SCOREBOARD_SV

class i2c_vip_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(i2c_vip_scoreboard)

  uvm_analysis_imp #(i2c_vip_item, i2c_vip_scoreboard) mon_imp;

  int match_count    = 0;
  int mismatch_count = 0;

  function new(string n, uvm_component p);
    super.new(n, p);
    mon_imp = new("mon_imp", this);
  endfunction

  virtual function void write(i2c_vip_item item);
    `uvm_info(get_type_name(), $sformatf("[I2C BUS MON] Transaction captured: Addr=0x%02h, %s, Bytes=%0d", 
        item.addr, item.op.name(), item.data.size()), UVM_LOW)
    for (int i = 0; i < item.data.size(); i++) begin
      `uvm_info(get_type_name(), $sformatf("  [I2C Byte %0d] 0x%02h", i, item.data[i]), UVM_LOW)
    end
  endfunction

  function void check_i2c_write(bit [6:0] exp_addr, bit [7:0] exp_mem_addr, bit [7:0] exp_data, bit [7:0] rxack_status);
    if (rxack_status[7] == 1'b0) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD PASS] I2C Write to Addr=0x%02h (Mem: 0x%02h, Data: 0x%02h) acknowledged by slave!", 
          exp_addr, exp_mem_addr, exp_data), UVM_LOW)
      match_count++;
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD FAIL] I2C Write to Addr=0x%02h received NACK (SR=0x%02h)", 
          exp_addr, rxack_status))
      mismatch_count++;
    end
  endfunction

  function void check_i2c_read(bit [6:0] exp_addr, bit [7:0] exp_data, bit [7:0] actual_data);
    if (actual_data === exp_data) begin
      `uvm_info(get_type_name(), $sformatf("[SCOREBOARD PASS] I2C Read from Addr=0x%02h matched expected data 0x%02h!", 
          exp_addr, actual_data), UVM_LOW)
      match_count++;
    end else begin
      `uvm_error(get_type_name(), $sformatf("[SCOREBOARD FAIL] I2C Read mismatch! Expected=0x%02h, Read=0x%02h", 
          exp_data, actual_data))
      mismatch_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "                I2C SCOREBOARD SUMMARY                            ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Matches    : %0d", match_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Mismatches : %0d", mismatch_count), UVM_LOW)
    `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
    if (mismatch_count > 0) begin
      `uvm_error(get_type_name(), "I2C Verification Failed!")
    end else if (match_count > 0) begin
      `uvm_info(get_type_name(), "I2C Verification Completed Successfully!", UVM_LOW)
    end
  endfunction
endclass : i2c_vip_scoreboard

`endif // I2C_VIP_SCOREBOARD_SV
