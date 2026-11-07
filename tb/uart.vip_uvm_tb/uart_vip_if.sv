// =============================================================================
// UART VIP Interface: uart_vip_if
// Connects UART VIP Driver and Monitor to SoC Top UART External Pins
// =============================================================================

`ifndef UART_VIP_IF_SV
`define UART_VIP_IF_SV

interface uart_vip_if (
  input logic clk,
  input logic rst_n
);
  // uart_rx_i: Serial line driven by VIP Driver into DUT SoC UART RX
  // Default idle state is HIGH (1'b1) per UART protocol
  logic uart_rx_i = 1'b1;

  // uart_tx_o: Serial line driven by DUT SoC UART TX, monitored by VIP
  logic uart_tx_o;

  // uart_interrupt_o: Interrupt output line from DUT UART peripheral
  logic uart_interrupt_o;

endinterface : uart_vip_if

`endif // UART_VIP_IF_SV
