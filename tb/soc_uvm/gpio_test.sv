// =============================================================================
// GPIO End-to-End Functional Test: gpio_test
// Tests bidirectional 32-bit GPIO functionality across CPU/AXI and external VIP
// =============================================================================

`ifndef GPIO_TEST_SV
`define GPIO_TEST_SV

class gpio_drive_sequence extends uvm_sequence #(gpio_vip_item);
    `uvm_object_utils(gpio_drive_sequence)

    bit [31:0] drive_data;
    bit [31:0] drive_mask;

    function new(string name = "gpio_drive_sequence");
        super.new(name);
    endfunction

    task body();
        req = gpio_vip_item::type_id::create("req");
        start_item(req);
        req.gpio_data = drive_data;
        req.gpio_mask = drive_mask;
        finish_item(req);
    endtask
endclass

class gpio_test extends soc_test;
    `uvm_component_utils(gpio_test)

    localparam [31:0] GPIO_BASE        = 32'h4000_2000;
    localparam [31:0] GPIO_INFO        = GPIO_BASE + 32'h00;
    localparam [31:0] GPIO_CFG         = GPIO_BASE + 32'h04;
    localparam [31:0] GPIO_MODE_0      = GPIO_BASE + 32'h08; // Pins [15:0], 2 bits each
    localparam [31:0] GPIO_MODE_1      = GPIO_BASE + 32'h0C; // Pins [31:16], 2 bits each
    localparam [31:0] GPIO_GPIO_EN     = GPIO_BASE + 32'h80; // Input stage sampling enable
    localparam [31:0] GPIO_GPIO_IN     = GPIO_BASE + 32'h100;
    localparam [31:0] GPIO_GPIO_OUT    = GPIO_BASE + 32'h180;
    localparam [31:0] GPIO_GPIO_SET    = GPIO_BASE + 32'h200;
    localparam [31:0] GPIO_GPIO_CLEAR  = GPIO_BASE + 32'h280;
    localparam [31:0] GPIO_GPIO_TOGGLE = GPIO_BASE + 32'h300;

    function new(string name = "gpio_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Building gpio_test...", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        gpio_drive_sequence drv_seq;
        bit [31:0] rdata;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: GPIO END-TO-END FUNCTIONAL VERIFICATION START         ", UVM_LOW)
        `uvm_info(get_type_name(), "   DUT: smart_controlsoc_top (instance: soc_dut)                 ", UVM_LOW)
        `uvm_info(get_type_name(), "   Base Address  : 0x4000_2000 (Interconnect Port M02)            ", UVM_LOW)
        `uvm_info(get_type_name(), "   Bus Width     : 32 Bidirectional IOs (gpio_io[31:0])           ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 1: Wait for Reset Deassertion
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 1] Waiting for system reset deassertion...", UVM_LOW)
        wait (cfg.gpio_vif.rst_n === 1'b1);
        #200ns;

        // Verify default / reset read of GPIO INFO
        cfg.cpu_vif.cpu_read(GPIO_INFO, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read GPIO_INFO = 0x%08h", rdata), UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 2: GPIO OUTPUT VERIFICATION (CPU -> AXI -> GPIO Core -> VIP Monitor)
        // Configure lower 16 pins [15:0] as OUTPUT_ACTIVE (mode 2'b01 -> 32'h5555_5555)
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 2] Configuring Pins [15:0] as OUTPUT_ACTIVE (GPIO_MODE_0 = 0x5555_5555)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(GPIO_MODE_0, 32'h5555_5555);
        cfg.cpu_vif.cpu_read(GPIO_MODE_0, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback GPIO_MODE_0 = 0x%08h", rdata), UVM_LOW)

        // Test Pattern 1: Alternating pattern 0xA5A5
        `uvm_info(get_type_name(), "  [TEST 2.1] Driving Output Pattern 0xA5A5 via CPU...", UVM_LOW)
        cfg.cpu_vif.cpu_write(GPIO_GPIO_OUT, 32'h0000_A5A5);
        #100ns;
        env.gpio_sb.check_gpio_output(32'h0000_A5A5, 32'h0000_FFFF);

        // Test Pattern 2: Complement pattern 0x5A5A
        `uvm_info(get_type_name(), "  [TEST 2.2] Driving Output Pattern 0x5A5A via CPU...", UVM_LOW)
        cfg.cpu_vif.cpu_write(GPIO_GPIO_OUT, 32'h0000_5A5A);
        #100ns;
        env.gpio_sb.check_gpio_output(32'h0000_5A5A, 32'h0000_FFFF);

        // Test Pattern 3: Single Pin Walking (Bit 0)
        `uvm_info(get_type_name(), "  [TEST 2.3] Testing Single Pin Output (Bit 0)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(GPIO_GPIO_OUT, 32'h0000_0001);
        #100ns;
        env.gpio_sb.check_gpio_output(32'h0000_0001, 32'h0000_FFFF);

        // Test Pattern 4: Single Pin Walking (Bit 15)
        `uvm_info(get_type_name(), "  [TEST 2.4] Testing Single Pin Output (Bit 15)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(GPIO_GPIO_OUT, 32'h0000_8000);
        #100ns;
        env.gpio_sb.check_gpio_output(32'h0000_8000, 32'h0000_FFFF);

        // Test Pattern 5: SET Register functionality (Set Bit 2)
        `uvm_info(get_type_name(), "  [TEST 2.5] Testing GPIO_SET register (Setting bit 2)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(GPIO_GPIO_SET, 32'h0000_0004);
        #100ns;
        env.gpio_sb.check_gpio_output(32'h0000_8004, 32'h0000_FFFF);

        // Test Pattern 6: CLEAR Register functionality (Clear Bit 15)
        `uvm_info(get_type_name(), "  [TEST 2.6] Testing GPIO_CLEAR register (Clearing bit 15)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(GPIO_GPIO_CLEAR, 32'h0000_8000);
        #100ns;
        env.gpio_sb.check_gpio_output(32'h0000_0004, 32'h0000_FFFF);

        // ---------------------------------------------------------------------
        // Step 3: GPIO INPUT VERIFICATION (VIP Driver -> GPIO Pads -> AXI -> CPU)
        // Configure upper 16 pins [31:16] as INPUT_ONLY (mode 2'b00) & enable sampling
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 3] Configuring Input Pins [31:16] (MODE=0, EN=0xFFFF_0000)...", UVM_LOW)
        // Set all pins [15:0] back to input to avoid any bus conflict
        cfg.cpu_vif.cpu_write(GPIO_MODE_0, 32'h0000_0000);
        cfg.cpu_vif.cpu_write(GPIO_MODE_1, 32'h0000_0000);
        // Enable input sampling on upper 16 pins
        cfg.cpu_vif.cpu_write(GPIO_GPIO_EN, 32'hFFFF_0000);
        #100ns;

        drv_seq = gpio_drive_sequence::type_id::create("drv_seq");

        // Input Pattern 1: 0x1234 on upper 16 bits
        `uvm_info(get_type_name(), "  [TEST 3.1] VIP Driving 0x1234 on Pins [31:16] -> CPU Readback...", UVM_LOW)
        drv_seq.drive_data = 32'h1234_0000;
        drv_seq.drive_mask = 32'hFFFF_0000;
        drv_seq.start(env.gpio_agent.seqr);
        #250ns; // Wait for synchronizer stages in input_stage
        cfg.cpu_vif.cpu_read(GPIO_GPIO_IN, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read GPIO_IN = 0x%08h", rdata), UVM_LOW)
        env.gpio_sb.check_cpu_readback(32'h1234_0000, rdata, 32'hFFFF_0000);

        // Input Pattern 2: 0xABCD on upper 16 bits
        `uvm_info(get_type_name(), "  [TEST 3.2] VIP Driving 0xABCD on Pins [31:16] -> CPU Readback...", UVM_LOW)
        drv_seq.drive_data = 32'hABCD_0000;
        drv_seq.drive_mask = 32'hFFFF_0000;
        drv_seq.start(env.gpio_agent.seqr);
        #250ns;
        cfg.cpu_vif.cpu_read(GPIO_GPIO_IN, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read GPIO_IN = 0x%08h", rdata), UVM_LOW)
        env.gpio_sb.check_cpu_readback(32'hABCD_0000, rdata, 32'hFFFF_0000);

        // Input Pattern 3: 0xF0F0 on upper 16 bits
        `uvm_info(get_type_name(), "  [TEST 3.3] VIP Driving 0xF0F0 on Pins [31:16] -> CPU Readback...", UVM_LOW)
        drv_seq.drive_data = 32'hF0F0_0000;
        drv_seq.drive_mask = 32'hFFFF_0000;
        drv_seq.start(env.gpio_agent.seqr);
        #250ns;
        cfg.cpu_vif.cpu_read(GPIO_GPIO_IN, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read GPIO_IN = 0x%08h", rdata), UVM_LOW)
        env.gpio_sb.check_cpu_readback(32'hF0F0_0000, rdata, 32'hFFFF_0000);

        // Input Pattern 4: 0x0F0F on upper 16 bits
        `uvm_info(get_type_name(), "  [TEST 3.4] VIP Driving 0x0F0F on Pins [31:16] -> CPU Readback...", UVM_LOW)
        drv_seq.drive_data = 32'h0F0F_0000;
        drv_seq.drive_mask = 32'hFFFF_0000;
        drv_seq.start(env.gpio_agent.seqr);
        #250ns;
        cfg.cpu_vif.cpu_read(GPIO_GPIO_IN, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read GPIO_IN = 0x%08h", rdata), UVM_LOW)
        env.gpio_sb.check_cpu_readback(32'h0F0F_0000, rdata, 32'hFFFF_0000);

        // Release VIP pins
        drv_seq.drive_data = 32'h0000_0000;
        drv_seq.drive_mask = 32'h0000_0000;
        drv_seq.start(env.gpio_agent.seqr);
        #100ns;

        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: GPIO END-TO-END FUNCTIONAL VERIFICATION COMPLETED     ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : gpio_test

`endif // GPIO_TEST_SV
