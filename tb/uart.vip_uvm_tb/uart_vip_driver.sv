// =============================================================================
// UART VIP Driver: uart_vip_driver
// Drives serial UART transactions into DUT UART RX line (vif.uart_rx_i)
// =============================================================================

`ifndef UART_VIP_DRIVER_SV
`define UART_VIP_DRIVER_SV

class uart_vip_driver extends uvm_driver #(uart_vip_item);
  virtual uart_vip_if vif;
  uvm_analysis_port #(uart_vip_item) drv_ap;

  `uvm_component_utils(uart_vip_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    drv_ap = new("drv_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface uart_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize line to idle state (HIGH) per UART standard
    vif.uart_rx_i <= 1'b1;

    // Wait for reset deassertion
    wait(vif.rst_n === 1'b1);
    repeat (20) @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(req);
      drive_frame(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_frame(uart_vip_item item);
    int baud_div;
    if (item.baud_rate > 0)
      baud_div = 100_000_000 / item.baud_rate; // 868 cycles @ 115200 baud, 100MHz
    else
      baud_div = 868;

    item.transmit_time = $realtime;
    `uvm_info(get_type_name(), $sformatf("Driving serial frame: data=0x%02h ('%c'), baud_div=%0d cycles (%0d baud)",
              item.data, (item.data >= 32 && item.data < 127) ? item.data : 8'h2E, baud_div, item.baud_rate), UVM_LOW)

    // Ensure line is idle before starting frame
    vif.uart_rx_i <= 1'b1;
    repeat (10) @(posedge vif.clk);

    // 1. Start Bit: 1'b0
    vif.uart_rx_i <= 1'b0;
    `uvm_info(get_type_name(), $sformatf("  [TX START BIT] Driven LOW at %0t ns", $time), UVM_HIGH)
    repeat (baud_div) @(posedge vif.clk);

    // 2. Data Bits: LSB First (bit 0 through bit 7)
    for (int i = 0; i < item.data_bits; i++) begin
      vif.uart_rx_i <= item.data[i];
      `uvm_info(get_type_name(), $sformatf("  [TX DATA BIT %0d] Driven %b at %0t ns", i, item.data[i], $time), UVM_HIGH)
      repeat (baud_div) @(posedge vif.clk);
    end

    // 3. Optional Parity Bit
    if (item.parity_en) begin
      bit parity_val = ^item.data;
      if (item.parity_mode) parity_val = ~parity_val; // Even parity
      vif.uart_rx_i <= parity_val;
      `uvm_info(get_type_name(), $sformatf("  [TX PARITY BIT] Driven %b at %0t ns", parity_val, $time), UVM_HIGH)
      repeat (baud_div) @(posedge vif.clk);
    end

    // 4. Stop Bit(s): 1'b1
    vif.uart_rx_i <= 1'b1;
    `uvm_info(get_type_name(), $sformatf("  [TX STOP BIT] Driven HIGH at %0t ns", $time), UVM_HIGH)
    repeat (baud_div * item.stop_bits) @(posedge vif.clk);

    // Guard time back to idle state
    repeat (20) @(posedge vif.clk);

    `uvm_info(get_type_name(), $sformatf("Completed driving serial frame for 0x%02h at %0t ns", item.data, $time), UVM_LOW)
    drv_ap.write(item);
  endtask

endclass : uart_vip_driver

`endif // UART_VIP_DRIVER_SV
