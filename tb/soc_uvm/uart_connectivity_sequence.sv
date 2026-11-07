// =============================================================================
// UART Connectivity Sequence: uart_connectivity_sequence
// Generates primary test transaction (8'hA5) at 115200 baud, 8-N-1
// =============================================================================

`ifndef UART_CONNECTIVITY_SEQUENCE_SV
`define UART_CONNECTIVITY_SEQUENCE_SV

class uart_connectivity_sequence extends uvm_sequence #(uart_vip_item);
    `uvm_object_utils(uart_connectivity_sequence)

    rand bit [7:0] tx_data;
    rand int       baud_rate;

    constraint c_data {
        soft tx_data   == 8'hA5;
        soft baud_rate == 115200;
    }

    function new(string name = "uart_connectivity_sequence");
        super.new(name);
        tx_data   = 8'hA5;
        baud_rate = 115200;
    endfunction

    virtual task body();
        uart_vip_item item = uart_vip_item::type_id::create("item");
        `uvm_info(get_type_name(), $sformatf("Launching UART sequence with data=0x%02h, baud=%0d", tx_data, baud_rate), UVM_LOW)

        start_item(item);
        if (!item.randomize() with {
            data      == tx_data;
            baud_rate == local::baud_rate;
            data_bits == 8;
            stop_bits == 1;
            parity_en == 1'b0;
        }) begin
            `uvm_fatal(get_type_name(), "Randomization failed for uart_vip_item!")
        end
        finish_item(item);

        `uvm_info(get_type_name(), $sformatf("Finished UART sequence for data=0x%02h", tx_data), UVM_LOW)
    endtask

endclass : uart_connectivity_sequence

`endif // UART_CONNECTIVITY_SEQUENCE_SV
