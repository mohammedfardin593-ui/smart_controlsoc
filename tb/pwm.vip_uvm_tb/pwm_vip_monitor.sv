// =============================================================================
// PWM VIP Monitor: pwm_vip_monitor
// Passively observes DUT output pwm_out_o and measures waveform cycles
// =============================================================================

`ifndef PWM_VIP_MONITOR_SV
`define PWM_VIP_MONITOR_SV

class pwm_vip_monitor extends uvm_monitor;
  virtual pwm_vip_if vif;
  uvm_analysis_port #(pwm_vip_item) ap;

  `uvm_component_utils(pwm_vip_monitor)

  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pwm_vip_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface pwm_vip_if not found in uvm_config_db!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    pwm_vip_item item;
    int h_count = 0;
    int l_count = 0;
    bit prev_val = 0;
    bit measuring = 0;

    wait (vif.rst_n === 1'b1);
    `uvm_info(get_type_name(), "PWM VIP Monitor active and observing pwm_out_o...", UVM_LOW)

    forever begin
      @(posedge vif.clk);
      #1ps; // Sample cleanly after clock-edge NBA update

      if (vif.pwm_out_o === 1'b1 && prev_val === 1'b0) begin
        // Rising edge detected
        if (measuring && h_count > 0 && l_count > 0) begin
          item = pwm_vip_item::type_id::create("item");
          item.high_cycles    = h_count;
          item.low_cycles     = l_count;
          item.period_cycles  = h_count + l_count;
          item.duty_cycle_pct = (h_count * 100.0) / item.period_cycles;

          `uvm_info(get_type_name(), $sformatf("[PWM MEASURED] Period=%0d cycles, High=%0d cycles, Low=%0d cycles (Duty: %0.2f%%)", 
              item.period_cycles, item.high_cycles, item.low_cycles, item.duty_cycle_pct), UVM_LOW)

          ap.write(item);
        end
        h_count = 1;
        l_count = 0;
        measuring = 1;
      end else if (measuring) begin
        if (vif.pwm_out_o === 1'b1) begin
          h_count++;
        end else begin
          l_count++;
        end
      end

      prev_val = vif.pwm_out_o;
    end
  endtask
endclass : pwm_vip_monitor

`endif // PWM_VIP_MONITOR_SV
