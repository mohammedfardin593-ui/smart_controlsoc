interface uart_vip_if (
  input logic clk,
  input logic rst_n
);
  logic uart_rx_i;
  logic uart_tx_o;
endinterface
