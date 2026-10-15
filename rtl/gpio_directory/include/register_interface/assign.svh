// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`ifndef REGISTER_INTERFACE_ASSIGN_SVH_
`define REGISTER_INTERFACE_ASSIGN_SVH_

`define REG_BUS_ASSIGN_TO_REQ(req, intf) \
  assign req.addr  = intf.addr; \
  assign req.write = intf.write; \
  assign req.wdata = intf.wdata; \
  assign req.wstrb = intf.wstrb; \
  assign req.valid = intf.valid;

`define REG_BUS_ASSIGN_FROM_RSP(intf, rsp) \
  assign intf.rdata = rsp.rdata; \
  assign intf.error = rsp.error; \
  assign intf.ready = rsp.ready;

`endif // REGISTER_INTERFACE_ASSIGN_SVH_
