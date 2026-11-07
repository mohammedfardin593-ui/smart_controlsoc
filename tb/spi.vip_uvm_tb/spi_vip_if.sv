// =============================================================================
// SPI VIP Interface: spi_vip_if
// Connects to SoC SPI Master ports (spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i)
// =============================================================================

`ifndef SPI_VIP_IF_SV
`define SPI_VIP_IF_SV

interface spi_vip_if (
  input logic clk,
  input logic rst_n
);
  logic spi_clk_o;
  logic spi_cs_n_o;
  logic spi_mosi_o;
  logic spi_miso_i = 1'b0;
endinterface : spi_vip_if

`endif // SPI_VIP_IF_SV
