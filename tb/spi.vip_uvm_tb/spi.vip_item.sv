class spi.vip_item extends uvm_sequence_item;

  bit spi_clk_o;
  bit spi_cs_n_o;
  bit spi_mosi_o;
  rand bit spi_miso_i;

  `uvm_object_utils(spi.vip_item)

  function new(string name="spi.vip_item"); super.new(name); endfunction
endclass
