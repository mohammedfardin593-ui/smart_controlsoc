// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`ifndef PRIM_SUBREG_EXT_SV_
`define PRIM_SUBREG_EXT_SV_

module prim_subreg_ext #(
  parameter int DW = 32
) (
  input          re,
  input          we,
  input [DW-1:0] wd,
  input [DW-1:0] d,
  output logic   qre,
  output logic   qe,
  output logic [DW-1:0] q,
  output logic [DW-1:0] qs
);
  assign qs = d;
  assign q = wd;
  assign qe = we;
  assign qre = re;
endmodule

`endif
