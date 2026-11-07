// =============================================================================
// CPU BFM Interface: cpu_bfm_if
// Connects UVM Environment directly to RISC-V VeeR EL2 CPU LSU AXI Master Port
// Preserves CPU ownership of Interconnect Port S00 (No extra master introduced)
// =============================================================================

`ifndef CPU_BFM_IF_SV
`define CPU_BFM_IF_SV

interface cpu_bfm_if (
    input logic clk,
    input logic rst_n
);
    // Task to write 32-bit MMIO register via VeeR CPU wrapper LSU AXI master port
    task cpu_write(
        input  [31:0] addr,
        input  [31:0] data,
        input  [3:0]  strb = 4'hF
    );
        tb_soc_uvm_top.soc_dut.cpu_inst.cpu_write(addr, data, strb);
    endtask

    // Task to read 32-bit MMIO register via VeeR CPU wrapper LSU AXI master port
    task cpu_read(
        input  [31:0] addr,
        output [31:0] data
    );
        tb_soc_uvm_top.soc_dut.cpu_inst.cpu_read(addr, data);
    endtask

    // Function to probe internal DUT UART IP RX FIFO output data
    function logic [7:0] get_dut_uart_rx_fifo_data();
        return tb_soc_uvm_top.soc_dut.uart_ip_inst.rx_fifo_data_out_int;
    endfunction

endinterface : cpu_bfm_if

`endif // CPU_BFM_IF_SV
