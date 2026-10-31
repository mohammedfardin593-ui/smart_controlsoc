class spi.vip_agent extends uvm_agent;
spi.vip_driver drv; spi.vip_monitor mon; spi.vip_sequencer seqr;
`uvm_component_utils(spi.vip_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=spi.vip_driver::type_id::create("drv",this); mon=spi.vip_monitor::type_id::create("mon",this); seqr=spi.vip_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
