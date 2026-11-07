// =============================================================================
// UART VIP Monitor: uart_vip_monitor
// Samples and reconstructs serial UART frames on vif.uart_rx_i
// =============================================================================

`ifndef UART_VIP_MONITOR_SV
`define UART_VIP_MONITOR_SV

class uart_vip_monitor extends uvm_monitor;
  virtual uart_vip_if vif;
  uvm_analysis_port #(uart_vip_item) ap;

  `uvm_component_utils(uart_vip_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface uart_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    int baud_div = 868; // 115200 baud at 100MHz clock
    bit [7:0] sampled_data;
    uart_vip_item item;

    wait(vif.rst_n === 1'b1);
    `uvm_info(get_type_name(), "UART VIP Monitor active and awaiting serial RX traffic...", UVM_LOW)

    forever begin
      // 1. Detect Start Bit falling edge
      @(negedge vif.uart_rx_i);
      `uvm_info(get_type_name(), $sformatf("Detected Start Bit falling edge at %0t ns", $time), UVM_HIGH)

      // 2. Sample at midpoint of Start Bit to verify validity (avoid false trigger / glitch)
      repeat (baud_div / 2) @(posedge vif.clk);
      if (vif.uart_rx_i !== 1'b0) begin
        `uvm_warning(get_type_name(), $sformatf("Glitch detected at %0t ns: Start bit aborted.", $time))
        continue;
      end

      // 3. Sample 8 Data Bits at exact bit centers (LSB first)
      for (int i = 0; i < 8; i++) begin
        repeat (baud_div) @(posedge vif.clk);
        sampled_data[i] = vif.uart_rx_i;
        `uvm_info(get_type_name(), $sformatf("Sampled bit[%0d] = %b at %0t ns", i, sampled_data[i], $time), UVM_HIGH)
      end

      // 4. Sample Stop Bit at midpoint
      repeat (baud_div) @(posedge vif.clk);
      item = uart_vip_item::type_id::create("mon_item");
      item.data          = sampled_data;
      item.baud_rate     = 115200;
      item.data_bits     = 8;
      item.stop_bits     = 1;
      item.transmit_time = $realtime;

      if (vif.uart_rx_i !== 1'b1) begin
        item.framing_error = 1'b1;
        `uvm_error(get_type_name(), $sformatf("Framing error at %0t ns! Stop bit sampled as %b (expected 1'b1)", $time, vif.uart_rx_i))
      end else begin
        item.framing_error = 1'b0;
        `uvm_info(get_type_name(), $sformatf("Reconstructed valid UART frame: data=0x%02h ('%c') at %0t ns",
                  sampled_data, (sampled_data >= 32 && sampled_data < 127) ? sampled_data : 8'h2E, $time), UVM_LOW)
      end

      // Broadcast to Scoreboard
      ap.write(item);
    end
  endtask

endclass : uart_vip_monitor

`endif // UART_VIP_MONITOR_SV
