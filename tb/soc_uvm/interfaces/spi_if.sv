// =============================================================================
// Interface: spi_if
// Peripheral: SPI Master Controller Interface for Smart Control SoC
// Signals match smart_controlsoc_top SPI external ports
// =============================================================================

`ifndef SPI_IF_SV
`define SPI_IF_SV

interface spi_if (
    input logic clk,
    input logic rst_n
);
    logic spi_clk_o;
    logic spi_cs_n_o;
    logic spi_mosi_o;
    logic spi_miso_i;

    // Clocking block for synchronous sampling/driving
    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        input  spi_clk_o;
        input  spi_cs_n_o;
        input  spi_mosi_o;
        output spi_miso_i;
    endclocking

    modport tb (
        clocking cb,
        input    spi_clk_o,
        input    spi_cs_n_o,
        input    spi_mosi_o,
        output   spi_miso_i,
        input    clk,
        input    rst_n
    );

    modport dut (
        output spi_clk_o,
        output spi_cs_n_o,
        output spi_mosi_o,
        input  spi_miso_i,
        input  clk,
        input  rst_n
    );

endinterface : spi_if

`endif // SPI_IF_SV
