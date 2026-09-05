`timescale 1ns/1ps

module axi_aes_cipher_slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6
)(
    input  wire                         s_axi_aclk,
    input  wire                         s_axi_aresetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                         s_axi_awvalid,
    output wire                         s_axi_awready,

    input  wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                         s_axi_wvalid,
    output wire                         s_axi_wready,

    output reg  [1:0]                   s_axi_bresp,
    output reg                          s_axi_bvalid,
    input  wire                         s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                         s_axi_arvalid,
    output wire                         s_axi_arready,

    output reg  [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]                    s_axi_rresp,
    output reg                           s_axi_rvalid,
    input  wire                           s_axi_rready
);

    // ============================================================
    // AES REGISTER MAP
    // ============================================================

    localparam [5:0] A_CSR   = 6'h00;

    localparam [5:0] A_KEY0  = 6'h04;
    localparam [5:0] A_KEY1  = 6'h08;
    localparam [5:0] A_KEY2  = 6'h0C;
    localparam [5:0] A_KEY3  = 6'h10;

    localparam [5:0] A_TIN0  = 6'h14;
    localparam [5:0] A_TIN1  = 6'h18;
    localparam [5:0] A_TIN2  = 6'h1C;
    localparam [5:0] A_TIN3  = 6'h20;

    localparam [5:0] A_TOUT0 = 6'h24;
    localparam [5:0] A_TOUT1 = 6'h28;
    localparam [5:0] A_TOUT2 = 6'h2C;
    localparam [5:0] A_TOUT3 = 6'h30;


    // ============================================================
    // AXI WRITE ADDRESS/DATA HOLD REGISTERS
    // ============================================================

    reg [5:0]  awaddr_hold;
    reg        aw_hold_valid;

    reg [31:0] wdata_hold;
    reg [3:0]  wstrb_hold;
    reg        w_hold_valid;


    // ============================================================
    // AES REGISTERS
    // ============================================================

    reg [31:0] key0;
    reg [31:0] key1;
    reg [31:0] key2;
    reg [31:0] key3;

    reg [31:0] tin0;
    reg [31:0] tin1;
    reg [31:0] tin2;
    reg [31:0] tin3;

    reg [31:0] tout0;
    reg [31:0] tout1;
    reg [31:0] tout2;
    reg [31:0] tout3;

    reg        ld_reg;
    reg        done_reg;


    // ============================================================
    // AES CORE SIGNALS
    // ============================================================

    wire [127:0] aes_key;
    wire [127:0] aes_text_in;
    wire [127:0] aes_text_out;
    wire         aes_done;


    assign aes_key =
        {key3, key2, key1, key0};

    assign aes_text_in =
        {tin3, tin2, tin1, tin0};


    // ============================================================
    // AES CIPHER CORE
    // ============================================================

    aes_cipher_top u_aes_cipher (
        .clk      (s_axi_aclk),
        .rst      (s_axi_aresetn),
        .ld       (ld_reg),
        .done     (aes_done),
        .key      (aes_key),
        .text_in  (aes_text_in),
        .text_out (aes_text_out)
    );


    // ============================================================
    // AXI WRITE READY
    // ============================================================

    assign s_axi_awready =
        !aw_hold_valid && !s_axi_bvalid;

    assign s_axi_wready =
        !w_hold_valid && !s_axi_bvalid;


    // ============================================================
    // WRITE OPERATION
    // ============================================================

    wire do_write;

    assign do_write =
        aw_hold_valid &&
        w_hold_valid &&
        !s_axi_bvalid;


    // ============================================================
    // BYTE WRITE STROBE FUNCTION
    // ============================================================

    function [31:0] apply_wstrb;

        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0]  strb;

        integer k;

        begin

            apply_wstrb = old_value;

            for (k = 0; k < 4; k = k + 1) begin

                if (strb[k])
                    apply_wstrb[k*8 +: 8] =
                        new_value[k*8 +: 8];

            end

        end

    endfunction


    // ============================================================
    // AXI WRITE LOGIC
    // ============================================================

    always @(posedge s_axi_aclk) begin

        if (!s_axi_aresetn) begin

            awaddr_hold  <= 6'h00;
            aw_hold_valid <= 1'b0;

            wdata_hold   <= 32'h00000000;
            wstrb_hold   <= 4'h0;
            w_hold_valid <= 1'b0;

            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;

            key0 <= 32'h00000000;
            key1 <= 32'h00000000;
            key2 <= 32'h00000000;
            key3 <= 32'h00000000;

            tin0 <= 32'h00000000;
            tin1 <= 32'h00000000;
            tin2 <= 32'h00000000;
            tin3 <= 32'h00000000;

            tout0 <= 32'h00000000;
            tout1 <= 32'h00000000;
            tout2 <= 32'h00000000;
            tout3 <= 32'h00000000;

            ld_reg   <= 1'b0;
            done_reg <= 1'b0;

        end

        else begin

            // ----------------------------------------------------
            // LD is a one-clock pulse.
            // ----------------------------------------------------

            if (ld_reg)
                ld_reg <= 1'b0;


            // ----------------------------------------------------
            // Capture AXI write address.
            // ----------------------------------------------------

            if (s_axi_awvalid && s_axi_awready) begin

                awaddr_hold   <= s_axi_awaddr;
                aw_hold_valid <= 1'b1;

            end


            // ----------------------------------------------------
            // Capture AXI write data.
            // ----------------------------------------------------

            if (s_axi_wvalid && s_axi_wready) begin

                wdata_hold   <= s_axi_wdata;
                wstrb_hold   <= s_axi_wstrb;
                w_hold_valid <= 1'b1;

            end


            // ----------------------------------------------------
            // Execute write when both address and data exist.
            // ----------------------------------------------------

            if (do_write) begin

                case (awaddr_hold)

                    // ==================================================
                    // CIPHER CSR - 0x00
                    //
                    // Bit 0  = LD
                    // Bit 31 = DONE
                    // ==================================================

                    A_CSR: begin

                        if (wstrb_hold[0] &&
                            wdata_hold[0]) begin

                            // Start AES operation
                            ld_reg <= 1'b1;

                            // Clear previous DONE
                            done_reg <= 1'b0;

                        end

                    end


                    // ==================================================
                    // KEY0 - 0x04
                    // ==================================================

                    A_KEY0: begin

                        key0 <= apply_wstrb(
                            key0,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    // ==================================================
                    // KEY1 - 0x08
                    // ==================================================

                    A_KEY1: begin

                        key1 <= apply_wstrb(
                            key1,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    // ==================================================
                    // KEY2 - 0x0C
                    // ==================================================

                    A_KEY2: begin

                        key2 <= apply_wstrb(
                            key2,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    // ==================================================
                    // KEY3 - 0x10
                    // ==================================================

                    A_KEY3: begin

                        key3 <= apply_wstrb(
                            key3,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    // ==================================================
                    // TIN0 - 0x14
                    // ==================================================

                    A_TIN0: begin

                        tin0 <= apply_wstrb(
                            tin0,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    // ==================================================
                    // TIN1 - 0x18
                    // ==================================================

                    A_TIN1: begin

                        tin1 <= apply_wstrb(
                            tin1,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    // ==================================================
                    // TIN2 - 0x1C
                    // ==================================================

                    A_TIN2: begin

                        tin2 <= apply_wstrb(
                            tin2,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    // ==================================================
                    // TIN3 - 0x20
                    // ==================================================

                    A_TIN3: begin

                        tin3 <= apply_wstrb(
                            tin3,
                            wdata_hold,
                            wstrb_hold
                        );

                    end


                    default: begin

                    end

                endcase


                // ----------------------------------------------------
                // Clear write holds.
                // ----------------------------------------------------

                aw_hold_valid <= 1'b0;
                w_hold_valid  <= 1'b0;


                // ----------------------------------------------------
                // AXI write response.
                // ----------------------------------------------------

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;

            end


            // ----------------------------------------------------
            // AXI write response handshake.
            // ----------------------------------------------------

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;


            // ----------------------------------------------------
            // AES DONE
            //
            // AES core DONE can be a short pulse.
            // Latch it into done_reg.
            // ----------------------------------------------------

            if (aes_done) begin

                done_reg <= 1'b1;

                // Capture ciphertext
                tout0 <= aes_text_out[31:0];
                tout1 <= aes_text_out[63:32];
                tout2 <= aes_text_out[95:64];
                tout3 <= aes_text_out[127:96];

            end

        end

    end


    // ============================================================
    // AXI READ READY
    // ============================================================

    assign s_axi_arready =
        !s_axi_rvalid;


    // ============================================================
    // AXI READ DATA
    // ============================================================

    always @(*) begin

        s_axi_rdata = 32'h00000000;

        case (s_axi_araddr)

            // ----------------------------------------------------
            // CIPHER CSR
            // ----------------------------------------------------

            A_CSR: begin

                s_axi_rdata = 32'h00000000;

                // DONE
                s_axi_rdata[31] = done_reg;

                // LD
                s_axi_rdata[0] = ld_reg;

            end


            // ----------------------------------------------------
            // KEY REGISTERS
            // ----------------------------------------------------

            A_KEY0:
                s_axi_rdata = key0;

            A_KEY1:
                s_axi_rdata = key1;

            A_KEY2:
                s_axi_rdata = key2;

            A_KEY3:
                s_axi_rdata = key3;


            // ----------------------------------------------------
            // TEXT INPUT REGISTERS
            // ----------------------------------------------------

            A_TIN0:
                s_axi_rdata = tin0;

            A_TIN1:
                s_axi_rdata = tin1;

            A_TIN2:
                s_axi_rdata = tin2;

            A_TIN3:
                s_axi_rdata = tin3;


            // ----------------------------------------------------
            // TEXT OUTPUT REGISTERS
            // ----------------------------------------------------

            A_TOUT0:
                s_axi_rdata = tout0;

            A_TOUT1:
                s_axi_rdata = tout1;

            A_TOUT2:
                s_axi_rdata = tout2;

            A_TOUT3:
                s_axi_rdata = tout3;


            default:
                s_axi_rdata = 32'h00000000;

        endcase

    end


    // ============================================================
    // AXI READ LOGIC
    // ============================================================

    always @(posedge s_axi_aclk) begin

        if (!s_axi_aresetn) begin

            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'h00000000;
            s_axi_rresp  <= 2'b00;

        end

        else begin

            // ----------------------------------------------------
            // Generate read response.
            // ----------------------------------------------------

            if (s_axi_arvalid && s_axi_arready) begin

                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;

            end


            // ----------------------------------------------------
            // Read response handshake.
            // ----------------------------------------------------

            if (s_axi_rvalid && s_axi_rready) begin

                s_axi_rvalid <= 1'b0;

            end

        end

    end


endmodule
