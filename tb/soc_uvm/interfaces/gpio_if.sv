// =============================================================================
// Interface: gpio_if
// Peripheral: 32-bit Bidirectional GPIO Interface for Smart Control SoC
// Signals match smart_controlsoc_top GPIO external ports
// =============================================================================

`ifndef GPIO_IF_SV
`define GPIO_IF_SV

interface gpio_if (
    input logic clk,
    input logic rst_n
);
    wire  [31:0] gpio_io;
    logic        gpio_interrupt_o;

    // Testbench driver emulation controls to prevent contention
    logic [31:0] gpio_drv_val;
    logic [31:0] gpio_drv_en;

    assign gpio_io = gpio_drv_en ? gpio_drv_val : 32'bz;

    // Clocking block for synchronous sampling
    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        inout gpio_io;
        input gpio_interrupt_o;
    endclocking

    modport tb (
        clocking cb,
        output   gpio_drv_val,
        output   gpio_drv_en,
        input    gpio_io,
        input    gpio_interrupt_o,
        input    clk,
        input    rst_n
    );

    modport dut (
        inout  gpio_io,
        output gpio_interrupt_o,
        input  clk,
        input  rst_n
    );

endinterface : gpio_if

`endif // GPIO_IF_SV
