class pwm.vip_agent extends uvm_agent;
pwm.vip_driver drv; pwm.vip_monitor mon; pwm.vip_sequencer seqr;
`uvm_component_utils(pwm.vip_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=pwm.vip_driver::type_id::create("drv",this); mon=pwm.vip_monitor::type_id::create("mon",this); seqr=pwm.vip_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
