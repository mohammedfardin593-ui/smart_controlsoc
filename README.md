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
2. **Peripheral MMIO Path:** When the CPU performs loads or stores targeting peripheral memory regions (`0x4000_0000` - `0x4000_CFFF`), the LSU routes transactions across the AXI4-Lite system interconnect.
3. **Interrupt Feedback:** Asynchronous and synchronous peripheral events trigger dedicated interrupt lines aggregated by the interrupt controller.

```
+---------------------------------------------------------------------------------------------------------------+
|                                             SMART CONTROLSOC TOP                                              |
|                                                                                                               |
|  +--------------------+         +--------------------------------------------------------------------------+  |
|  |  RISC-V VeeR EL2   |  (S00)  |                                AXI4-Lite                                 |  |
|  |     CPU (LSU)      | =======>|                            Interconnect (2x6)                            |  |
|  +--------------------+         +--------------------------------------------------------------------------+  |
|                                        ||          ||          ||          ||          ||          ||         |
|  +--------------------+  (S01)         || (M00)    || (M01)    || (M02)    || (M03)    || (M04)    || (M05)   |
|  |   DMA Controller   | =======>       \/          \/          \/          \/          \/          \/         |
|  |     Bus Master     |         +----------++----------++----------++----------++----------++----------+      |
|  +--------------------+         | AXI UART || AXI Timer|| AXI GPIO || AXI SPI  || AXI I2C  || AXI PWM  |      |
|                                 +----------++----------++----------++----------++----------++----------+      |
|                                      ||          ||          ||          ||          ||          ||           |
+--------------------------------------||----------||----------||----------||----------||----------||-----------+
                                       \/          \/          \/          \/          \/          \/
                                    [Serial]   [Timer IRQ] [32x GPIO]   [SPI Bus]   [I2C Bus]   [PWM Pin]
```

---

## 3. Hardware Implementation Status

| Subsystem / IP Core | Type | Interconnect Port | Memory Base Address | Address Range | Status | Testbench Coverage |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **VeeR EL2 Core** | Master | Port `S00` | — | Internal | **Integrated** | LSU Master Driven |
| **DMA Controller** | Master | Port `S01` | — | Interconnect Master | **Integrated** | Test 12 (Pass) |
| **DMA CSR Port** | Slave | Dedicated Port | `0x4000_C000` | 4 KB (`0x4000_C000` – `0x4000_CFFF`) | **Integrated** | Test 12 (Pass) |
| **UART IP Core** | Slave | Port `M00` | `0x4000_0000` | 4 KB (`0x4000_0000` – `0x4000_0FFF`) | **Integrated** | Tests 1 – 6 (Pass) |
| **Timer IP** | Slave | Port `M01` | `0x4000_4000` | 4 KB (`0x4000_4000` – `0x4000_4FFF`) | **Integrated** | Test 11 (Pass) |
| **GPIO Controller** | Slave | Port `M02` | `0x4000_2000` | 4 KB (`0x4000_2000` – `0x4000_2FFF`) | **Integrated** | Test 10 (Pass) |
| **SPI Controller** | Slave | Port `M03` | `0x4000_6000` | 4 KB (`0x4000_6000` – `0x4000_6FFF`) | **Integrated** | Test 7 (Pass) |
| **I²C Controller** | Slave | Port `M04` | `0x4000_8000` | 4 KB (`0x4000_8000` – `0x4000_8FFF`) | **Integrated** | Test 9 (Pass) |
| **PWM Generator** | Slave | Port `M05` | `0x4000_A000` | 4 KB (`0x4000_A000` – `0x4000_AFFF`) | **Integrated** | Test 8 (Pass) |

> **Note on Team Memory Mapping:** Each peripheral occupies a 4 KB window with 4 KB reserved buffer zones interleaved between them, fully matching `/home/student/Documents/153/Address_mapping.ods`.

---

## 4. Memory Map & Peripheral Register Definitions

Each peripheral occupies an aligned 4 KB address window within the system peripheral space (`0x4000_0000` – `0x4000_CFFF`):

### 4.1 UART (Base: `0x4000_0000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00` | `UART_RBR` / `UART_THR` | R / W | Receiver Buffer Register / Transmitter Holding Register |
| `0x04` | `UART_IER` | R/W | Interrupt Enable Register |
| `0x08` | `UART_BAUD_DIV` | R/W | Baud Rate Divisor Generator Register |
| `0x0C` | `UART_LCR` | R/W | Line Control Register (DLAB, Parity, Stop Bits, Word Length) |
| `0x14` | `UART_LSR` | R | Line Status Register (TX Empty, RX Data Ready) |

### 4.2 Hardware Timer (Base: `0x4000_4000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x000` | `ALERT_TEST` | WO | Alert test register (Write 1 to trigger alert test event) |
| `0x004` | `TIMER_CTRL` | R/W | Timer Control (Bit 0: `active` counter enable) |
| `0x100` | `TIMER_INTR_ENABLE0` | R/W | Timer Interrupt Enable Mask (Bit 0: Enable interrupt on compare match) |
| `0x104` | `TIMER_INTR_STATE0` | W1C | Timer Interrupt Status (Bit 0: Interrupt pending flag; write 1 to clear) |
| `0x108` | `TIMER_INTR_TEST0` | WO | Software Interrupt Test Force (Bit 0: Force interrupt for testing) |
| `0x10C` | `TIMER_CFG0` | R/W | Timer Configuration (Bits [11:0]: 12-bit Prescaler, Bits [23:16]: 8-bit Step Value) |
| `0x110` | `TIMER_V_LOWER0` | R/W | 64-bit Real-Time Counter `mtime` [31:0] (Read current value / Write counter) |
| `0x114` | `TIMER_V_UPPER0` | R/W | 64-bit Real-Time Counter `mtime` [63:32] |
| `0x118` | `TIMER_COMPARE_LOWER0`| R/W | 64-bit Compare Threshold `mtimecmp` [31:0] |
| `0x11C` | `TIMER_COMPARE_UPPER0`| R/W | 64-bit Compare Threshold `mtimecmp` [63:32] |

### 4.3 GPIO Controller (Base: `0x4000_2000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x000` | `GPIO_INFO` | RO | Hardware Version (Bits 19:10 = 2) & Pin Count (Bits 9:0 = 32) -> Reset: `0x0000_0820` |
| `0x004` | `GPIO_CFG` | R/W | Global Configuration (Bit 0: Global Interrupt Mode, Bit 1: Pin-Level Interrupt Mode) |
| `0x008` | `GPIO_MODE_0` | R/W | IO Mode for Pins 0–15 (2 bits/pin: 0=Input, 1=Push-Pull, 2=OpenDrain0, 3=OpenDrain1) |
| `0x00C` | `GPIO_MODE_1` | R/W | IO Mode for Pins 16–31 (2 bits/pin) |
| `0x080` | `GPIO_EN` | R/W | Input Sampling Enable Mask for Pins 0–31 (1 = Sample Enabled) |
| `0x100` | `GPIO_IN` | RO | Synchronized Pin Input State Read Register |
| `0x180` | `GPIO_OUT` | R/W | Direct Output State Register |
| `0x200` | `GPIO_SET` | WO | Atomic Output Bit Set Register (Write 1 to set corresponding pin) |
| `0x280` | `GPIO_CLEAR` | WO | Atomic Output Bit Clear Register (Write 1 to clear corresponding pin) |
| `0x300` | `GPIO_TOGGLE` | WO | Atomic Output Bit Toggle Register (Write 1 to invert corresponding pin) |
| `0x380` | `GPIO_INTRPT_RISE_EN` | R/W | Rising Edge Interrupt Enable Mask |
| `0x400` | `GPIO_INTRPT_FALL_EN` | R/W | Falling Edge Interrupt Enable Mask |
| `0x480` | `GPIO_INTRPT_LVL_HIGH_EN` | R/W | Level-Sensitive High Interrupt Enable Mask |
| `0x500` | `GPIO_INTRPT_LVL_LOW_EN` | R/W | Level-Sensitive Low Interrupt Enable Mask |
| `0x580` | `GPIO_INTRPT_STATUS` | W1C | Aggregated Interrupt Status Register (Write 1 to clear pending interrupt) |

### 4.4 SPI Controller (Base: `0x4000_6000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x30` | `SPI_RCLK` | R/W | SPI Clock Ratio Register |
| `0x40` | `SPI_SRR` | W | Software Reset Register (`0x0A` triggers soft reset) |
| `0x60` | `SPI_CR` | R/W | SPI Control Register (Master Mode, Clock Phase/Polarity, Enable) |
| `0x64` | `SPI_SR` | R | SPI Status Register (TX/RX FIFO Empty and Full Flags) |
| `0x68` | `SPI_DTR` | W | Data Transmit Register (Pushes byte into TX FIFO) |
| `0x6C` | `SPI_DRR` | R | Data Receive Register (Pops byte from RX FIFO) |
| `0x70` | `SPI_SSR` | R/W | Slave Select Register |

### 4.5 I²C Controller (Base: `0x4000_8000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00` | `I2C_PRER_LO` | R/W | Clock Prescale Register (Low byte) |
| `0x04` | `I2C_PRER_HI` | R/W | Clock Prescale Register (High byte) |
| `0x08` | `I2C_CTR` | R/W | Control Register (Bit 7: Core Enable, Bit 6: Interrupt Enable) |
| `0x0C` | `I2C_TXR_RXR` | W / R | Transmit Data Register / Receive Data Register |
| `0x10` | `I2C_CR_SR` | W / R | Command Register / Status Register |

### 4.6 PWM Generator (Base: `0x4000_A000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00` | `PWM_DUTY_REG` | R/W | 8-Bit Duty Cycle Register (`0x00` = 0%, `0x80` = 50%, `0xFF` = 100%) |

### 4.7 DMA Controller CSR Port (Base: `0x4000_C000`)
| Offset | Register Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00` | `DMA_CONTROL` | R/W | Control: [0] GO, [1] ABORT, [9:2] MAX_BURST |
| `0x08` | `DMA_STATUS` | RO | Status: [15:0] Version (0xCAFE), [16] DONE, [17] ERROR |
| `0x10` | `DMA_ERROR_ADDR` | RO | Error Address Register |
| `0x18` | `DMA_ERROR_STATS`| RO | Error Statistics |
| `0x20` | `DMA_DESC0_SRC` | R/W | Descriptor 0 Source Address |
| `0x28` | `DMA_DESC1_SRC` | R/W | Descriptor 1 Source Address |
| `0x30` | `DMA_DESC0_DST` | R/W | Descriptor 0 Destination Address |
| `0x38` | `DMA_DESC1_DST` | R/W | Descriptor 1 Destination Address |
| `0x40` | `DMA_DESC0_LEN` | R/W | Descriptor 0 Byte Count |
| `0x48` | `DMA_DESC1_LEN` | R/W | Descriptor 1 Byte Count |
| `0x50` | `DMA_DESC0_CFG` | R/W | Descriptor 0 Config: [0] EN, [1] RD_MODE (0:INC, 1:FIX), [2] WR_MODE |

---

## 5. Directory Structure

```
smart_controlsoc/
├── doc/                                   # Architectural specifications & diagram assets
│   ├── AXI4-Lite Smart Peripheral SoC Block Diagram.png
│   ├── Smart_ControlSoC_Testplan.csv      # UVM & SystemVerilog Comprehensive Verification Test Plan
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
│   ├── timer_directory/                   # 64-bit Real-Time Hardware Timer IP (Port M01)
│   │   ├── doc/                           # Register spec, theory of operation, block diagram
│   │   ├── rtl/                           # axi_timer_top.sv, timer_core.sv
│   │   └── tb/                            # Standalone timer unit testbench
│   ├── gpio_directory/                    # AXI4-Lite GPIO IP Core (Port M02)
│   │   ├── doc/                           # Register spec (gpio_regs.hjson), changelog, README
│   │   ├── include/                       # Register interface & assertion headers
│   │   ├── rtl/                           # axi_gpio_top, gpio, gpio_reg_top, gpio_input_stage
│   │   └── tb/                            # Standalone GPIO unit testbench
│   ├── spi_directory/                     # AXI4-Lite SPI IP Core (Port M03)
│   │   ├── doc/                           # SPI diagrams and specifications
│   │   ├── include/                       # axi_spi.vh, axi_spi_defines.vh
│   │   └── rtl/                           # Clock ratio generator, FIFO, Controller, Top
│   ├── i2c_directory/                     # AXI4-Lite I2C Master IP Core (Port M04)
│   │   ├── doc/                           # OpenCores I2C specifications
│   │   ├── rtl/                           # Bit controller, Byte controller, and AXI bridge
│   │   └── tb/                            # I2C verification models
│   ├── pwm_directory/                     # AXI4-Lite PWM Generator IP Core (Port M05)
│   │   ├── doc/                           # PWM IP README
│   │   ├── rtl/                           # myip_v1_0.v, myip_v1_0_S00_AXI.v
│   │   └── scripts/                       # PYNQ control scripts
│   ├── smart_controlsoc_top.v             # Top-Level SoC Integration Module
├── tb/
│   └── tb_smart_controlsoc_top.sv         # System-Level Verification Testbench
├── filelist.f                             # Unified VCS / QuestaSim simulation filelist
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
* **`TEST 10: GPIO Controller Verification`**
  * Reads `GPIO_INFO` register (`0x4000_2000`) and asserts HW Version 2 and 32-pin count (`0x0000_0820`).
  * Programs `GPIO_MODE_0` (`0x4000_2008`) to set Pin 0 as active Push-Pull Output (`2'b01`).
  * Drives Pin 0 HIGH via `GPIO_OUT` (`0x4000_2180`) and validates `gpio_io[0] == 1'b1`.
  * Tests atomic bit clearing via `GPIO_CLEAR` (`0x4000_2280`) and validates `gpio_io[0] == 1'b0`.
  * Tests atomic bit setting via `GPIO_SET` (`0x4000_2200`) and validates `gpio_io[0] == 1'b1`.
  * Tests atomic bit toggling via `GPIO_TOGGLE` (`0x4000_2300`) to LOW then HIGH.
  * Configures Pin 1 as input, enables sampling mask in `GPIO_EN` (`0x4000_2080`), drives external testbench stimulus and validates synchronized readback in `GPIO_IN` (`0x4000_2100`).
  * Configures sticky interrupt mode via `GPIO_CFG` (`0x4000_2004`), enables rising-edge interrupt via `GPIO_INTRPT_RISE_EN` (`0x4000_2380`), verifies `gpio_interrupt_o` assertion and `GPIO_INTRPT_STATUS` (`0x4000_2580`) register update, and tests interrupt de-assertion via Write-1-to-Clear (W1C).
* **`TEST 11: Hardware Timer Verification`**
  * Reads and validates default reset state of `TIMER_CTRL` (`0x00`), `TIMER_V_LOWER0` (`0x00`), and `TIMER_CFG0` (`0x0001_0000`, step=1).
  * Programs prescaler to 0 and step to 1 via `TIMER_CFG0` (`0x4000_410C`).
  * Enables timer (`TIMER_CTRL` active=1) and verifies real-time counter incrementing across cycles via `TIMER_V_LOWER0` (`0x4000_4110`).
  * Programs 64-bit compare threshold (`TIMER_COMPARE_LOWER0` = `0x4000_4118`), unmasks interrupt (`TIMER_INTR_ENABLE0` = `0x4000_4100`), and verifies comparator match triggering interrupt assertion on `timer_interrupt_o` and pending status in `TIMER_INTR_STATE0` (`0x4000_4104`).
  * De-asserts interrupt by issuing Write-1-to-Clear (W1C) to `TIMER_INTR_STATE0` and validates `timer_interrupt_o == 1'b0`.
  * Tests software forced interrupt triggering via `TIMER_INTR_TEST0` (`0x4000_4108`).
* **`TEST 12: DMA Autonomous Interconnect Transfer (S01 Bus Master)`**
  * Reads DMA CSR `DMA_STATUS` (`0x4000_C008`) and validates hardware version signature `0xCAFE`.
  * Writes test data (`0x1234_5678`) to PWM duty cycle register and clears `GPIO_OUT` (`0x4000_2180`).
  * Programs DMA Descriptor 0 via dedicated CSR port (Source: PWM, Destination: `GPIO_OUT`, Length: 4 bytes, Mode: FIXED-to-FIXED).
  * Triggers autonomous transfer via `DMA_CONTROL` GO bit (`0x4000_C000 = 0x05`).
  * Asserts autonomous transaction capture on Interconnect Port S01 (`s01_axi_*`), waits for `dma_done_interrupt_o`, and verifies `GPIO_OUT == 0x1234_5678`.
* **`TEST 13: Executing C Program Firmware Transactions (main1.hex)`**
  * Loads and streams 74 MMIO transactions generated from `sw/main1.c`.
  * Exercises all 6 peripherals, DMA descriptors, and multi-master cross-routing isolation tests (`0xDEADBEEF`, `0x5A5A5A5A`).
  * Asserts 100% data readback match across all MMIO registers.

### 6.1 UVM & SystemVerilog Test Plan
For detailed verification architecture, test intent, C firmware procedures, and UVM monitor/scoreboard checkpoints, refer to the unified test plan spreadsheet:
* 📄 **[Smart_ControlSoC_Testplan.csv](doc/Smart_ControlSoC_Testplan.csv)** (26 comprehensive testcases across Boot, UART, Timer, GPIO, SPI, I2C, PWM, DMA, Pipeline, Bus Stress, and Full Regression).

---

## 7. How to Run Simulation

### 7.1 Using Synopsys VCS & Verdi (Recommended)
```bash
# Compile and simulate with SystemVerilog and FSDB dumping enabled
vcs -sverilog -timescale=1ns/1ps \
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
vlog -sv -mfcu -f filelist.f tb/tb_smart_controlsoc_top.sv
vsim -c -do "run -all; quit" work.tb_smart_controlsoc_top
```

---

## 8. Project Roadmap & Pending Deliverables

This section details the remaining engineering phases, pending hardware integrations, software deliverables, and physical implementation goals required to achieve complete project closure.

```
+--------------------------------------------------------------------------------------------------------+
|                                  SoC DEVELOPMENT PROGRESS TRACKER                                       |
+--------------------------------------------------------------------------------------------------------+
|  Phase 1: Architecture Design & AXI Interconnect Setup      | [####################] 100% | COMPLETED  |
|  Phase 2: Communication & Control IP Integration (4 of 6)    | [####################] 100% | COMPLETED  |
|  Phase 3: Peripheral Integration (Timer & GPIO Completed)   | [####################] 100% | COMPLETED  |
|  Phase 4: Interrupt Aggregation & PIC Routing               | [                    ]   0% | PENDING    |
|  Phase 5: DMA Bus Master Integration                        | [                    ]   0% | PENDING    |
|  Phase 6: Bare-Metal C Drivers & Full System Verification   | [                    ]   0% | PENDING    |
+--------------------------------------------------------------------------------------------------------+
```

> **Project Scope Definition:** The primary objective of this work is **Front-End Architecture Design, RTL IP Integration, and System-Level Verification**. Physical implementation (ASIC Synthesis, Place & Route, and Physical Signoff) is deliberately excluded, allowing complete focus on functional verification, bus protocol compliance, and software driver development.

---

### 8.1 Remaining Hardware & RTL Integration Tasks

#### 1. Hardware Timer IP Integration (STATUS: COMPLETED)
* **Target Interface:** Interconnect Master Port 1 (`m01`), Base Address: `0x4000_4000` (4 KB space).
* **Engineering Scope (Completed):**
  * Fully structured in `rtl/timer_directory/` with modular subdirectories (`rtl/`, `doc/`, `tb/`).
  * Engineered self-contained AXI4-Lite slave wrapper (`axi_timer_top.sv`) encapsulating `timer_core.sv` without external TileLink or OpenTitan package dependencies.
  * Implemented 64-bit real-time counter (`mtime`), 64-bit comparator (`mtimecmp`), 12-bit prescaler, and 8-bit step increments.
  * Connected to `m01_axi_*` channel in `smart_controlsoc_top.v` and exposed `timer_interrupt_o` at top-level.
  * Verified under **`TEST 11`** in `tb/tb_smart_controlsoc_top.sv` (Reset values, Prescaler/step configuration, counter advancement, compare match interrupt assertion, W1C de-assertion, and SW forced interrupt testing).

#### 2. General-Purpose I/O (GPIO) Controller Integration (STATUS: COMPLETED)
* **Target Interface:** Interconnect Master Port 2 (`m02`), Base Address: `0x4000_2000` (4 KB space).
* **Engineering Scope (Completed):**
  * Fully structured in `rtl/gpio_directory/` with clean subdirectories (`rtl/`, `include/`, `doc/`, `tb/`).
  * Self-contained 2-stage synchronizer flip-flop chain implemented in `gpio_input_stage.sv` (zero external technology cell dependencies).
  * AXI4-Lite slave engine implemented in `axi_gpio_top.sv` with tri-state bidirectional `gpio_io[31:0]` buffers.
  * Connected to `m02_axi_*` channels in `smart_controlsoc_top.v`.
  * Verified under **`TEST 10`** in `tb/tb_smart_controlsoc_top.sv` (INFO read, Push-Pull mode, Direct OUT, Atomic Clear, Atomic Set, Atomic Toggle, Input sampling on Pin 1, Rising-Edge interrupt assertion, and W1C de-assertion).

#### 3. Direct Memory Access (DMA) Controller Integration (Completed)
* **Target Interface:** Interconnect Slave Port 1 (`s01`) acting as second Bus Master.
* **Engineering Scope & Results:**
  * Created structured `rtl/dma_directory/` layout (`doc/`, `include/`, `rtl/`, `tb/`).
  * Implemented `axi_dma_top.sv` providing discrete pin-level AXI4 Master and AXI4-Lite Slave CSR interfaces.
  * Connected autonomous DMA AXI4 engine to slave port `s01_axi_*` on the 2x6 interconnect.
  * Preserved interconnect architecture (2x6 strictly preserved, no IP slave modification).
  * Exposed dedicated AXI4-Lite CSR slave port (`dma_csr_*`) and interrupts (`dma_done_interrupt_o`, `dma_error_interrupt_o`) at `smart_controlsoc_top`.
  * Verified end-to-end under **`TEST 12`** in `tb/tb_smart_controlsoc_top.sv` (CSR version signature check `0xCAFE`, descriptor 0 programming, autonomous interconnect transfer from PWM to GPIO, and interrupt assertion).

---

### 8.2 Subsystem Interfacing & Interrupt Aggregation

#### Centralized PIC Interrupt Routing (Priority: HIGH)
* **Engineering Scope:**
  * Currently, peripheral interrupt lines are exposed as top-level signals (`uart_interrupt_o`, `i2c_interrupt_o`, `gpio_interrupt_o`, `timer_interrupt_o`, `dma_done_interrupt_o`, `dma_error_interrupt_o`).
  * In the next phase, these lines—along with `spi_irq`—will be routed directly into the **VeeR EL2 Programmable Interrupt Controller (PIC)**.
  * Configure interrupt priority levels, enable masks, and test end-to-end CPU exception handling and ISR (Interrupt Service Routine) dispatching.

---

### 8.3 Software Stack, Firmware & Simulation Automation

#### 1. Hardware Abstraction Layer (HAL) & Device Drivers
* **Target Location:** `sw/drivers/`
* **Deliverables:**
  * `soc_memory_map.h`: Unified C header containing all base addresses and bitfield definitions.
  * `uart.h` / `uart.c`: Polling and interrupt-driven string transmission and reception drivers.
  * `spi.h` / `spi.c`: SPI transfer and slave-select drivers.
  * `i2c.h` / `i2c.c`: I²C byte read/write and bus addressing drivers.
  * `timer.h` / `timer.c`: Millisecond/microsecond delay and periodic timer interrupt drivers.
  * `pwm.h` / `pwm.c`: Duty cycle and frequency configuration drivers.
  * `gpio.h` / `gpio.c`: Pin direction, read, write, and pin interrupt configuration drivers.
  * `dma.h` / `dma.c`: DMA descriptor setup, control, and interrupt service drivers.

#### 2. Bare-Metal Linker & Startup Architecture
* **Target Location:** `sw/bsp/`
* **Deliverables:**
  * `link.ld`: Custom linker script mapping `.text` sections into ICCM (`0xEE00_0000`) and `.data`/`.bss`/stack into DCCM (`0xF004_0000`).
  * `crt0.s`: Startup assembly code initializing the stack pointer (`sp`), global pointer (`gp`), zeroing `.bss`, and jumping to `main()`.

#### 3. GNU Toolchain Automated Compilation Pipeline
* **Target Location:** `sw/Makefile`
* **Deliverables:**
  * Bare-metal compilation script using `riscv64-unknown-elf-gcc`.
  * Automatic generation of memory initialization files (`firmware.hex` / `firmware.bin`) for direct loading into the CPU ICCM via `$readmemh` during RTL simulation.

---

### 8.4 Action Items & Verification Traceability Matrix

| # | Task Description | Target File / Module | Phase | Category | Priority | Status |
| :-: | :--- | :--- | :--- | :-: | :-: | :-: |
| **T1** | Integrate 64-bit Timer into Interconnect Port M01 | `rtl/smart_controlsoc_top.v` | Phase 3 | RTL | High | ✅ Completed |
| **T2** | Integrate Bidirectional GPIO into Interconnect Port M02 | `rtl/smart_controlsoc_top.v` | Phase 3 | RTL | High | ✅ Completed |
| **T3** | Extend Testbench to cover Timer and GPIO verification | `tb/tb_smart_controlsoc_top.sv` | Phase 3 | Verification | High | ✅ Completed (GPIO & Timer Verified) |
| **T4** | Route peripheral interrupts to VeeR EL2 PIC | `rtl/smart_controlsoc_top.v` | Phase 4 | RTL | High | ⏳ Pending |
| **T5** | Integrate DMA Master into Interconnect Port S01 | `rtl/smart_controlsoc_top.v` | Phase 5 | RTL | Medium | ✅ Completed (Test 12 Passed) |
| **T6** | Develop C Memory Map (`soc_memory_map.h`) & Drivers | `sw/drivers/` | Phase 6 | Software | High | ⏳ Pending |
| **T7** | Create Linker Script (`link.ld`) and Startup (`crt0.s`) | `sw/bsp/` | Phase 6 | Software | High | ⏳ Pending |
| **T8** | Run End-to-End Firmware Simulation with RISC-V GCC | `tb/tb_smart_controlsoc_top.sv` | Phase 6 | Verification | High | ⏳ Pending |

