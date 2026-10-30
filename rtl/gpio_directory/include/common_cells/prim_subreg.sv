// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`ifndef PRIM_SUBREG_SV_
`define PRIM_SUBREG_SV_

module prim_subreg #(
  parameter int DW = 32,
  parameter     SWACCESS = "RW",
  parameter [DW-1:0] RESVAL = '0
) (
  input logic          clk_i,
  input logic          rst_ni,

  input logic          we,
  input logic [DW-1:0] wd,

  input logic          de,
  input logic [DW-1:0] d,

  output logic         qe,
  output logic [DW-1:0] q,
  output logic [DW-1:0] qs
);
  logic [DW-1:0] reg_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg_q <= RESVAL;
    end else if (de) begin
      reg_q <= d;
    end else if (we) begin
      if (SWACCESS == "W1C") begin
        reg_q <= reg_q & ~wd;
      end else if (SWACCESS == "W1S") begin
        reg_q <= reg_q | wd;
      end else if (SWACCESS == "W0C") begin
        reg_q <= reg_q & wd;
      end else begin // "RW", "WO"
        reg_q <= wd;
      end
    end
  end

  assign qs = reg_q;
  assign q  = reg_q;
  assign qe = we;
endmodule

`endif
