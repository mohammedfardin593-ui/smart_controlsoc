class gpio.vip_driver extends uvm_driver #(gpio.vip_item);
virtual gpio.vip_if vif;
`uvm_component_utils(gpio.vip_driver)
function new(string n,uvm_component p);super.new(n,p);endfunction
task run_phase(uvm_phase phase); forever begin seq_item_port.get_next_item(req); @(posedge vif.clk); seq_item_port.item_done(); end endtask
endclass
