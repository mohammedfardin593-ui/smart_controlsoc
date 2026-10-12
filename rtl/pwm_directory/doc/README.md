# AXI4-Lite-PWM-Controller-IP-Zynq-PYNQ-
A simple AXI4-Lite based PWM generator IP, controlled from Python on a PYNQ-Z2 (Zynq-7000) board using the PYNQ framework.\
\
**Features**/

- 32-bit AXI4-Lite slave interface (4-bit address).\
- Single PWM output: PWM_OUT.\
- 8-bit duty cycle control via AXI register slv_reg0[7:0].\
- Packaged as a custom Vivado IP and used in a block design.\
- Tested on PYNQ-Z2 with a Zynq-7000 device and PYNQ overlay.\


**RTL Overview**\
* 1.myip_v1_0.v 
  - Top-level IP wrapper. 
  - Exposes:
  - AXI slave port (S00_AXI interface).
  - PWM_OUT port.
  - Instantiates myip_v1_0_S00_AXI.

* 2.myip_v1_0_S00_AXI.v
  - AXI4-Lite register logic: slv_reg0–slv_reg3.
  - slv_reg0[7:0] used as duty_cycle.
  - 8-bit free-running counter pwm_counter.
  - PWM logic:\
  - Counter increments on S_AXI_ACLK when S_AXI_ARESETN is high.
  - PWM_OUT = (pwm_counter < duty_cycle).

    The PWM controller design was also verified by successfully programming and executing it on the PYNQ-Z2 platform, confirming proper functionality and expected operational behavior under hardware deployment conditions.\

    *Usage*
  - Copy pwm_test.bit to PYNQ board.
  - Run Python control script from Jupyter.
  - Observe PWM output on connected LED/pin.\
 
    An image of the working PYNC Z2 (ZYNC 7000 board) is attached below. \
    ![PYNQ-Z2 ](https://github.com/user-attachments/assets/a9f9d0b2-4a77-426f-bfa5-94c28aa17e53)


