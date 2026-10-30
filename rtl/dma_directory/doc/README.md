# Direct Memory Access (DMA) Controller

## Overview
The DMA controller IP provides autonomous high-speed data movement across the Smart ControlSoC interconnect without requiring CPU intervention. It connects as an AXI4 bus master to Port S01 of the system's 2x6 interconnect (`axi_interconnect_wrap_2x6`) and is programmed via a dedicated 32-bit AXI4-Lite CSR slave port.

## Architecture
```
              +----------------------------------+
              |      smart_controlsoc_top        |
              |                                  |
              |   +---------------+              |
CSR AXI4-Lite |-->|               |  AXI4 Master |
              |   |  axi_dma_top  |=============|==> Interconnect S01 Port
DMA Done IRQ  |<--|               |              |    (Accesses UART, Timer,
DMA Error IRQ |<--|               |              |     GPIO, SPI, I2C, PWM)
              |   +---------------+              |
              +----------------------------------+
```

### Submodules
- `axi_dma_top`: Top wrapper exposing discrete pin-level AXI4 Master and AXI4-Lite Slave interfaces.
- `dma_axi_wrapper`: Bridges RgGen CSRs and DMA functional wrapper.
- `dma_func_wrapper`: Orchestrates read/write streamers, internal FIFO, and AXI master interface.
- `dma_fsm`: Control state machine managing descriptor execution, byte counts, and transaction progress.
- `dma_streamer`: Read and Write AXI burst generation engines.
- `dma_fifo`: Dual-port synchronous buffer between read and write engines.
- `dma_axi_if`: AXI master protocol handler with handshake logic and beat counters.
- `csr_dma`: RgGen-generated CSR block managing control, status, error, and descriptors.

## Memory-Mapped Registers (AXI4-Lite Slave)
Base Address is assigned by the system integrator (accessible via `dma_csr_*` pins).

| Offset | Register Name      | Description |
|--------|-------------------|-------------|
| `0x00` | `DMA_CONTROL`     | Control register: [0] `go` (trigger transfer), [1] `abort`, [9:2] `max_burst` |
| `0x08` | `DMA_STATUS`      | Status register: [15:0] IP version, [16] `done`, [17] `error` |
| `0x10` | `DMA_ERROR_ADDR`  | Captures faulting AXI address if a transaction fails |
| `0x18` | `DMA_ERROR_STATS` | [0] error type (read/write), [1] error source, [2] error trigger |
| `0x20` | `DMA_DESC0_SRC`   | Descriptor 0 Source 32-bit Address |
| `0x28` | `DMA_DESC1_SRC`   | Descriptor 1 Source 32-bit Address |
| `0x30` | `DMA_DESC0_DST`   | Descriptor 0 Destination 32-bit Address |
| `0x38` | `DMA_DESC1_DST`   | Descriptor 1 Destination 32-bit Address |
| `0x40` | `DMA_DESC0_LEN`   | Descriptor 0 Transfer Length in Bytes |
| `0x48` | `DMA_DESC1_LEN`   | Descriptor 1 Transfer Length in Bytes |
| `0x50` | `DMA_DESC0_CFG`   | Descriptor 0 Config: [0] Write Mode (0=Fixed, 1=Incr), [1] Read Mode (0=Fixed, 1=Incr), [2] Enable |
| `0x58` | `DMA_DESC1_CFG`   | Descriptor 1 Config: [0] Write Mode (0=Fixed, 1=Incr), [1] Read Mode (0=Fixed, 1=Incr), [2] Enable |

## Directory Layout
- `doc/`: Architecture documentation and register specifications.
- `include/`: AXI package types (`amba_axi_pkg.sv`), DMA structures (`dma_utils_pkg.sv`, `dma_pkg.svh`), and macro definitions (`rggen_rtl_macros.vh`).
- `rtl/`: Synthesizable Verilog and SystemVerilog implementation files.
- `tb/`: Standalone testbenches and Cocotb verification test suites.
