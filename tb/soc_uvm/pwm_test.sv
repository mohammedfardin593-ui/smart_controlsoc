// =============================================================================
// PWM End-to-End Functional Test: pwm_test
// Tests AXI PWM generator (Base: 0x4000_A000) and passive waveform observation
// =============================================================================

`ifndef PWM_TEST_SV
`define PWM_TEST_SV

class pwm_test extends soc_test;
    `uvm_component_utils(pwm_test)

    localparam [31:0] PWM_BASE = 32'h4000_A000;

    function new(string name = "pwm_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Building pwm_test...", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        bit [31:0] rdata;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: PWM END-TO-END FUNCTIONAL VERIFICATION START          ", UVM_LOW)
        `uvm_info(get_type_name(), "   DUT: smart_controlsoc_top (instance: soc_dut)                 ", UVM_LOW)
        `uvm_info(get_type_name(), "   Base Address  : 0x4000_A000 (Interconnect Port M05)            ", UVM_LOW)
        `uvm_info(get_type_name(), "   Output Port   : pwm_out_o (passive VIP observation)            ", UVM_LOW)
        `uvm_info(get_type_name(), "   Period        : 256 clock cycles (2560 ns @ 100MHz)            ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 1: Wait for Reset Deassertion
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 1] Waiting for system reset deassertion...", UVM_LOW)
        wait (cfg.pwm_vif.rst_n === 1'b1);
        #200ns;

        // Verify default / reset read of PWM duty cycle register (should be 0)
        cfg.cpu_vif.cpu_read(PWM_BASE, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback Default PWM duty_cycle = 0x%08h", rdata), UVM_LOW)
        if (rdata[7:0] !== 8'h00) begin
            `uvm_error(get_type_name(), "Default PWM duty cycle is not 0 after reset!")
        end else begin
            `uvm_info(get_type_name(), "PASS: Default PWM duty cycle is 0 (idle LOW).", UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // Step 2: Configure 25% Duty Cycle (64 / 256)
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 2] Configuring 25% Duty Cycle (duty_cycle = 64)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(PWM_BASE, 32'd64);
        cfg.cpu_vif.cpu_read(PWM_BASE, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback PWM duty_cycle = %0d (Expected: 64)", rdata[7:0]), UVM_LOW)

        // Allow 3 PWM periods to elapse and be measured by VIP monitor
        #10us;
        env.pwm_sb.check_pwm_waveform(64, 256);

        // ---------------------------------------------------------------------
        // Step 3: Configure 50% Duty Cycle (128 / 256)
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 3] Configuring 50% Duty Cycle (duty_cycle = 128)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(PWM_BASE, 32'd128);
        cfg.cpu_vif.cpu_read(PWM_BASE, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback PWM duty_cycle = %0d (Expected: 128)", rdata[7:0]), UVM_LOW)

        #10us;
        env.pwm_sb.check_pwm_waveform(128, 256);

        // ---------------------------------------------------------------------
        // Step 4: Configure 75% Duty Cycle (192 / 256)
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 4] Configuring 75% Duty Cycle (duty_cycle = 192)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(PWM_BASE, 32'd192);
        cfg.cpu_vif.cpu_read(PWM_BASE, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback PWM duty_cycle = %0d (Expected: 192)", rdata[7:0]), UVM_LOW)

        #10us;
        env.pwm_sb.check_pwm_waveform(192, 256);

        // ---------------------------------------------------------------------
        // Step 5: Disable PWM (Duty Cycle = 0)
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 5] Disabling PWM Output (duty_cycle = 0)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(PWM_BASE, 32'd0);
        #5us;

        if (cfg.pwm_vif.pwm_out_o !== 1'b0) begin
            `uvm_error(get_type_name(), "PWM output not LOW after setting duty cycle to 0!")
        end else begin
            `uvm_info(get_type_name(), "PASS: pwm_out_o successfully remained LOW after disabling.", UVM_LOW)
        end

        #500ns;
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: PWM END-TO-END FUNCTIONAL VERIFICATION COMPLETED       ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : pwm_test

`endif // PWM_TEST_SV
