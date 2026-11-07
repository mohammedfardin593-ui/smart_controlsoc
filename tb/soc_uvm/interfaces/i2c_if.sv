// =============================================================================
// Interface: i2c_if
// Peripheral: I2C Open-Drain Bus Interface for Smart Control SoC
// Signals match smart_controlsoc_top I2C external ports
// =============================================================================

`ifndef I2C_IF_SV
`define I2C_IF_SV

interface i2c_if (
    input logic clk,
    input logic rst_n
);
    wire  i2c_scl_io;
    wire  i2c_sda_io;
    logic i2c_interrupt_o;

    // Open-drain driver controls: drive 0 when active, release (z) for high
    logic scl_drv_low;
    logic sda_drv_low;

    assign i2c_scl_io = scl_drv_low ? 1'b0 : 1'bz;
    assign i2c_sda_io = sda_drv_low ? 1'b0 : 1'bz;

    // Clocking block for synchronous sampling
    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        input i2c_scl_io;
        input i2c_sda_io;
        input i2c_interrupt_o;
    endclocking

    modport tb (
        clocking cb,
        output   scl_drv_low,
        output   sda_drv_low,
        input    i2c_scl_io,
        input    i2c_sda_io,
        input    i2c_interrupt_o,
        input    clk,
        input    rst_n
    );

    modport dut (
        inout  i2c_scl_io,
        inout  i2c_sda_io,
        output i2c_interrupt_o,
        input  clk,
        input  rst_n
    );

endinterface : i2c_if

`endif // I2C_IF_SV
