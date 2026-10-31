interface spi_vip_if (
  input logic clk,
  input logic rst_n
);
  logic spi_clk_o;
  logic spi_cs_n_o;
  logic spi_mosi_o;
  logic spi_miso_i;
endinterface
