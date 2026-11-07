// =============================================================================
// I2C End-to-End Functional Test: i2c_test
// Tests OpenCores I2C Master controller and external i2c_slave_model (Addr 0x10)
// =============================================================================

`ifndef I2C_TEST_SV
`define I2C_TEST_SV

class i2c_test extends soc_test;
    `uvm_component_utils(i2c_test)

    localparam [31:0] I2C_BASE     = 32'h4000_8000;
    localparam [31:0] I2C_PRER_LO  = I2C_BASE + 32'h00;
    localparam [31:0] I2C_PRER_HI  = I2C_BASE + 32'h04;
    localparam [31:0] I2C_CTR      = I2C_BASE + 32'h08;
    localparam [31:0] I2C_TXR_RXR  = I2C_BASE + 32'h0C;
    localparam [31:0] I2C_CR_SR    = I2C_BASE + 32'h10;

    localparam [6:0]  SLAVE_ADDR   = 7'b001_0000; // 0x10

    function new(string name = "i2c_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Building i2c_test...", UVM_LOW)
    endfunction

    task wait_i2c_done(output bit [31:0] sr_val);
        bit done = 0;
        for (int i = 0; i < 2000; i++) begin
            cfg.cpu_vif.cpu_read(I2C_CR_SR, sr_val);
            if (sr_val[1] == 1'b0) begin // TIP == 0 (Transfer completed)
                done = 1;
                break;
            end
            #500ns;
        end
        if (!done) begin
            `uvm_error(get_type_name(), "TIMEOUT: I2C transaction did not complete (TIP stuck high)!")
        end
    endtask

    task run_phase(uvm_phase phase);
        bit [31:0] rdata;
        bit [31:0] sr_data;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: I2C END-TO-END FUNCTIONAL VERIFICATION START          ", UVM_LOW)
        `uvm_info(get_type_name(), "   DUT: smart_controlsoc_top (instance: soc_dut)                 ", UVM_LOW)
        `uvm_info(get_type_name(), "   Role          : I2C Master (Base: 0x4000_8000, Port M04)       ", UVM_LOW)
        `uvm_info(get_type_name(), "   Slave Model   : i2c_slave_model (7-bit Addr: 0x10)             ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 1: Wait for Reset Deassertion
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 1] Waiting for system reset deassertion...", UVM_LOW)
        wait (cfg.i2c_vif.rst_n === 1'b1);
        #200ns;

        // Verify idle line levels (both SCL and SDA should be pulled HIGH)
        if (cfg.i2c_vif.i2c_scl_io !== 1'b1 || cfg.i2c_vif.i2c_sda_io !== 1'b1) begin
            `uvm_error(get_type_name(), $sformatf("I2C bus lines not pulled HIGH at idle! SCL=%b SDA=%b", 
                cfg.i2c_vif.i2c_scl_io, cfg.i2c_vif.i2c_sda_io))
        end else begin
            `uvm_info(get_type_name(), "PASS: I2C SCL and SDA are idling HIGH (Open-drain with pull-ups verified).", UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // Step 2: Configure Clock Prescaler and Enable Core
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 2] Configuring I2C Prescaler and enabling Controller...", UVM_LOW)
        // 100MHz clock / (5 * 100kHz) - 1 = 199 (0x00C7)
        cfg.cpu_vif.cpu_write(I2C_PRER_LO, 32'h0000_00C7);
        cfg.cpu_vif.cpu_write(I2C_PRER_HI, 32'h0000_0000);
        // Enable Core (CTR[7] = 1)
        cfg.cpu_vif.cpu_write(I2C_CTR, 32'h0000_0080);
        cfg.cpu_vif.cpu_read(I2C_CTR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback I2C_CTR = 0x%08h (Core Enable: %b)", rdata, rdata[7]), UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 3: Transaction 1 — Write 0x3C to Slave Memory Address 0x02
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 3] Writing Data 0x3C to Slave Addr 0x10, Mem Reg 0x02...", UVM_LOW)

        // Send START + Slave Address (0x10) + Write (0) -> Byte 0x20
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0020);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0090); // STA | WR
        wait_i2c_done(sr_data);
        `uvm_info(get_type_name(), $sformatf("  Slave Addr ACK received (SR=0x%02h, RXACK=%b)", sr_data[7:0], sr_data[7]), UVM_LOW)

        // Send Memory Address (0x02)
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0002);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0010); // WR
        wait_i2c_done(sr_data);
        `uvm_info(get_type_name(), $sformatf("  Memory Reg Addr 0x02 ACK received (SR=0x%02h, RXACK=%b)", sr_data[7:0], sr_data[7]), UVM_LOW)

        // Send Data Byte (0x3C) + STOP
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_003C);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0050); // WR | STO
        wait_i2c_done(sr_data);
        `uvm_info(get_type_name(), $sformatf("  Data 0x3C Write + STOP completed (SR=0x%02h, RXACK=%b)", sr_data[7:0], sr_data[7]), UVM_LOW)
        env.i2c_sb.check_i2c_write(SLAVE_ADDR, 8'h02, 8'h3C, sr_data[7:0]);
        #1us;

        // ---------------------------------------------------------------------
        // Step 4: Transaction 2 — Readback Data from Slave Memory Address 0x02
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 4] Reading back Data from Slave Memory Address 0x02...", UVM_LOW)

        // START + Slave Address (0x10) + Write (0) to set memory address pointer
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0020);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0090); // STA | WR
        wait_i2c_done(sr_data);

        // Memory Address (0x02)
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0002);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0010); // WR
        wait_i2c_done(sr_data);

        // Repeated START + Slave Address (0x10) + Read (1) -> Byte 0x21
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0021);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0090); // Repeated STA | WR
        wait_i2c_done(sr_data);
        `uvm_info(get_type_name(), $sformatf("  Repeated START + Read Addr ACK received (SR=0x%02h)", sr_data[7:0]), UVM_LOW)

        // Read Data Byte + NACK + STOP
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0028); // RD | ACK(1=NACK) | STO
        wait_i2c_done(sr_data);

        // Read received byte from RXR register
        cfg.cpu_vif.cpu_read(I2C_TXR_RXR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback Data byte from I2C_RXR = 0x%02h", rdata[7:0]), UVM_LOW)
        env.i2c_sb.check_i2c_read(SLAVE_ADDR, 8'h3C, rdata[7:0]);
        #1us;

        // ---------------------------------------------------------------------
        // Step 5: Transaction 3 — Multiple-byte test: Write 0x7E to Address 0x01 & Readback
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 5] Multiple transfer test: Writing 0x7E to Address 0x01 & Readback...", UVM_LOW)

        // Write 0x7E to address 0x01
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0020);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0090); // STA | WR
        wait_i2c_done(sr_data);

        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0001);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0010); // WR
        wait_i2c_done(sr_data);

        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_007E);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0050); // WR | STO
        wait_i2c_done(sr_data);
        env.i2c_sb.check_i2c_write(SLAVE_ADDR, 8'h01, 8'h7E, sr_data[7:0]);
        #1us;

        // Readback from address 0x01
        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0020);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0090); // STA | WR
        wait_i2c_done(sr_data);

        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0001);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0010); // WR
        wait_i2c_done(sr_data);

        cfg.cpu_vif.cpu_write(I2C_TXR_RXR, 32'h0000_0021);
        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0090); // Repeated STA | WR
        wait_i2c_done(sr_data);

        cfg.cpu_vif.cpu_write(I2C_CR_SR,   32'h0000_0028); // RD | ACK(1=NACK) | STO
        wait_i2c_done(sr_data);

        cfg.cpu_vif.cpu_read(I2C_TXR_RXR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Readback Data byte from I2C_RXR = 0x%02h", rdata[7:0]), UVM_LOW)
        env.i2c_sb.check_i2c_read(SLAVE_ADDR, 8'h7E, rdata[7:0]);
        #1us;

        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: I2C END-TO-END FUNCTIONAL VERIFICATION COMPLETED       ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : i2c_test

`endif // I2C_TEST_SV
