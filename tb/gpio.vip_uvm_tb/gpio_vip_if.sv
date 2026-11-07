// =============================================================================
// GPIO VIP Interface: gpio_vip_if
// Connects to SoC 32-bit bidirectional GPIO bus (gpio_io[31:0])
// Supports individual pin driving and tri-state control
// =============================================================================

`ifndef GPIO_VIP_IF_SV
`define GPIO_VIP_IF_SV

interface gpio_vip_if (
  input logic clk,
  input logic rst_n
);
  wire [31:0] gpio_io;

  logic [31:0] drv_data = 32'h0;
  logic [31:0] drv_en   = 32'h0;

  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : gen_gpio_drv
      assign gpio_io[i] = drv_en[i] ? drv_data[i] : 1'bz;
    end
  endgenerate

  task drive_pins(input [31:0] data, input [31:0] mask);
    drv_data = data;
    drv_en   = mask;
  endtask

  task release_pins();
    drv_en = 32'h0;
  endtask

endinterface : gpio_vip_if

`endif // GPIO_VIP_IF_SV
