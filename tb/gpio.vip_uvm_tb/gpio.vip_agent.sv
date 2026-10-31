class gpio.vip_agent extends uvm_agent;
gpio.vip_driver drv; gpio.vip_monitor mon; gpio.vip_sequencer seqr;
`uvm_component_utils(gpio.vip_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=gpio.vip_driver::type_id::create("drv",this); mon=gpio.vip_monitor::type_id::create("mon",this); seqr=gpio.vip_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
