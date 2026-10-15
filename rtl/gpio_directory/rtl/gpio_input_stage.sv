// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`timescale 1ns/1ps

module gpio_input_stage #(
  parameter int unsigned NrSyncStages = 2
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic en_i,
  input  logic serial_i,
  output logic r_edge_o,
  output logic f_edge_o,
  output logic serial_o
);

  logic [NrSyncStages-1:0] sync_q;
  logic                    serial_sync;
  logic                    serial_sampled;

  // Multi-stage synchronizer chain
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_q <= '0;
    end else begin
      sync_q <= {sync_q[NrSyncStages-2:0], serial_i};
    end
  end

  assign serial_sync = sync_q[NrSyncStages-1];

  // Sampling register enabled by en_i
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      serial_sampled <= 1'b0;
    end else begin
      if (en_i) begin
        serial_sampled <= serial_sync;
      end
    end
  end

  assign serial_o = serial_sampled;
  assign f_edge_o = (~serial_sync) & serial_sampled;
  assign r_edge_o = serial_sync & (~serial_sampled);

endmodule : gpio_input_stage
