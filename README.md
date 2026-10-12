# RISC-V VeeR EL2 Based Smart Peripheral Control SoC

![SoC Architecture](doc/AXI4-Lite%20Smart%20Peripheral%20SoC%20Block%20Diagram.png)

[![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32IMC-blue.svg)](#)
[![Interconnect](https://img.shields.io/badge/Interconnect-AXI4--Lite%20(2x6)-orange.svg)](#)
[![Verification](https://img.shields.io/badge/Simulation-Synopsys%20VCS%20%2F%20Verdi-purple.svg)](#)
[![Status](https://img.shields.io/badge/Project%20Status-Active%20Integration-brightgreen.svg)](#)

---

## 1. Executive Summary & Project Overview

The **RISC-V VeeR EL2 Based Smart Peripheral Control SoC** is a modular, high-performance, peripheral-oriented System-on-Chip (SoC) designed for real-time embedded control, industrial monitoring, and multi-protocol hardware interfacing.

At the core of the SoC is the Western Digital / CHIPS Alliance **VeeR EL2**, a dual-issue, 4-stage pipelined 32-bit RISC-V processor supporting the **RV32IMC** instruction set architecture. The processor connects through core-local tightly-coupled memories (**ICCM** for instructions and **DCCM** for data) for deterministic single-cycle execution, while system-level peripheral access is managed across an optimized **AXI4-Lite 2x6 Shared Interconnect**.

### Key Architectural Highlights
* **Processing Core:** 32-bit RISC-V VeeR EL2 (RV32IMC) core with Load-Store Unit (LSU) AXI interface.
* **Bus Architecture:** 2-Master $\times$ 6-Slave AXI4-Lite Crossbar Interconnect with round-robin arbitration, independent address decoding, and memory-mapped register access.
* **Integrated Communication Peripherals:** High-speed UART with FIFO buffering, SPI Controller with configurable clock divider, and I²C Master Controller with open-drain buffers.
* **Control Output Peripherals:** 8-bit programmable PWM generator for precision motor and power regulation.
* **Interrupt Management:** Centralized event routing to the Programmable Interrupt Controller (PIC).
* **System Verification:** Comprehensive SystemVerilog testbench (`tb_smart_controlsoc_top.sv`) with true AXI Master protocol BFM, automated pass/fail assertion monitors, and Synopsys FSDB waveform generation.

---

## 2. System Architecture & Interconnect Topology

The SoC employs a decoupled memory and control path topology:
1. **Core-Local Execution Path:** Instruction fetching (IFU) and local stack/data accesses (LSU) are handled via internal ICCM and DCCM, eliminating bus contention during normal code execution.
2. **Peripheral MMIO Path:** When the CPU performs loads or stores targeting peripheral memory regions (`0x2000_0000` - `0x2000_5FFF`), the LSU routes transactions across the AXI4-Lite system interconnect.
3. **Interrupt Feedback:** Asynchronous and synchronous peripheral events trigger dedicated interrupt lines aggregated by the interrupt controller.

```
+-----------------------------------------------------------------------------------+
|                              SMART CONTROLSOC TOP                                 |
|                                                                                   |
|  +--------------------+         +----------------------------------------------+  |
|  |  RISC-V VeeR EL2   |  (S00)  |               AXI4-Lite                      |  |
|  |     CPU (LSU)      | =======>|            Interconnect (2x6)                |  |
|  +--------------------+         +----------------------------------------------+  |
|                                        ||          ||          ||          ||     |
|  +--------------------+  (S01)         || (M00)    || (M03)    || (M04)    ||(M05)|
|  |   DMA Controller   | - - - - >      \/          \/          \/          \/     |
|  |     (Reserved)     |         +----------++----------++----------++----------+  |
|  +--------------------+         | AXI UART || AXI SPI  || AXI I2C  || AXI PWM  |  |
|                                 +----------++----------++----------++----------+  |
|                                      ||          ||          ||          ||       |
+--------------------------------------||----------||----------||----------||-------+
                                       \/          \/          \/          \/
                                    [Serial]     [SPI Bus]   [I2C Bus]  [PWM Pin]
```

---

## 3. Hardware Implementation Status

| Subsystem / IP Core | Type | Interconnect Port | Memory Base Address | Address Range | Status | Testbench Coverage |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **VeeR EL2 Core** | Master | Port `S00` | — | Internal | **Integrated** | LSU Master Driven |
| **DMA Controller** | Master | Port `S01` | — | Internal | *Reserved* | Cleanly Tied Off |
| **UART IP Core** | Slave | Port `M00` | `0x2000_0000` | 4 KB (`0x2000_0FFF`) | **Integrated** | Tests 1 – 6 (Pass) |
| **Timer IP** | Slave | Port `M01` | `0x2000_1000` | 4 KB (`0x2000_1FFF`) | *Next Phase* | Cleanly Tied Off |
| **GPIO Controller** | Slave | Port `M02` | `0x2000_2000` | 4 KB (`0x2000_2FFF`) | *Next Phase* | Cleanly Tied Off |
| **SPI Controller** | Slave | Port `M03` | `0x2000_3000` | 4 KB (`0x2000_3FFF`) | **Integrated** | Test 7 (Pass) |
| **I²C Controller** | Slave | Port `M04` | `0x2000_4000` | 4 KB (`0x2000_4FFF`) | **Integrated** | Test 9 (Pass) |
| **PWM Generator** | Slave | Port `M05` | `0x2000_5000` | 4 KB (`0x2000_5FFF`) | **Integrated** | Test 8 (Pass) |

---

## 4. Memory Map & Peripheral Register Definitions

Each peripheral occupies an aligned 4 KB address window within the system peripheral space (`0x2000_0000` – `0x2000_5FFF`):

### 4.1 UART (Base: `0x2000_0000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00` | `UART_RBR` / `UART_THR` | R / W | Receiver Buffer Register / Transmitter Holding Register |
| `0x04` | `UART_IER` | R/W | Interrupt Enable Register |
| `0x08` | `UART_BAUD_DIV` | R/W | Baud Rate Divisor Generator Register |
| `0x0C` | `UART_LCR` | R/W | Line Control Register (DLAB, Parity, Stop Bits, Word Length) |
| `0x14` | `UART_LSR` | R | Line Status Register (TX Empty, RX Data Ready) |

### 4.2 SPI Controller (Base: `0x2000_3000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x30` | `SPI_RCLK` | R/W | SPI Clock Ratio Register |
| `0x40` | `SPI_SRR` | W | Software Reset Register (`0x0A` triggers soft reset) |
| `0x60` | `SPI_CR` | R/W | SPI Control Register (Master Mode, Clock Phase/Polarity, Enable) |
| `0x64` | `SPI_SR` | R | SPI Status Register (TX/RX FIFO Empty and Full Flags) |
| `0x68` | `SPI_DTR` | W | Data Transmit Register (Pushes byte into TX FIFO) |
| `0x6C` | `SPI_DRR` | R | Data Receive Register (Pops byte from RX FIFO) |
| `0x70` | `SPI_SSR` | R/W | Slave Select Register |

### 4.3 I²C Controller (Base: `0x2000_4000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00` | `I2C_PRER_LO` | R/W | Clock Prescale Register (Low byte) |
| `0x04` | `I2C_PRER_HI` | R/W | Clock Prescale Register (High byte) |
| `0x08` | `I2C_CTR` | R/W | Control Register (Bit 7: Core Enable, Bit 6: Interrupt Enable) |
| `0x0C` | `I2C_TXR_RXR` | W / R | Transmit Data Register / Receive Data Register |
| `0x10` | `I2C_CR_SR` | W / R | Command Register / Status Register |

### 4.4 PWM Generator (Base: `0x2000_5000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00` | `PWM_DUTY_REG` | R/W | 8-Bit Duty Cycle Register (`0x00` = 0%, `0x80` = 50%, `0xFF` = 100%) |

---

## 5. Directory Structure

```
smart_controlsoc/
├── doc/                                   # Architectural specifications & diagram assets
│   ├── AXI4-Lite Smart Peripheral SoC Block Diagram.png
│   ├── honours_architecture_AXI4_Lite.docx
│   ├── honours_signal_list_AXI_path.docx
│   └── honours_system_specifications_AXI4_Lite.docx
├── rtl/
│   ├── Cores-VeeR-EL2/                    # RISC-V VeeR EL2 CPU core repository
│   ├── interconnect/                      # AXI4-Lite Crossbar Interconnect
│   │   ├── arbiter.v                      # Round-robin bus arbiter
│   │   ├── axi_interconnect.v             # AXI crossbar core
│   │   ├── axi_interconnect_wrap_2x6.v    # 2-Master x 6-Slave interconnect wrapper
│   │   └── priority_encoder.v             # Interconnect priority encoder
│   ├── uart_directory/                    # AXI4-Lite UART IP Core
│   │   ├── doc/                           # UART register documentation
│   │   ├── include/                       # Header definitions
│   │   ├── rtl/                           # Transmitter, Receiver, Baud Generator, Controller
│   │   └── tb/                            # Unit testbenches
│   ├── spi_directory/                     # AXI4-Lite SPI IP Core
│   │   ├── doc/                           # SPI diagrams and specifications
│   │   ├── include/                       # axi_spi.vh, axi_spi_defines.vh
│   │   └── rtl/                           # Clock ratio generator, FIFO, Controller, Top
│   ├── i2c_directory/                     # AXI4-Lite I2C Master IP Core
│   │   ├── doc/                           # OpenCores I2C specifications
│   │   ├── rtl/                           # Bit controller, Byte controller, and AXI bridge
│   │   └── tb/                            # I2C verification models
│   ├── pwm_directory/                     # AXI4-Lite PWM Generator IP Core
│   │   ├── doc/                           # PWM IP README
│   │   ├── rtl/                           # myip_v1_0.v, myip_v1_0_S00_AXI.v
│   │   └── scripts/                       # PYNQ control scripts
│   ├── smart_controlsoc_top.v             # Top-Level SoC Integration Module
├── tb/
│   └── tb_smart_controlsoc_top.sv         # System-Level Verification Testbench
└── README.md                              # Project documentation & status report
```

---

## 6. Verification & Test Suite

The system is verified using **`tb/tb_smart_controlsoc_top.sv`**, a self-contained SystemVerilog testbench equipped with an **AXI4-Lite Master Bus Functional Model (BFM)** that drives protocol-compliant transactions into the system interconnect without requiring external simulation dependencies.

### Verification Coverage Matrix
* **`TEST 1: Reset & Default Pin Verification`**
  * Verifies reset assertion across all sub-modules; asserts `uart_tx_o` idle high state.
* **`TEST 2: UART Line & Baud Rate Configuration`**
  * Programs DLAB=1, configures fast simulation divisor (40 clock cycles per bit), enables RX interrupts.
* **`TEST 3: UART Single Byte Transmission`**
  * Writes ASCII character `'A'` (`0x41`) via MMIO; serial frame monitor captures and verifies start, 8 data bits, and stop bit on `uart_tx_o`.
* **`TEST 4: UART Multi-Byte String Burst`**
  * Streams string `"RISCV"` sequentially across the AXI interconnect and verifies serial reception.
* **`TEST 5: External Host UART RX & Interrupt Servicing`**
  * Host model transmits byte `0x5A` into `uart_rx_i`; verifies push to RX FIFO, interrupt assertion on `uart_interrupt_o`, and interrupt de-assertion upon CPU read of `UART_RBR`.
* **`TEST 6: UART Full-Duplex Bidirectional Operation`**
  * Executes simultaneous transmission and reception over UART channels.
* **`TEST 7: SPI Controller Verification`**
  * Reads default `SPI_SR` (`0x0000_00A5`), asserts TX & RX empty flags; programs `SPI_CR` for Master Mode and SPI Enable; writes byte `0xA5` to `SPI_DTR` and verifies serial clock activation.
* **`TEST 8: PWM Generator Verification`**
  * Reads default duty cycle (0%); programs 50% duty cycle (`0x80`); monitors counter toggling on `pwm_out_o`.
* **`TEST 9: I²C Controller Verification`**
  * Reads default prescaler (`0xFF`); programs prescaler to `0x64`; enables core via `I2C_CTR`; verifies open-drain pull-ups on `i2c_scl_io` and `i2c_sda_io`.

---

## 7. How to Run Simulation

### 7.1 Using Synopsys VCS & Verdi (Recommended)
```bash
# Compile and simulate with SystemVerilog and FSDB dumping enabled
vcs -sverilog -timescale=1ns/1ps \
    +incdir+rtl/interconnect \
    +incdir+rtl/uart_directory/include \
    +incdir+rtl/spi_directory/include \
    +incdir+rtl/i2c_directory/rtl \
    +define+FSDB \
    -f filelist.f \
    tb/tb_smart_controlsoc_top.sv -o simv

# Run the simulation executable
./simv

# View waveforms in Verdi
verdi -ssf smart_controlsoc.fsdb &
```

### 7.2 Using Mentor QuestaSim / ModelSim
```bash
vlib work
vlog -sv +incdir+rtl/interconnect +incdir+rtl/uart_directory/include +incdir+rtl/spi_directory/include +incdir+rtl/i2c_directory/rtl \
    rtl/interconnect/*.v \
    rtl/uart_directory/rtl/*.v \
    rtl/spi_directory/rtl/*.v \
    rtl/i2c_directory/rtl/*.v \
    rtl/pwm_directory/rtl/*.v \
    rtl/smart_controlsoc_top.v \
    tb/tb_smart_controlsoc_top.sv

vsim -c -do "run -all; quit" work.tb_smart_controlsoc_top
```

---

## 8. Next Milestones

1. **Phase 4: Remaining Peripheral Integration**
   * Integrate 32-bit hardware **Timer IP** into Master Port 1 (`m01` at `0x2000_1000`).
   * Integrate bidirectional **GPIO Controller** into Master Port 2 (`m02` at `0x2000_2000`).
2. **Phase 5: Centralized Interrupt Routing**
   * Connect interrupt request outputs (`uart_interrupt_o`, `spi_irq`, `i2c_interrupt_o`, `timer_irq`, `gpio_irq`) into the VeeR EL2 Programmable Interrupt Controller (PIC).
3. **Phase 6: Software Firmware & Drivers**
   * Compile bare-metal C device drivers using `riscv64-unknown-elf-gcc`.
   * Load software `.hex` directly into the CPU Instruction Memory (ICCM) for end-to-end firmware-driven SoC verification.
