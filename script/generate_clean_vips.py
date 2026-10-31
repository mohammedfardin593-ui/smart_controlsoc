#!/usr/bin/env python3
import os
import sys
import csv

CLK_NAMES = ['clk', 'clock']
RST_NAMES = ['rst', 'rst_n', 'reset', 'reset_n']

def sv_type(width):
    return 'bit' if width == 1 else f'bit [{width-1}:0]'

def read_signals(csv_file):
    sigs = []
    with open(csv_file) as f:
        for row in csv.reader(f):
            if len(row) < 3:
                continue
            if row[2].strip().lower() in ['size', 'width']:
                continue
            try:
                width = int(row[2].strip())
            except ValueError:
                continue
            sigs.append({'name': row[0].strip(), 'dir': row[1].strip().lower(), 'width': width})
    return sigs

vips = [
    ('gpio_vip', 'smart_controlsoc/doc/interfaces/gpio_interface.csv', 'smart_controlsoc/tb/gpio.vip_uvm_tb'),
    ('i2c_vip',  'smart_controlsoc/doc/interfaces/i2c_interface.csv',  'smart_controlsoc/tb/i2c.vip_uvm_tb'),
    ('pwm_vip',  'smart_controlsoc/doc/interfaces/pwm_interface.csv',  'smart_controlsoc/tb/pwm.vip_uvm_tb'),
    ('spi_vip',  'smart_controlsoc/doc/interfaces/spi_interface.csv',  'smart_controlsoc/tb/spi.vip_uvm_tb'),
    ('uart_vip', 'smart_controlsoc/doc/interfaces/uart_interface.csv', 'smart_controlsoc/tb/uart.vip_uvm_tb')
]

for VIP, csv_file, outdir in vips:
    signals = read_signals(csv_file)
    os.makedirs(outdir, exist_ok=True)
    
    # Item
    s_item = f'''class {VIP}_item extends uvm_sequence_item;
'''
    for sig in signals:
        if sig['name'] not in CLK_NAMES + RST_NAMES:
            rand = 'rand ' if sig['dir'] in ['input', 'inout'] else ''
            s_item += f'  {rand}{sv_type(sig["width"])} {sig["name"]};\n'
    s_item += f'''
  `uvm_object_utils({VIP}_item)

  function new(string name="{VIP}_item");
    super.new(name);
  endfunction
endclass
'''

    # Sequencer
    s_seqr = f'''class {VIP}_sequencer extends uvm_sequencer #({VIP}_item);
  `uvm_component_utils({VIP}_sequencer)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
'''

    # Driver
    s_drv = f'''class {VIP}_driver extends uvm_driver #({VIP}_item);
  virtual {VIP}_if vif;
  `uvm_component_utils({VIP}_driver)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual {VIP}_if)::get(this, "", "vif", vif));
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass
'''

    # Monitor
    s_mon = f'''class {VIP}_monitor extends uvm_monitor;
  virtual {VIP}_if vif;
  uvm_analysis_port #({VIP}_item) ap;
  `uvm_component_utils({VIP}_monitor)

  function new(string n, uvm_component p);
    super.new(n, p);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(virtual {VIP}_if)::get(this, "", "vif", vif));
  endfunction

  task run_phase(uvm_phase phase);
    // Monitor interface signals
  endtask
endclass
'''

    # Agent
    s_agent = f'''class {VIP}_agent extends uvm_agent;
  {VIP}_driver drv;
  {VIP}_monitor mon;
  {VIP}_sequencer seqr;
  `uvm_component_utils({VIP}_agent)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = {VIP}_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      drv = {VIP}_driver::type_id::create("drv", this);
      seqr = {VIP}_sequencer::type_id::create("seqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass
'''

    # Scoreboard
    s_sb = f'''class {VIP}_scoreboard extends uvm_scoreboard;
  `uvm_component_utils({VIP}_scoreboard)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
'''

    # Env
    s_env = f'''class {VIP}_env extends uvm_env;
  {VIP}_agent agent;
  {VIP}_scoreboard sb;
  `uvm_component_utils({VIP}_env)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = {VIP}_agent::type_id::create("agent", this);
    sb    = {VIP}_scoreboard::type_id::create("sb", this);
  endfunction
endclass
'''

    # Test
    s_test = f'''class {VIP}_test extends uvm_test;
  {VIP}_env env;
  `uvm_component_utils({VIP}_test)

  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = {VIP}_env::type_id::create("env", this);
  endfunction
endclass
'''

    # Interface
    s_if = f'''interface {VIP}_if (
  input logic clk,
  input logic rst_n
);
'''
    for sig in signals:
        if sig['name'] not in CLK_NAMES + RST_NAMES:
            if sig['width'] == 1:
                s_if += f'  logic {sig["name"]};\n'
            else:
                s_if += f'  logic [{sig["width"]-1}:0] {sig["name"]};\n'
    s_if += 'endinterface\n'

    # Package
    s_pkg = f'''package {VIP}_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "{VIP}_item.sv"
  `include "{VIP}_sequencer.sv"
  `include "{VIP}_driver.sv"
  `include "{VIP}_monitor.sv"
  `include "{VIP}_agent.sv"
  `include "{VIP}_scoreboard.sv"
  `include "{VIP}_env.sv"
  `include "{VIP}_test.sv"
endpackage
'''

    # Single VIP tb_top.sv
    s_top = f'''module tb_top;
  import uvm_pkg::*;
  import {VIP}_pkg::*;
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst_n = 0;
  initial #20 rst_n = 1;
  {VIP}_if vif(clk, rst_n);
  initial begin
    uvm_config_db#(virtual {VIP}_if)::set(null, "*", "vif", vif);
    run_test("{VIP}_test");
  end
endmodule
'''

    files = {
        f'{VIP}_if.sv': s_if,
        f'{VIP}_item.sv': s_item,
        f'{VIP}_sequencer.sv': s_seqr,
        f'{VIP}_driver.sv': s_drv,
        f'{VIP}_monitor.sv': s_mon,
        f'{VIP}_agent.sv': s_agent,
        f'{VIP}_scoreboard.sv': s_sb,
        f'{VIP}_env.sv': s_env,
        f'{VIP}_test.sv': s_test,
        f'{VIP}_pkg.sv': s_pkg,
        'tb_top.sv': s_top
    }
    for fname, fcontent in files.items():
        with open(os.path.join(outdir, fname), 'w') as f:
            f.write(fcontent)
    print('Generated clean VIP:', VIP, 'in', outdir)
