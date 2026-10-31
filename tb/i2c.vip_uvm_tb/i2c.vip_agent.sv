class i2c.vip_agent extends uvm_agent;
i2c.vip_driver drv; i2c.vip_monitor mon; i2c.vip_sequencer seqr;
`uvm_component_utils(i2c.vip_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=i2c.vip_driver::type_id::create("drv",this); mon=i2c.vip_monitor::type_id::create("mon",this); seqr=i2c.vip_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
