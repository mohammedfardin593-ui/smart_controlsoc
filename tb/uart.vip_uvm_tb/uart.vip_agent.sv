class uart.vip_agent extends uvm_agent;
uart.vip_driver drv; uart.vip_monitor mon; uart.vip_sequencer seqr;
`uvm_component_utils(uart.vip_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=uart.vip_driver::type_id::create("drv",this); mon=uart.vip_monitor::type_id::create("mon",this); seqr=uart.vip_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
