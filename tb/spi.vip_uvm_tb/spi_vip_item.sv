// =============================================================================
// SPI VIP Sequence Item: spi_vip_item
// Contains full-duplex MOSI and MISO data bytes
// =============================================================================

`ifndef SPI_VIP_ITEM_SV
`define SPI_VIP_ITEM_SV

class spi_vip_item extends uvm_sequence_item;
  rand bit [7:0] mosi_data;
  rand bit [7:0] miso_data;

  `uvm_object_utils_begin(spi_vip_item)
    `uvm_field_int(mosi_data, UVM_ALL_ON)
    `uvm_field_int(miso_data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "spi_vip_item");
    super.new(name);
  endfunction
endclass : spi_vip_item

`endif // SPI_VIP_ITEM_SV
