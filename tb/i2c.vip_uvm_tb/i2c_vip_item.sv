// =============================================================================
// I2C VIP Sequence Item: i2c_vip_item
// Captures I2C bus transactions: START, Address, R/W, Data bytes, ACK, STOP
// =============================================================================

`ifndef I2C_VIP_ITEM_SV
`define I2C_VIP_ITEM_SV

typedef enum bit { I2C_WRITE = 1'b0, I2C_READ = 1'b1 } i2c_op_e;

class i2c_vip_item extends uvm_sequence_item;
  bit [6:0] addr;
  i2c_op_e  op;
  bit [7:0] data[$];
  bit       nack; // 0 = ACK, 1 = NACK
  bit       is_start;
  bit       is_stop;

  `uvm_object_utils_begin(i2c_vip_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_enum(i2c_op_e, op, UVM_ALL_ON)
    `uvm_field_queue_int(data, UVM_ALL_ON)
    `uvm_field_int(nack, UVM_ALL_ON)
    `uvm_field_int(is_start, UVM_ALL_ON)
    `uvm_field_int(is_stop, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "i2c_vip_item");
    super.new(name);
  endfunction
endclass : i2c_vip_item

`endif // I2C_VIP_ITEM_SV
