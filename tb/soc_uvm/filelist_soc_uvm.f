// =============================================================================
// Smart ControlSoC - SoC-Level UVM Verification Filelist
// Dedicated filelist for VCS compilation of tb_soc_uvm_top
// Excludes all AES components per strict project scope limitations
// Integrates the 5 external peripheral interfaces from Smart_ControlSoC_Testplan.csv
// (UART, GPIO, I2C, SPI, PWM)
// =============================================================================

// Include Directories
+incdir+rtl/interconnect
+incdir+rtl/uart_directory/include
+incdir+rtl/spi_directory/include
+incdir+rtl/i2c_directory/rtl
+incdir+rtl/gpio_directory/include
+incdir+rtl/dma_directory/include
+incdir+rtl/dma_directory/rtl
+incdir+tb/uart.vip_uvm_tb
+incdir+tb/gpio.vip_uvm_tb
+incdir+tb/i2c.vip_uvm_tb
+incdir+tb/spi.vip_uvm_tb
+incdir+tb/pwm.vip_uvm_tb
+incdir+tb/soc_uvm
+incdir+tb/soc_uvm/interfaces

// OpenTitan Primitives & Common Cells
rtl/gpio_directory/include/reg_bus.sv
rtl/gpio_directory/include/common_cells/prim_subreg.sv
rtl/gpio_directory/include/common_cells/prim_subreg_ext.sv

// RISC-V VeeR EL2 Core Wrapper
rtl/Cores-VeeR-EL2/el2_veer_wrapper.v

// Interconnect Subsystem
rtl/interconnect/arbiter.v
rtl/interconnect/priority_encoder.v
rtl/interconnect/axi_interconnect.v
rtl/interconnect/axi_interconnect_wrap_2x6.v

// UART Peripheral (Port M00: 0x4000_0000)
rtl/uart_directory/rtl/axi_internal_fifo.v
rtl/uart_directory/rtl/uart_parity_bit_compute.v
rtl/uart_directory/rtl/uart_receiver.v
rtl/uart_directory/rtl/uart_transmitter.v
rtl/uart_directory/rtl/uart_controller.v
rtl/uart_directory/rtl/axi_uart_top.v

// Hardware Timer Peripheral (Port M01: 0x4000_4000)
rtl/timer_directory/rtl/timer_core.sv
rtl/timer_directory/rtl/axi_timer_top.sv

// SPI Controller Peripheral (Port M03: 0x4000_6000)
rtl/spi_directory/rtl/ratio_clk.v
rtl/spi_directory/rtl/spi_clk_gen.v
rtl/spi_directory/rtl/spi_ctrl.v
rtl/spi_directory/rtl/spi_exch_byte.v
rtl/spi_directory/rtl/spi_fifo.v
rtl/spi_directory/rtl/spi_valid_logic.v
rtl/spi_directory/rtl/axi_spi_ctrl.v
rtl/spi_directory/rtl/axi_spi_top.v

// I2C Controller Peripheral (Port M04: 0x4000_8000)
rtl/i2c_directory/rtl/i2c_master_bit_ctrl.v
rtl/i2c_directory/rtl/i2c_master_byte_ctrl.v
rtl/i2c_directory/rtl/i2c_master_top.v
rtl/i2c_directory/rtl/axi_i2c_top.v
rtl/i2c_directory/tb/i2c_slave_model.v

// PWM Generator Peripheral (Port M05: 0x4000_A000)
rtl/pwm_directory/rtl/myip_v1_0_S00_AXI.v
rtl/pwm_directory/rtl/myip_v1_0.v

// GPIO Peripheral (Port M02: 0x4000_2000)
rtl/gpio_directory/rtl/gpio_reg_pkg.sv
rtl/gpio_directory/rtl/gpio_reg_top.sv
rtl/gpio_directory/rtl/gpio_input_stage.sv
rtl/gpio_directory/rtl/gpio.sv
rtl/gpio_directory/rtl/axi_gpio_top.sv

// Direct Memory Access (DMA) Subsystem
rtl/dma_directory/include/amba_axi_pkg.sv
rtl/dma_directory/include/dma_utils_pkg.sv
rtl/dma_directory/rtl/rggen_adapter_common.v
rtl/dma_directory/rtl/rggen_address_decoder.v
rtl/dma_directory/rtl/rggen_axi4lite_adapter.v
rtl/dma_directory/rtl/rggen_axi4lite_bridge.v
rtl/dma_directory/rtl/rggen_axi4lite_skid_buffer.v
rtl/dma_directory/rtl/rggen_bit_field.v
rtl/dma_directory/rtl/rggen_bit_field_w01trg.v
rtl/dma_directory/rtl/rggen_default_register.v
rtl/dma_directory/rtl/rggen_external_register.v
rtl/dma_directory/rtl/rggen_indirect_register.v
rtl/dma_directory/rtl/rggen_mux.v
rtl/dma_directory/rtl/rggen_or_reducer.v
rtl/dma_directory/rtl/rggen_register_common.v
rtl/dma_directory/rtl/csr_dma.v
rtl/dma_directory/rtl/dma_fifo.sv
rtl/dma_directory/rtl/dma_streamer.sv
rtl/dma_directory/rtl/dma_fsm.sv
rtl/dma_directory/rtl/dma_axi_if.sv
rtl/dma_directory/rtl/dma_func_wrapper.sv
rtl/dma_directory/rtl/dma_axi_wrapper.sv
rtl/dma_directory/rtl/axi_dma_top.sv

// Top-Level SoC RTL (Module: smart_controlsoc_top)
rtl/smart_controlsoc_top.v

// SoC Interface Files
tb/soc_uvm/interfaces/uart_if.sv
tb/soc_uvm/interfaces/gpio_if.sv
tb/soc_uvm/interfaces/i2c_if.sv
tb/soc_uvm/interfaces/spi_if.sv
tb/soc_uvm/interfaces/pwm_if.sv
tb/soc_uvm/interfaces/cpu_bfm_if.sv

// Reused Peripheral VIP Interfaces & Packages (5 External Interfaces)
tb/uart.vip_uvm_tb/uart_vip_if.sv
tb/uart.vip_uvm_tb/uart_vip_pkg.sv
tb/gpio.vip_uvm_tb/gpio_vip_if.sv
tb/gpio.vip_uvm_tb/gpio_vip_pkg.sv
tb/i2c.vip_uvm_tb/i2c_vip_if.sv
tb/i2c.vip_uvm_tb/i2c_vip_pkg.sv
tb/spi.vip_uvm_tb/spi_vip_if.sv
tb/spi.vip_uvm_tb/spi_vip_pkg.sv
tb/pwm.vip_uvm_tb/pwm_vip_if.sv
tb/pwm.vip_uvm_tb/pwm_vip_pkg.sv

// SoC-Level UVM Verification Package
tb/soc_uvm/soc_uvm_pkg.sv

// SoC-Level UVM Top Testbench
tb/soc_uvm/tb_soc_uvm_top.sv
