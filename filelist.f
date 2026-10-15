// =============================================================================
// Smart ControlSoC Filelist for VCS / QuestaSim / ModelSim
// =============================================================================

// Include Directories
+incdir+rtl/interconnect
+incdir+rtl/uart_directory/include
+incdir+rtl/spi_directory/include
+incdir+rtl/i2c_directory/rtl
+incdir+rtl/gpio_directory/include

// Interconnect
rtl/interconnect/arbiter.v
rtl/interconnect/priority_encoder.v
rtl/interconnect/axi_interconnect.v
rtl/interconnect/axi_interconnect_wrap_2x6.v

// UART Peripheral (Port M00: 0x2000_0000)
rtl/uart_directory/rtl/axi_internal_fifo.v
rtl/uart_directory/rtl/uart_parity_bit_compute.v
rtl/uart_directory/rtl/uart_receiver.v
rtl/uart_directory/rtl/uart_transmitter.v
rtl/uart_directory/rtl/uart_controller.v
rtl/uart_directory/rtl/axi_uart_top.v

// SPI Controller Peripheral (Port M03: 0x2000_3000)
rtl/spi_directory/rtl/ratio_clk.v
rtl/spi_directory/rtl/spi_clk_gen.v
rtl/spi_directory/rtl/spi_ctrl.v
rtl/spi_directory/rtl/spi_exch_byte.v
rtl/spi_directory/rtl/spi_fifo.v
rtl/spi_directory/rtl/spi_valid_logic.v
rtl/spi_directory/rtl/axi_spi_ctrl.v
rtl/spi_directory/rtl/axi_spi_top.v

// I2C Controller Peripheral (Port M04: 0x2000_4000)
rtl/i2c_directory/rtl/i2c_master_bit_ctrl.v
rtl/i2c_directory/rtl/i2c_master_byte_ctrl.v
rtl/i2c_directory/rtl/i2c_master_top.v
rtl/i2c_directory/rtl/axi_i2c_top.v

// PWM Generator Peripheral (Port M05: 0x2000_5000)
rtl/pwm_directory/rtl/myip_v1_0_S00_AXI.v
rtl/pwm_directory/rtl/myip_v1_0.v

// GPIO Peripheral (Port M02: 0x2000_2000)
rtl/gpio_directory/rtl/gpio_reg_pkg.sv
rtl/gpio_directory/rtl/gpio_reg_top.sv
rtl/gpio_directory/rtl/gpio_input_stage.sv
rtl/gpio_directory/rtl/gpio.sv
rtl/gpio_directory/rtl/axi_gpio_top.sv

// Top-Level SoC
rtl/smart_controlsoc_top.v
