// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`ifndef REG_BUS_SV_
`define REG_BUS_SV_

interface REG_BUS #(
    parameter int AW = 32,
    parameter int DW = 32
);
    logic [AW-1:0]   addr;
    logic            write;
    logic [DW-1:0]   wdata;
    logic [DW/8-1:0] wstrb;
    logic            valid;
    logic [DW-1:0]   rdata;
    logic            error;
    logic            ready;

    modport in  (input addr, write, wdata, wstrb, valid, output rdata, error, ready);
    modport out (output addr, write, wdata, wstrb, valid, input rdata, error, ready);
endinterface

`endif
