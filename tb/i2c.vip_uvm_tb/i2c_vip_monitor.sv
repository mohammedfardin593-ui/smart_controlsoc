// =============================================================================
// I2C VIP Monitor: i2c_vip_monitor
// Passively monitors open-drain SCL and SDA lines and decodes transactions
// =============================================================================

`ifndef I2C_VIP_MONITOR_SV
`define I2C_VIP_MONITOR_SV

class i2c_vip_monitor extends uvm_monitor;
  virtual i2c_vip_if vif;
  uvm_analysis_port #(i2c_vip_item) ap;

  `uvm_component_utils(i2c_vip_monitor)

  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface i2c_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    i2c_vip_item item;
    bit [7:0] byte_val;
    bit ack_bit;

    wait (vif.rst_n === 1'b1);
    `uvm_info(get_type_name(), "I2C VIP Monitor active and listening...", UVM_LOW)

    forever begin
      // Wait for START condition: SDA falling while SCL is HIGH
      do begin
        @(negedge vif.i2c_sda_io);
      end while (vif.i2c_scl_io !== 1'b1);

      item = i2c_vip_item::type_id::create("item");
      item.is_start = 1;
      `uvm_info(get_type_name(), $sformatf("I2C START detected at %0t ns", $time), UVM_HIGH)

      // Sample first byte (Address + RW)
      byte_val = 8'h00;
      for (int i = 7; i >= 0; i--) begin
        @(posedge vif.i2c_scl_io);
        byte_val[i] = vif.i2c_sda_io;
      end
      // Sample ACK/NACK
      @(posedge vif.i2c_scl_io);
      ack_bit = vif.i2c_sda_io;

      item.addr = byte_val[7:1];
      item.op   = byte_val[0] ? I2C_READ : I2C_WRITE;
      item.nack = ack_bit;

      // Sample data bytes until repeated START or STOP
      fork : wait_data_or_stop
        begin
          forever begin
            byte_val = 8'h00;
            for (int i = 7; i >= 0; i--) begin
              @(posedge vif.i2c_scl_io);
              byte_val[i] = vif.i2c_sda_io;
            end
            @(posedge vif.i2c_scl_io);
            ack_bit = vif.i2c_sda_io;
            item.data.push_back(byte_val);
          end
        end
        begin
          // Watch for STOP (rising edge of SDA while SCL is HIGH) or Repeated START (falling edge of SDA while SCL is HIGH)
          forever begin
            @(vif.i2c_sda_io);
            if (vif.i2c_scl_io === 1'b1) begin
              break;
            end
          end
        end
      join_any
      disable wait_data_or_stop;

      ap.write(item);
    end
  endtask
endclass : i2c_vip_monitor

`endif // I2C_VIP_MONITOR_SV
