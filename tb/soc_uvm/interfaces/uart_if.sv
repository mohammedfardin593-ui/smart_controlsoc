// =============================================================================
// Interface: uart_if
// Peripheral: UART Controller Interface for Smart Control SoC
// Signals match smart_controlsoc_top UART external ports
// =============================================================================

`ifndef UART_IF_SV
`define UART_IF_SV

interface uart_if (
    input logic clk,
    input logic rst_n
);
    logic uart_rx_i;
    logic uart_tx_o;
    logic uart_interrupt_o;

    // Clocking block for synchronous testbench verification
    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        output uart_rx_i;
        input  uart_tx_o;
        input  uart_interrupt_o;
    endclocking

    modport tb (
        clocking cb,
        input    clk,
        input    rst_n
    );

    modport dut (
        input  uart_rx_i,
        output uart_tx_o,
        output uart_interrupt_o,
        input  clk,
        input  rst_n
    );

endinterface : uart_if

`endif // UART_IF_SV
