// =============================================================================
// Interface: pwm_if
// Peripheral: PWM Generator Output Interface for Smart Control SoC
// Signals match smart_controlsoc_top PWM external port
// =============================================================================

`ifndef PWM_IF_SV
`define PWM_IF_SV

interface pwm_if (
    input logic clk,
    input logic rst_n
);
    logic pwm_out_o;

    // Clocking block for synchronous duty-cycle sampling
    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        input pwm_out_o;
    endclocking

    modport tb (
        clocking cb,
        input    pwm_out_o,
        input    clk,
        input    rst_n
    );

    modport dut (
        output pwm_out_o,
        input  clk,
        input  rst_n
    );

endinterface : pwm_if

`endif // PWM_IF_SV
