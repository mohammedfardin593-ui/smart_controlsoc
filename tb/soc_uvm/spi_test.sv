// =============================================================================
// SPI End-to-End Functional Test: spi_test
// Tests AXI SPI Master controller (Base: 0x4000_6000) and external SPI VIP
// Performs full-duplex MOSI transmission and MISO reception across CPU/AXI
// =============================================================================

`ifndef SPI_TEST_SV
`define SPI_TEST_SV

class spi_slave_seq extends uvm_sequence #(spi_vip_item);
    `uvm_object_utils(spi_slave_seq)

    bit [7:0] miso_val;

    function new(string name = "spi_slave_seq");
        super.new(name);
    endfunction

    task body();
        req = spi_vip_item::type_id::create("req");
        start_item(req);
        req.miso_data = miso_val;
        finish_item(req);
    endtask
endclass

class spi_test extends soc_test;
    `uvm_component_utils(spi_test)

    localparam [31:0] SPI_BASE = 32'h4000_6000;
    localparam [31:0] SPI_RCLK = SPI_BASE + 32'h30;
    localparam [31:0] SPI_CR   = SPI_BASE + 32'h60;
    localparam [31:0] SPI_SR   = SPI_BASE + 32'h64;
    localparam [31:0] SPI_DTR  = SPI_BASE + 32'h68;
    localparam [31:0] SPI_DRR  = SPI_BASE + 32'h6C;
    localparam [31:0] SPI_SSR  = SPI_BASE + 32'h70;

    function new(string name = "spi_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Building spi_test...", UVM_LOW)
    endfunction

    task wait_spi_rx_ready(output bit [31:0] sr_val);
        bit ready = 0;
        for (int i = 0; i < 2000; i++) begin
            cfg.cpu_vif.cpu_read(SPI_SR, sr_val);
            if (sr_val[0] == 1'b0) begin // RX FIFO NOT empty (bit 0 is rx_empty)
                ready = 1;
                break;
            end
            #50ns;
        end
        if (!ready) begin
            `uvm_error(get_type_name(), "TIMEOUT waiting for SPI RX FIFO not empty (SR[0] == 0)!")
        end
    endtask

    task do_spi_transfer(bit [7:0] exp_mosi, bit [7:0] exp_miso);
        spi_slave_seq slave_seq;
        bit [31:0] sr_val;
        bit [31:0] drr_val;

        `uvm_info(get_type_name(), $sformatf("--- Initiating SPI Transfer: MOSI=0x%02h, MISO=0x%02h ---", 
            exp_mosi, exp_miso), UVM_LOW)

        // Queue slave MISO responder byte in driver via sequence
        slave_seq = spi_slave_seq::type_id::create("slave_seq");
        slave_seq.miso_val = exp_miso;
        fork
            slave_seq.start(env.spi_agent.seqr);
        join_none
        #10ns; // allow sequence to reach driver before transfer begins

        // Write MOSI data into TX FIFO (DTR register)
        cfg.cpu_vif.cpu_write(SPI_DTR, {24'h0, exp_mosi});

        // Wait until SPI reception completes (SR[0] rx_empty goes LOW)
        wait_spi_rx_ready(sr_val);

        // Read received byte from RX FIFO (DRR register)
        cfg.cpu_vif.cpu_read(SPI_DRR, drr_val);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Read DRR = 0x%02h (Status SR: 0x%08h)", 
            drr_val[7:0], sr_val), UVM_LOW)

        // Compare MOSI observed by monitor & MISO read by CPU in scoreboard
        env.spi_sb.check_spi_transfer(exp_mosi, exp_miso, drr_val[7:0]);
    endtask

    task run_phase(uvm_phase phase);
        bit [31:0] rdata;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: SPI END-TO-END FUNCTIONAL VERIFICATION START          ", UVM_LOW)
        `uvm_info(get_type_name(), "   DUT: smart_controlsoc_top (instance: soc_dut)                 ", UVM_LOW)
        `uvm_info(get_type_name(), "   Role          : SPI Master (Base: 0x4000_6000, Port M03)       ", UVM_LOW)
        `uvm_info(get_type_name(), "   Responder     : External SPI VIP Slave Agent                   ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 1: Wait for Reset Deassertion
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 1] Waiting for system reset deassertion...", UVM_LOW)
        wait (cfg.spi_vif.rst_n === 1'b1);
        #200ns;

        // ---------------------------------------------------------------------
        // Step 2: Read Default Register Values After Reset
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 2] Verifying Reset Default Registers...", UVM_LOW)
        cfg.cpu_vif.cpu_read(SPI_CR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Default SPI_CR  = 0x%08h (Expected: 0x00000180)", rdata), UVM_LOW)

        cfg.cpu_vif.cpu_read(SPI_SR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Default SPI_SR  = 0x%08h (Expected: 0x000000A5)", rdata), UVM_LOW)

        cfg.cpu_vif.cpu_read(SPI_SSR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Default SPI_SSR = 0x%08h (Expected: 0xFFFFFFFF)", rdata), UVM_LOW)

        // ---------------------------------------------------------------------
        // Step 3: Configure Clock Ratio & Control Register
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 3] Configuring Clock Ratio and Master Enable...", UVM_LOW)
        // Ratio = 2 (divide sys_clk by 8 for fast simulation SPI clock)
        cfg.cpu_vif.cpu_write(SPI_RCLK, 32'd2);

        // Configure CR: bit 7 (manual SS), bit 2 (master mode), bit 1 (SPI enable) = 0x86
        cfg.cpu_vif.cpu_write(SPI_CR, 32'h0000_0086);
        cfg.cpu_vif.cpu_read(SPI_CR, rdata);
        `uvm_info(get_type_name(), $sformatf("  [CPU <- AXI] Configured SPI_CR = 0x%08h", rdata), UVM_LOW)

        // Select Slave 0 (SSR[0] = 0 -> spi_cs_n_o asserted LOW)
        `uvm_info(get_type_name(), "  [CPU -> AXI] Asserting Slave Select 0 (SSR = 0xFFFFFFFE)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(SPI_SSR, 32'hFFFF_FFFE);
        #100ns;

        if (cfg.spi_vif.spi_cs_n_o !== 1'b0) begin
            `uvm_error(get_type_name(), "SPI CS_N pin did not assert LOW after SSR write!")
        end else begin
            `uvm_info(get_type_name(), "PASS: SPI CS_N pin confirmed LOW on external interface.", UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // Step 4: Full-Duplex Byte Transfers
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 4] Executing Full-Duplex SPI Transfers...", UVM_LOW)

        // Transfer 1: 0xA5 MOSI, 0x5A MISO
        do_spi_transfer(8'hA5, 8'h5A);
        #200ns;

        // Transfer 2: 0x3C MOSI, 0xC3 MISO
        do_spi_transfer(8'h3C, 8'hC3);
        #200ns;

        // Transfer 3: 0xF0 MOSI, 0x0F MISO
        do_spi_transfer(8'hF0, 8'h0F);
        #200ns;

        // Transfer 4: 0xAA MOSI, 0x55 MISO
        do_spi_transfer(8'hAA, 8'h55);
        #200ns;

        // Transfer 5: 0xFF MOSI, 0x12 MISO
        do_spi_transfer(8'hFF, 8'h12);
        #200ns;

        // ---------------------------------------------------------------------
        // Step 5: Deassert Slave Select
        // ---------------------------------------------------------------------
        `uvm_info(get_type_name(), "[STEP 5] Deasserting Slave Select (SSR = 0xFFFFFFFF)...", UVM_LOW)
        cfg.cpu_vif.cpu_write(SPI_SSR, 32'hFFFF_FFFF);
        #100ns;

        if (cfg.spi_vif.spi_cs_n_o !== 1'b1) begin
            `uvm_error(get_type_name(), "SPI CS_N pin did not return HIGH after deselecting slave!")
        end else begin
            `uvm_info(get_type_name(), "PASS: SPI CS_N pin confirmed HIGH (idle deselected).", UVM_LOW)
        end

        #500ns;
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)
        `uvm_info(get_type_name(), "   PHASE 3: SPI END-TO-END FUNCTIONAL VERIFICATION COMPLETE       ", UVM_LOW)
        `uvm_info(get_type_name(), "==================================================================", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : spi_test

`endif // SPI_TEST_SV
