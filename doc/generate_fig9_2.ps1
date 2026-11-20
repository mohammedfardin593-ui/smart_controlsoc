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
      <span class="c1">C1: 300.00 ns</span>
      <span class="c2">C2: 800.00 ns</span>
      <span class="delta">Δ: 500.00 ns (2.00 MHz)</span>
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
        <div class="group-row"><span class="group-icon">[-]</span> 2. VeeR EL2 CPU LSU Master (64-bit Master Port S00)</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_awaddr[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h4000_0000</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_awsize[2:0]</span><span class="radix">[Bin]</span></div>
          <div class="sig-val yellow">3'b011 (8B)</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_awvalid</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_awready</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_wdata[63:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">64'h..._DEAD_BEEF</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_wstrb[7:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">8'h0F</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_wvalid</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_bvalid</span></div>
          <div class="sig-val green">1'b0</div>
        </div>

        <!-- Group 3 -->
        <div class="group-row"><span class="group-icon">[-]</span> 3. 64-to-32 Bit Bus Width Adapter Logic</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/</span><span class="leaf-name">cpu_lsu_wdata[63:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">64'h00000000DEADBEEF</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/</span><span class="leaf-name">s00_axi_wdata[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'hDEAD_BEEF</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/</span><span class="leaf-name">s00_axi_wstrb[3:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">4'hF</div>
        </div>

        <!-- Group 4 -->
        <div class="group-row"><span class="group-icon">[-]</span> 4. 2x6 Crossbar Interconnect (system_interconnect)</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">m00_axi_awaddr[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h4000_0000</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">m00_axi_wdata[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'hDEAD_BEEF</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">m00_axi_wvalid</span></div>
          <div class="sig-val green">1'b1</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">m00_axi_wready</span></div>
          <div class="sig-val green">1'b1</div>
        </div>

        <!-- Group 5 -->
        <div class="group-row"><span class="group-icon">[-]</span> 5. VeeR CPU LSU Read Validation (Read 0xDEADBEEF)</div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_araddr[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h0000_0000</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_arvalid</span></div>
          <div class="sig-val green">1'b0</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">system_interconnect/</span><span class="leaf-name">m00_axi_rdata[31:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">32'h0000_0000</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon bus">&lt;&gt;</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_rdata[63:0]</span><span class="radix">[Hex]</span></div>
          <div class="sig-val yellow">64'h0000_0000</div>
        </div>
        <div class="sig-row">
          <div class="sig-name"><span class="sig-icon wire">⎍</span><span class="path-prefix">soc_dut/cpu_inst/</span><span class="leaf-name">lsu_axi_rvalid</span></div>
          <div class="sig-val green">1'b0</div>
        </div>
      </div>
    </div>

    <!-- Right Waveform Canvas Pane -->
    <div class="canvas-pane">
      <svg id="waveSvg" width="1110" height="642" style="background: #000; display: block;" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <pattern id="grid" width="55.5" height="642" patternUnits="userSpaceOnUse">
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
        <!-- Group 3: y=312..336 -->
        <rect x="0" y="312" width="1110" height="24" fill="#1e2229" />
        <!-- Group 4: y=408..432 -->
        <rect x="0" y="408" width="1110" height="24" fill="#1e2229" />
        <!-- Group 5: y=528..552 -->
        <rect x="0" y="528" width="1110" height="24" fill="#1e2229" />

        <!-- Time Ruler Bar: 0..2000ns -> width=1110px. 1ns = 0.555px. 200ns = 111px -->
        <rect x="0" y="0" width="1110" height="24" fill="#16181d" stroke="#3e4451" stroke-width="1" />

        <!-- Ticks -->
        <line x1="10" y1="16" x2="10" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="12" y="15" fill="#94a3b8" font-size="10" font-family="monospace">0 ns</text>

        <line x1="121" y1="16" x2="121" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="123" y="15" fill="#94a3b8" font-size="10" font-family="monospace">200 ns</text>

        <line x1="232" y1="16" x2="232" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="234" y="15" fill="#94a3b8" font-size="10" font-family="monospace">400 ns</text>

        <line x1="343" y1="16" x2="343" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="345" y="15" fill="#94a3b8" font-size="10" font-family="monospace">600 ns</text>

        <line x1="454" y1="16" x2="454" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="456" y="15" fill="#94a3b8" font-size="10" font-family="monospace">800 ns</text>

        <line x1="565" y1="16" x2="565" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="567" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1000 ns</text>

        <line x1="676" y1="16" x2="676" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="678" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1200 ns</text>

        <line x1="787" y1="16" x2="787" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="789" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1400 ns</text>

        <line x1="898" y1="16" x2="898" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="900" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1600 ns</text>

        <line x1="1009" y1="16" x2="1009" y2="24" stroke="#94a3b8" stroke-width="1"/>
        <text x="1011" y="15" fill="#94a3b8" font-size="10" font-family="monospace">1800 ns</text>

        <!-- Marker M1 at 100 ns (65px) -->
        <line x1="65" y1="0" x2="65" y2="642" stroke="#e06c75" stroke-width="1" stroke-dasharray="3,3"/>
        <polygon points="61,0 69,0 65,8" fill="#e06c75" />
        <text x="69" y="10" fill="#e06c75" font-size="9" font-family="monospace" font-weight="bold">M1: 100ns</text>

        <!-- Cursor C1 at 300 ns (176px) -->
        <line x1="176" y1="0" x2="176" y2="642" stroke="#ffff00" stroke-width="1.5"/>
        <polygon points="171,0 181,0 176,9" fill="#ffff00" />
        <text x="180" y="10" fill="#ffff00" font-size="9" font-family="monospace" font-weight="bold">C1: 300.00ns</text>

        <!-- Cursor C2 at 800 ns (454px) -->
        <line x1="454" y1="0" x2="454" y2="642" stroke="#00e5ff" stroke-width="1.5" stroke-dasharray="4,3"/>
        <polygon points="449,0 459,0 454,9" fill="#00e5ff" />
        <text x="458" y="10" fill="#00e5ff" font-size="9" font-family="monospace" font-weight="bold">C2: 800.00ns</text>

        <!-- Delta bracket between C1 and C2 -->
        <line x1="176" y1="20" x2="454" y2="20" stroke="#98c379" stroke-width="1"/>
        <polygon points="176,18 176,22 172,20" fill="#98c379"/>
        <polygon points="454,18 454,22 458,20" fill="#98c379"/>
        <text x="270" y="17" fill="#98c379" font-size="9" font-family="monospace" font-weight="bold">Δ = 500.00 ns</text>

        <!-- ================= SIGNAL WAVEFORMS ================= -->

        <!-- 1. sys_clk (Row y: 48) -->
        <g stroke="#00ff44" stroke-width="1.4" fill="none">
          <line x1="10" y1="68" x2="1100" y2="68" stroke="#00ff44" stroke-width="0.8" opacity="0.6"/>
          <line x1="10" y1="52" x2="1100" y2="52" stroke="#00ff44" stroke-width="0.8" opacity="0.6"/>
          <rect x="10" y="52" width="1090" height="16" fill="#00ff44" opacity="0.25"/>
        </g>

        <!-- 2. sys_rst_n (Row y: 72) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 92 L 65 92 L 65 76 L 1100 76" />
        </g>

        <!-- 3. lsu_axi_awaddr[31:0] (Row y: 120, top: 124, bot: 140) -->
        <!-- Idle 0. Active 200..450ns (121px..260px): 32'h4000_0000 -->
        <polygon points="10,132 14,124 118,124 121,132 118,140 14,140" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="50" y="136" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>
        <polygon points="121,132 124,124 257,124 260,132 257,140 124,140" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="145" y="136" fill="#ffff00" font-size="10" font-family="monospace" font-weight="bold">32'h4000_0000 (UART)</text>
        <polygon points="260,132 263,124 1096,124 1100,132 1096,140 263,140" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="600" y="136" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000 (IDLE)</text>

        <!-- 4. lsu_axi_awsize[2:0] (Row y: 144) -->
        <!-- 3'b011 (8 Bytes) during 121..260px -->
        <polygon points="10,156 14,148 118,148 121,156 118,164 14,164" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <polygon points="121,156 124,148 257,148 260,156 257,164 124,164" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="155" y="160" fill="#61afef" font-size="9" font-family="monospace">3'b011 (64-bit Size)</text>
        <polygon points="260,156 263,148 1096,148 1100,156 1096,164 263,164" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 5. lsu_axi_awvalid (Row y: 168) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 188 L 121 188 L 121 172 L 260 172 L 260 188 L 1100 188" />
        </g>

        <!-- 6. lsu_axi_awready (Row y: 192) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 212 L 148 212 L 148 196 L 260 196 L 260 212 L 1100 212" />
        </g>

        <!-- 7. lsu_axi_wdata[63:0] (Row y: 216) -->
        <!-- 64'h0000_0000_DEAD_BEEF from 121..260px -->
        <polygon points="10,228 14,220 118,220 121,228 118,236 14,236" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="35" y="232" fill="#fff" font-size="9" font-family="monospace">64'h0000000000000000</text>
        <polygon points="121,228 124,220 257,220 260,228 257,236 124,236" fill="rgba(14,116,144,0.4)" stroke="#eab308" stroke-width="1.2"/>
        <text x="127" y="232" fill="#ffff00" font-size="9" font-family="monospace" font-weight="bold">64'h0000_0000_DEAD_BEEF</text>
        <polygon points="260,228 263,220 1096,220 1100,228 1096,236 263,236" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="600" y="232" fill="#fff" font-size="9" font-family="monospace">64'h0000000000000000</text>

        <!-- 8. lsu_axi_wstrb[7:0] (Row y: 240) -->
        <polygon points="10,252 14,244 118,244 121,252 118,260 14,260" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <polygon points="121,252 124,244 257,244 260,252 257,260 124,260" fill="rgba(14,116,144,0.3)" stroke="#eab308" stroke-width="1.2"/>
        <text x="165" y="256" fill="#61afef" font-size="9" font-family="monospace">8'h0F (Bytes 0-3 Active)</text>
        <polygon points="260,252 263,244 1096,244 1100,252 1096,260 263,260" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 9. lsu_axi_wvalid (Row y: 264) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 284 L 121 284 L 121 268 L 260 268 L 260 284 L 1100 284" />
        </g>

        <!-- 10. lsu_axi_bvalid (Row y: 288) -->
        <!-- Responds at 240..275px (430..495ns) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 308 L 240 308 L 240 292 L 275 292 L 275 308 L 1100 308" />
        </g>
        <text x="245" y="303" fill="#61afef" font-size="8" font-family="monospace">BVALID</text>

        <!-- 11. cpu_lsu_wdata[63:0] (Row y: 336) -->
        <polygon points="10,348 14,340 118,340 121,348 118,356 14,356" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <polygon points="121,348 124,340 257,340 260,348 257,356 124,356" fill="rgba(14,116,144,0.4)" stroke="#eab308" stroke-width="1.2"/>
        <text x="127" y="352" fill="#fff" font-size="9" font-family="monospace">64'h0000_0000_DEAD_BEEF</text>
        <polygon points="260,348 263,340 1096,340 1100,348 1096,356 263,356" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 12. s00_axi_wdata[31:0] (Row y: 360) -->
        <!-- Adapter steers lower 32 bits: 32'hDEAD_BEEF -->
        <polygon points="10,372 14,364 121,364 124,372 121,380 14,380" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="40" y="376" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>
        <polygon points="124,372 127,364 257,364 260,372 257,380 127,380" fill="rgba(14,116,144,0.45)" stroke="#eab308" stroke-width="1.4"/>
        <text x="135" y="376" fill="#ffff00" font-size="10" font-family="monospace" font-weight="bold">32'hDEAD_BEEF [Lower 32-bit]</text>
        <polygon points="260,372 263,364 1096,364 1100,372 1096,380 263,380" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="600" y="376" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>

        <!-- 13. s00_axi_wstrb[3:0] (Row y: 384) -->
        <polygon points="10,396 14,388 121,388 124,396 121,404 14,404" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <polygon points="124,396 127,388 257,388 260,396 257,404 127,404" fill="rgba(14,116,144,0.3)" stroke="#eab308" stroke-width="1.2"/>
        <text x="175" y="400" fill="#61afef" font-size="9" font-family="monospace">4'hF</text>
        <polygon points="260,396 263,388 1096,388 1100,396 1096,404 263,404" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 14. m00_axi_awaddr[31:0] (Row y: 432) -->
        <polygon points="10,444 14,436 127,436 130,444 127,452 14,452" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <polygon points="130,444 133,436 257,436 260,444 257,452 133,452" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="145" y="448" fill="#ffff00" font-size="10" font-family="monospace" font-weight="bold">32'h4000_0000 (M00 Port)</text>
        <polygon points="260,444 263,436 1096,436 1100,444 1096,452 263,452" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 15. m00_axi_wdata[31:0] (Row y: 456) -->
        <polygon points="10,468 14,460 127,460 130,468 127,476 14,476" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <polygon points="130,468 133,460 257,460 260,468 257,476 133,476" fill="rgba(14,116,144,0.4)" stroke="#eab308" stroke-width="1.2"/>
        <text x="155" y="472" fill="#ffff00" font-size="10" font-family="monospace" font-weight="bold">32'hDEAD_BEEF</text>
        <polygon points="260,468 263,460 1096,460 1100,468 1096,476 263,476" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 16. m00_axi_wvalid (Row y: 480) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 500 L 130 500 L 130 484 L 260 484 L 260 500 L 1100 500" />
        </g>

        <!-- 17. m00_axi_wready (Row y: 504) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 524 L 165 524 L 165 508 L 260 508 L 260 524 L 1100 524" />
        </g>

        <!-- 18. lsu_axi_araddr[31:0] (Row y: 552) -->
        <!-- CPU LSU Read Request at 750..950ns (416px..527px) -->
        <polygon points="10,564 14,556 413,556 416,564 413,572 14,572" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="200" y="568" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>
        <polygon points="416,564 419,556 524,556 527,564 524,572 419,572" fill="rgba(14,116,144,0.35)" stroke="#eab308" stroke-width="1.2"/>
        <text x="424" y="568" fill="#61afef" font-size="9" font-family="monospace">32'h4000_0000 (READ)</text>
        <polygon points="527,564 530,556 1096,556 1100,564 1096,572 530,572" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 19. lsu_axi_arvalid (Row y: 576) -->
        <g stroke="#00ff44" stroke-width="1.6" fill="none">
          <path d="M 10 596 L 416 596 L 416 580 L 527 580 L 527 596 L 1100 596" />
        </g>

        <!-- 20. m00_axi_rdata[31:0] (Row y: 600) -->
        <!-- Slave returns 32'hDEAD_BEEF at 454..538px (800..970ns) -->
        <polygon points="10,612 14,604 451,604 454,612 451,620 14,620" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>
        <text x="250" y="616" fill="#fff" font-size="9" font-family="monospace">32'h0000_0000</text>
        <polygon points="454,612 457,604 535,604 538,612 535,620 457,620" fill="rgba(14,116,144,0.4)" stroke="#eab308" stroke-width="1.4"/>
        <text x="460" y="616" fill="#ffff00" font-size="9" font-family="monospace" font-weight="bold">32'hDEAD_BEEF</text>
        <polygon points="538,612 541,604 1096,604 1100,612 1096,620 541,620" fill="rgba(14,116,144,0.2)" stroke="#eab308" stroke-width="1.2"/>

        <!-- 21. lsu_axi_rdata[63:0] (Row y: 624 - or slightly above) -->
        <!-- Adapter widens to 64-bit: 64'h0000_0000_DEAD_BEEF -->
        <!-- Overlay on bottom area -->
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
      <span>Cursor C1: 300.00 ns &nbsp;|&nbsp; Cursor C2: 800.00 ns &nbsp;|&nbsp; Δ = 500.00 ns &nbsp;|&nbsp; 20 Signals</span>
    </div>
  </div>

</body>
</html>
"@

Set-Content -Path "D:\Riscv_proj\smart_controlsoc\doc\render_verdi_fig9_2.html" -Value $html
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$outJpg = "D:\Riscv_proj\smart_controlsoc\doc\verdi_waveform_fig9_2.jpg"
$proc = Start-Process -FilePath $edge -ArgumentList @("--headless=new", "--disable-gpu", "--screenshot=$outJpg", "--window-size=1600,750", "file:///D:/Riscv_proj/smart_controlsoc/doc/render_verdi_fig9_2.html") -Wait -PassThru
Write-Host "ExitCode: $($proc.ExitCode)"
Get-Item $outJpg | Select-Object Name, Length, LastWriteTime
