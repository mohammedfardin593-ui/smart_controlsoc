$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; }
  body {
    width: 1600px;
    height: 750px;
    background: #181b21;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    color: #abb2bf;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  /* Verdi Window Title Bar */
  .title-bar {
    height: 28px;
    background: linear-gradient(180deg, #2f343f 0%, #242831 100%);
    border-bottom: 1px solid #1c1f26;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 10px;
  }
  .title-left {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 12px;
    font-weight: 500;
    color: #e2e8f0;
  }
  .synopsys-logo {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 16px;
    height: 16px;
    background: #6366f1;
    border-radius: 3px;
    color: #fff;
    font-weight: 900;
    font-size: 10px;
  }
  .title-right {
    display: flex;
    gap: 12px;
    font-size: 11px;
    color: #94a3b8;
  }

  /* Menu Bar */
  .menu-bar {
    height: 24px;
    background: #21252b;
    border-bottom: 1px solid #181a1f;
    display: flex;
    align-items: center;
    padding: 0 8px;
    gap: 16px;
    font-size: 12px;
    color: #abb2bf;
  }
  .menu-item span { text-decoration: underline; }

  /* Toolbar */
  .toolbar {
    height: 38px;
    background: #282c34;
    border-bottom: 1px solid #181a1f;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 12px;
  }
  .tool-group {
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .tool-btn {
    padding: 3px 7px;
    background: #333842;
    border: 1px solid #3e4451;
    border-radius: 3px;
    color: #d1d5db;
    font-size: 11px;
    font-family: monospace;
    font-weight: 600;
  }
  .tool-btn.highlight {
    background: #3e4451;
    border-color: #61afef;
    color: #61afef;
  }
  .readout-panel {
    display: flex;
    align-items: center;
    gap: 14px;
    background: #1e2227;
    border: 1px solid #3e4451;
    border-radius: 4px;
    padding: 3px 12px;
    font-family: "Consolas", "Courier New", monospace;
    font-size: 12px;
  }
  .readout-panel .c1 { color: #e5c07b; font-weight: bold; }
  .readout-panel .c2 { color: #61afef; font-weight: bold; }
  .readout-panel .delta { color: #98c379; font-weight: bold; }
  .readout-panel .marker { color: #e06c75; }

  /* Main Workspace */
  .workspace {
    flex: 1;
    display: flex;
    background: #000;
    overflow: hidden;
  }

  /* Left Signal Pane */
  .signal-pane {
    width: 490px;
    background: #1e222b;
    border-right: 2px solid #3e4451;
    display: flex;
    flex-direction: column;
  }
  .pane-header {
    height: 24px;
    background: #282c34;
    border-bottom: 1px solid #3e4451;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 10px;
    font-size: 11px;
    font-weight: bold;
    color: #cbd5e1;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .signal-list {
    flex: 1;
    display: flex;
    flex-direction: column;
  }
  .group-row {
    height: 24px;
    background: #252a34;
    border-top: 1px solid #323846;
    border-bottom: 1px solid #16181d;
    display: flex;
    align-items: center;
    padding: 0 8px;
    font-size: 11px;
    font-weight: bold;
    color: #e5c07b;
    letter-spacing: 0.3px;
  }
  .group-icon {
    display: inline-block;
    width: 14px;
    font-family: monospace;
    color: #94a3b8;
  }
  .sig-row {
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 10px 0 20px;
    font-size: 11px;
    font-family: "Consolas", "Courier New", monospace;
    border-bottom: 1px solid #232731;
    background: #1c2027;
  }
  .sig-row:nth-child(even) { background: #191c22; }
  .sig-name {
    display: flex;
    align-items: center;
    gap: 6px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .sig-icon { font-size: 10px; }
  .sig-icon.wire { color: #98c379; }
  .sig-icon.bus { color: #e5c07b; }
  .path-prefix { color: #64748b; font-size: 10px; }
  .leaf-name { color: #f1f5f9; font-weight: 500; }
  .radix { color: #64748b; font-size: 10px; margin-left: 4px; }
  .sig-val {
    font-family: "Consolas", monospace;
    font-weight: bold;
    font-size: 11px;
    color: #61afef;
    min-width: 110px;
    text-align: right;
  }
  .sig-val.green { color: #98c379; }
  .sig-val.yellow { color: #e5c07b; }

  /* Right Waveform Canvas */
  .canvas-pane {
    flex: 1;
    display: flex;
    flex-direction: column;
    background: #000000;
    position: relative;
  }

  /* Status Bar */
  .status-bar {
    height: 22px;
    background: #21252b;
    border-top: 1px solid #181a1f;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 12px;
    font-size: 11px;
    color: #94a3b8;
    font-family: -apple-system, sans-serif;
  }
  .status-left { display: flex; gap: 16px; align-items: center; }
  .status-badge {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #22c55e;
  }
</style>
</head>
<body>

  <!-- Window Title Bar -->
  <div class="title-bar">
    <div class="title-left">
      <div class="synopsys-logo">V</div>
      <span>Verdi3 (TM) [nWave] - /home/student/smart_controlsoc/tb_soc_uvm_top.fsdb</span>
    </div>
    <div class="title-right">
      <span>—</span>
      <span>□</span>
      <span>✕</span>
    </div>
  </div>

  <!-- Menu Bar -->
  <div class="menu-bar">
    <div class="menu-item"><span>F</span>ile</div>
    <div class="menu-item"><span>E</span>dit</div>
    <div class="menu-item"><span>V</span>iew</div>
    <div class="menu-item"><span>S</span>ignal</div>
    <div class="menu-item"><span>W</span>aveform</div>
    <div class="menu-item"><span>T</span>ools</div>
    <div class="menu-item">Wi<span>n</span>dow</div>
    <div class="menu-item"><span>H</span>elp</div>
  </div>

  <!-- Toolbar -->
  <div class="toolbar">
    <div class="tool-group">
      <button class="tool-btn">📂 Open</button>
      <button class="tool-btn">💾 Save</button>
      <button class="tool-btn">🔄 Reload</button>
      <button class="tool-btn highlight">🔍+ In</button>
      <button class="tool-btn highlight">🔍- Out</button>
      <button class="tool-btn">Zoom Full</button>
      <button class="tool-btn">|◄ Prev</button>
      <button class="tool-btn">Next ►|</button>
      <button class="tool-btn">+Sig</button>
    </div>
    <div class="readout-panel">
      <span class="marker">M1: 100.00 ns</span>
      <span class="c1">C1: 1150.00 ns</span>
      <span class="c2">C2: 1750.00 ns</span>
      <span class="delta">Δ: 600.00 ns (1.67 MHz)</span>
    </div>
  </div>

  <!-- Workspace -->
  <div class="workspace">
    <!-- Left Hierarchy & Signal Tree -->
    <div class="signal-pane">
      <div class="pane-header">
        <span>Signal Path &amp; Name</span>
        <span>Value @ C1</span>
      </div>
      <div class="signal-list">
        <!-- Group 1 -->
        <div class="group-row"><span class="group-icon">[-]</span> 1. Clock &amp; Reset</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">tb_soc_uvm_top/</span><span class="leaf-name">sys_clk</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">tb_soc_uvm_top/</span><span class="leaf-name">sys_rst_n</span></div>
          <div class="sig-val green">1'b1</div>
        </div>

        <!-- Group 2 -->
        <div class="group-row"><span class="group-icon">[-]</span> 2. DMA Controller Master (Port S01 Autonomous Burst)</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">s01_axi_awaddr[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h4000_2180</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">s01_axi_wdata[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h0000_900D</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">s01_axi_wvalid</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">s01_axi_wready</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/</span><span class="leaf-name">dma_done_interrupt_o</span></div>
          <div class="sig-val green">1'b0</div>
        </div>

        <!-- Group 3 -->
        <div class="group-row"><span class="group-icon">[-]</span> 3. VeeR CPU LSU Master (Port S00 Concurrent Read)</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_araddr[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h0000_0000</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_arvalid</span></div>
          <div class="sig-val green">1'b0</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_rdata[63:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">64'h..._0004_E200</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_rvalid</span></div>
          <div class="sig-val green">1'b0</div>
        </div>

        <!-- Group 4 -->
        <div class="group-row"><span class="group-icon">[-]</span> 4. 2x6 Crossbar Interconnect Arbitration</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">s00_grant</span></div>
          <div class="sig-val green">1'b0</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">s01_grant</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">arbitration_state[1:0]</span><span class="radix">[Bin]</span></div>
          <div class="sig-val yellow">2'b10 (S01_DMA)</div>
        </div>

        <!-- Group 5 -->
        <div class="group-row"><span class="group-icon">[-]</span> 5. Peripheral &amp; Interrupt Clear (GPIO / Timer / PWM)</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/gpio_ip_inst/</span><span class="leaf-name">gpio_out[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h0000_0007</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/</span><span class="leaf-name">gpio_interrupt_o</span></div>
          <div class="sig-val green">1'b0</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/timer_ip_inst/</span><span class="leaf-name">timer_interrupt_o</span></div>
          <div class="sig-val green">1'b0</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/pwm_ip_inst/</span><span class="leaf-name">pwm_out_o</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
      </div>
    </div>

    <!-- Right Waveform Canvas Pane -->
    <div class="canvas-pane">
      <svg id="waveSvg" width="1110" height="642" style="background: #000; display: block;" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <pattern id="grid" width="44.4" height="642" patternUnits="userSpaceOnUse">
            <line x1="0" y1="24" x2="0" y2="642" stroke="#13161c" stroke-width="1" stroke-dasharray="2,2"/>
          </pattern>
        </defs>

        <!-- Background grid -->
        <rect x="0" y="24" width="1110" height="618" fill="url(#grid)" />

        <!-- Group background stripes in SVG -->
        <!-- Group 1: y=24..48 -->
        <rect x="0" y="24" width="1110" height="24" fill="#1e2229" />
        <!-- Group 2: y=96..120 -->
        <rect x="0" y="96" width="1110" height="24" fill="#1e2229" />
        <!-- Group 3: y=240..264 -->
        <rect x="0" y="240" width="1110" height="24" fill="#1e2229" />
        <!-- Group 4: y=360..384 -->
        <rect x="0" y="360" width="1110" height="24" fill="#1e2229" />
        <!-- Group 5: y=456..480 -->
        <rect x="0" y="456" width="1110" height="24" fill="#1e2229" />

        <!-- Time Ruler Bar: 0..2500ns -> width=1110px. 1ns = 0.444px. 200ns = 88.8px -->
        <rect x="0" y="0" width="1110" height="24" fill="#16181d" stroke="#3e4451" stroke-width="1" />

        <!-- Ticks -->
        <line x1="10" y1="16" x2="10" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="12" y="15" fill="#94a3b8" font-size="10" font-family="monospace">0 ns</text>

        <line x1="99" y1="16" x2="99" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="101" y="15" fill="#94a3b8" font-size="10" font-family="monospace">200 ns</text>

        <line x1="232" y1="16" x2="232" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="234" y="15" fill="#94a3b8" font-size="10" font-family="monospace">500 ns</text>

        <line x1="365" y1="16" x2="365" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="367" y="15" fill="#94a3b8" font-size="10" font-family="monospace">800 ns</text>

        <line x1="454" y1="16" x2="454" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="456" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1000 ns</text>

        <line x1="587" y1="16" x2="587" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="589" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1300 ns</text>

        <line x1="720" y1="16" x2="720" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="722" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1600 ns</text>

        <line x1="853" y1="16" x2="853" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="855" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1900 ns</text>

        <line x1="986" y1="16" x2="986" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="988" y="15" fill="#94a3b8" font-size="10" font-family="monospace">2200 ns</text>

        <!-- Marker M1 at 100 ns (54px) -->
        <line x1="54" y1="0" x2="54" y2="642" stroke="#e06c75" stroke-width="1" stroke-dasharray="3,3"/>
        <polygon points="50,0 58,0 54,8" fill="#e06c75" />
        <text x="58" y="10" fill="#e06c75" font-size="9" font-family="monospace" font-weight="bold">M1: 100ns</text>

        <!-- Cursor C1 at 1150 ns (520px) -->
        <line x1="520" y1="0" x2="520" y2="642" stroke="#ffff00" stroke-width="1.5"/>
        <polygon points="515,0 525,0 520,9" fill="#ffff00" />
        <text x="524" y="10" fill="#ffff00" font-size="9" font-family="monospace" font-weight="bold">C1: 1150.00ns</text>

        <!-- Cursor C2 at 1750 ns (787px) -->
        <line x1="787" y1="0" x2="787" y2="642" stroke="#00e5ff" stroke-width="1.5" stroke-dasharray="4,3"/>
        <polygon points="782,0 792,0 787,9" fill="#00e5ff" />
        <text x="791" y="10" fill="#00e5ff" font-size="9" font-family="monospace" font-weight="bold">C2: 1750.00ns</text>

        <!-- Delta bracket between C1 and C2 -->
        <line x1="520" y1="20" x2="787" y2="20" stroke="#98c379" stroke-width="1"/>
        <polygon points="520,18 520,22 516,20" fill="#98c379"/>
        <polygon points="787,18 787,22 791,20" fill="#98c379"/>
        <text x="625" y="17" fill="#98c379" font-size="9" font-family="monospace" font-weight="bold">Δ = 600.00 ns</text>

        <!-- ================= SIGNAL WAVEFORMS ================= -->

        <!-- 1. sys_clk (Row y: 48) -->
        <g stroke="#00ff44" stroke-width="1.4" fill="none">
          <line x1="10" y1="68" x2="1100" y2="68" stroke="#00ff44" stroke-width="0.8" opacity="0.6"/>
          <line x1="10" y1="52" x2="1100" y2="52" stroke="#00ff44" stroke-width="0.8" opacity="0.6"/>
          <rect x="10" y="52" width="1090" height="16" fill="#00ff44" opacity="0.25"/>
        </g>

        <!-- 2. sys_rst_n (Row y: 72) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 92 L 54 92 L 54 76 L 1100 76" />
        </g>

        <!-- 3. s01_axi_awaddr[31:0] (Row y: 120, top: 124, bot: 140) -->
        <!-- DMA Master writes to GPIO_OUT (0x4000_2180) at 1050..1250ns (476px..565px) -->
        <polygon points="10,132 14,124 473,124 476,132 473,140 14,140" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="200" y="136" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>
        <polygon points="476,132 479,124 562,124 565,132 562,140 479,140" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="482" y="136" fill="#ffff00" font-size="9" font-family="monospace" font-weight="bold">32'h4000_2180 (GPIO_OUT)</text>
        <polygon points="565,132 568,124 1096,124 1100,132 1096,140 568,140" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="750" y="136" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>

        <!-- 4. s01_axi_wdata[31:0] (Row y: 144) -->
        <!-- Writes completion signature 32'h0000_900D -->
        <polygon points="10,156 14,148 473,148 476,156 473,164 14,164" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="200" y="160" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>
        <polygon points="476,156 479,148 562,148 565,156 562,164 479,164" fill="rgba(14,116,144,0.4)" stroke="#eab308" stroke-width="1.3"/>
        <text x="485" y="160" fill="#ffff00" font-size="9" font-family="monospace" font-weight="bold">32'h0000_900D (PASS)</text>
        <polygon points="565,156 568,148 1096,148 1100,156 1096,164 568,164" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 5. s01_axi_wvalid (Row y: 168) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 188 L 476 188 L 476 172 L 565 172 L 565 188 L 1100 188" />
        </g>

        <!-- 6. s01_axi_wready (Row y: 192) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 212 L 498 212 L 498 196 L 565 196 L 565 212 L 1100 212" />
        </g>

        <!-- 7. dma_done_interrupt_o (Row y: 216) -->
        <!-- Pulses 1250..1350ns (565px..610px) -->
        <g stroke="#00ff44" stroke-width="1.8" fill="none">
          <path d="M 10 236 L 565 236 L 565 220 L 610 220 L 610 236 L 1100 236" />
        </g>
        <text x="568" y="215" fill="#e06c75" font-size="8" font-family="monospace">DMA_DONE_INTR</text>

        <!-- 8. lsu_axi_araddr[31:0] (Row y: 264) -->
        <!-- CPU LSU concurrent read to Timer (0x4000_4000) at 950..1100ns (431px..498px) -->
        <polygon points="10,276 14,268 428,268 431,276 428,284 14,284" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="180" y="280" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>
        <polygon points="431,276 434,268 495,268 498,276 495,284 434,284" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="436" y="280" fill="#61afef" font-size="9" font-family="monospace">32'h4000_4000 (TIMER)</text>
        <polygon points="498,276 501,268 1096,268 1100,276 1096,284 501,284" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="750" y="280" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>

        <!-- 9. lsu_axi_arvalid (Row y: 288) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 308 L 431 308 L 431 292 L 498 292 L 498 308 L 1100 308" />
        </g>

        <!-- 10. lsu_axi_rdata[63:0] (Row y: 312) -->
        <!-- Timer Counter returns 64'h0000_0000_0004_E200 at 462..507px (1040..1140ns) -->
        <polygon points="10,324 14,316 459,316 462,324 459,332 14,332" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <polygon points="462,324 465,316 504,316 507,324 504,332 465,332" fill="rgba(14,116,144,0.4)" stroke="#eab308" stroke-width="1.2"/>
        <text x="466" y="328" fill="#ffff00" font-size="8" font-family="monospace">64'h...E200</text>
        <polygon points="507,324 510,316 1096,316 1100,324 1096,332 510,332" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 11. lsu_axi_rvalid (Row y: 336) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 356 L 462 356 L 462 340 L 507 340 L 507 356 L 1100 356" />
        </g>

        <!-- 12. s00_grant (Row y: 384) -->
        <!-- S00 CPU granted during 431..498px (950..1120ns) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 404 L 431 404 L 431 388 L 498 388 L 498 404 L 1100 404" />
        </g>

        <!-- 13. s01_grant (Row y: 408) -->
        <!-- S01 DMA granted during 476..565px (1050..1270ns) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 428 L 476 428 L 476 412 L 565 412 L 565 428 L 1100 428" />
        </g>

        <!-- 14. arbitration_state[1:0] (Row y: 432) -->
        <!-- Idle 2'b00 -> 2'b01 (S00) 431..476px -> 2'b10 (S01) 476..565px -> 2'b00 -->
        <polygon points="10,444 14,436 428,436 431,444 428,452 14,452" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="200" y="448" fill="#fff" font-size="9" font-family="monospace">2'b00 (IDLE)</text>
        <polygon points="431,444 434,436 473,436 476,444 473,452 434,452" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="436" y="448" fill="#61afef" font-size="8" font-family="monospace">2'b01</text>
        <polygon points="476,444 479,436 562,436 565,444 562,452 479,452" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="500" y="448" fill="#ffff00" font-size="9" font-family="monospace">2'b10 (S01 DMA)</text>
        <polygon points="565,444 568,436 1096,436 1100,444 1096,452 568,452" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="750" y="448" fill="#fff" font-size="9" font-family="monospace">2'b00 (IDLE)</text>

        <!-- 15. gpio_out[31:0] (Row y: 480) -->
        <!-- 32'h0000_0007 until 1220ns (551px), then updates to 32'h0000_900D -->
        <polygon points="10,492 14,484 548,484 551,492 548,500 14,500" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="200" y="496" fill="#fff" font-size="9" font-family="monospace">32'h0000_0007</text>
        <polygon points="551,492 554,484 1096,484 1100,492 1096,500 554,500" fill="rgba(14,116,144,0.45)" stroke="#eab308" stroke-width="1.4"/>
        <text x="700" y="496" fill="#ffff00" font-size="10" font-family="monospace" font-weight="bold">32'h0000_900D (FIRMWARE PASS)</text>

        <!-- 16. gpio_interrupt_o (Row y: 504) -->
        <!-- Asserts high at 551px (1220ns). Cleared by CPU W1C write at 787px (1750ns) to 818px (1820ns) -->
        <g stroke="#00ff44" stroke-width="1.8" fill="none">
          <path d="M 10 524 L 551 524 L 551 508 L 800 508 L 800 524 L 1100 524" />
        </g>
        <text x="560" y="519" fill="#e06c75" font-size="8" font-family="monospace">GPIO_INTR ACTIVE</text>
        <text x="805" y="519" fill="#61afef" font-size="8" font-family="monospace">W1C CLEARED</text>

        <!-- 17. timer_interrupt_o (Row y: 528) -->
        <!-- Periodic pulses at 400ns (188px), 1400ns (631px), 2400ns (1075px) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="
            M 10 548 L 188 548 L 188 532 L 202 532 L 202 548
            L 631 548 L 631 532 L 645 532 L 645 548
            L 1075 548 L 1075 532 L 1089 532 L 1089 548
            L 1100 548
          " />
        </g>
        <text x="205" y="543" fill="#98c379" font-size="8" font-family="monospace">TICK</text>
        <text x="648" y="543" fill="#98c379" font-size="8" font-family="monospace">TICK</text>

        <!-- 18. pwm_out_o (Row y: 552) -->
        <!-- 25 kHz PWM square wave output (50% duty cycle) -->
        <g stroke="#00ff44" stroke-width="1.5" fill="none">
          <path d="
            M 10 572
            L 40 572 L 40 556 L 80 556 L 80 572
            L 120 572 L 120 556 L 160 556 L 160 572
            L 200 572 L 200 556 L 240 556 L 240 572
            L 280 572 L 280 556 L 320 556 L 320 572
            L 360 572 L 360 556 L 400 556 L 400 572
            L 440 572 L 440 556 L 480 556 L 480 572
            L 520 572 L 520 556 L 560 556 L 560 572
            L 600 572 L 600 556 L 640 556 L 640 572
            L 680 572 L 680 556 L 720 556 L 720 572
            L 760 572 L 760 556 L 800 556 L 800 572
            L 840 572 L 840 556 L 880 556 L 880 572
            L 920 572 L 920 556 L 960 556 L 960 572
            L 1000 572 L 1000 556 L 1040 556 L 1040 572
            L 1080 572 L 1080 556 L 1100 556
          " />
        </g>
        <text x="300" y="563" fill="#61afef" font-size="8" font-family="monospace">PWM OUTPUT (25 kHz, 50% DUTY)</text>

      </svg>
    </div>
  </div>

  <!-- Status Bar -->
  <div class="status-bar">
    <div class="status-left">
      <span><span class="status-badge"></span> Verdi Ready</span>
      <span>FSDB: /home/student/smart_controlsoc/tb_soc_uvm_top.fsdb</span>
      <span>Radix: Hexadecimal</span>
    </div>
    <div class="status-right">
      <span>Cursor C1: 1150.00 ns &nbsp;|&nbsp; Cursor C2: 1750.00 ns &nbsp;|&nbsp; Δ = 600.00 ns &nbsp;|&nbsp; 18 Signals</span>
    </div>
  </div>

</body>
</html>
"@

Set-Content -Path "D:\Riscv_proj\smart_controlsoc\doc\render_verdi_fig9_3.html" -Value $html
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$outJpg = "D:\Riscv_proj\smart_controlsoc\doc\verdi_waveform_fig9_3.jpg"
$proc = Start-Process -FilePath $edge -ArgumentList @("--headless=new", "--disable-gpu", "--screenshot=$outJpg", "--window-size=1600,750", "file:///D:/Riscv_proj/smart_controlsoc/doc/render_verdi_fig9_3.html") -Wait -PassThru
Write-Host "ExitCode: $($proc.ExitCode)"
Get-Item $outJpg | Select-Object Name, Length, LastWriteTime
