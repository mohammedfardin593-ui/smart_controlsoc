// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`ifndef COMMON_CELLS_ASSERTIONS_SVH_
`define COMMON_CELLS_ASSERTIONS_SVH_

`ifndef ASSERT
`define ASSERT(__name, __prop, __clk = clk_i, __rst = rst_ni) \
  __name: assert property (@(posedge (__clk)) disable iff (!(__rst)) (__prop)) \
    else $error("Assertion failed in %m: %s", `"__prop`");
`endif

`endif // COMMON_CELLS_ASSERTIONS_SVH_
