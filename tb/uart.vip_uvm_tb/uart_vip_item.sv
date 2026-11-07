// =============================================================================
// UART VIP Sequence Item: uart_vip_item
// Defines full UART frame attributes for 8-N-1 and configurable frames
// =============================================================================

`ifndef UART_VIP_ITEM_SV
`define UART_VIP_ITEM_SV

class uart_vip_item extends uvm_sequence_item;
  rand bit [7:0]  data;
  rand int        baud_rate;
  rand int        data_bits;
  rand int        stop_bits;
  rand bit        parity_en;
  rand bit        parity_mode; // 0 = odd, 1 = even

  // Status & measurement flags
  realtime        transmit_time;
  bit             framing_error;
  bit             parity_error;

  constraint c_default {
    soft baud_rate   == 115200;
    soft data_bits   == 8;
    soft stop_bits   == 1;
    soft parity_en   == 1'b0;
    soft parity_mode == 1'b0;
  }

  `uvm_object_utils_begin(uart_vip_item)
    `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(baud_rate, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(data_bits, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(stop_bits, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(parity_en, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(parity_mode, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(framing_error, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(parity_error, UVM_ALL_ON | UVM_BIN)
    `uvm_field_real(transmit_time, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "uart_vip_item");
    super.new(name);
    data          = 8'h00;
    baud_rate     = 115200;
    data_bits     = 8;
    stop_bits     = 1;
    parity_en     = 1'b0;
    parity_mode   = 1'b0;
    framing_error = 1'b0;
    parity_error  = 1'b0;
  endfunction

  virtual function string convert2string();
    return $sformatf("UART Item: data=0x%02h ('%c'), baud=%0d, bits=%0d, stop=%0d, parity_en=%0b, framing_err=%0b",
                     data, (data >= 32 && data < 127) ? data : 8'h2E, baud_rate, data_bits, stop_bits, parity_en, framing_error);
  endfunction

endclass : uart_vip_item

`endif // UART_VIP_ITEM_SV
