// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`ifndef REGISTER_INTERFACE_TYPEDEF_SVH_
`define REGISTER_INTERFACE_TYPEDEF_SVH_

`define REG_BUS_TYPEDEF_REQ(NAME, addr_t, data_t, strb_t) \
  typedef struct packed { \
    addr_t addr; \
    logic  write; \
    data_t wdata; \
    strb_t wstrb; \
    logic  valid; \
  } NAME``_req_t;

`define REG_BUS_TYPEDEF_RSP(NAME, data_t) \
  typedef struct packed { \
    data_t rdata; \
    logic  error; \
    logic  ready; \
  } NAME``_rsp_t;

`define REG_BUS_TYPEDEF_ALL(NAME, addr_t, data_t, strb_t) \
  `REG_BUS_TYPEDEF_REQ(NAME, addr_t, data_t, strb_t) \
  `REG_BUS_TYPEDEF_RSP(NAME, data_t)

`endif // REGISTER_INTERFACE_TYPEDEF_SVH_
