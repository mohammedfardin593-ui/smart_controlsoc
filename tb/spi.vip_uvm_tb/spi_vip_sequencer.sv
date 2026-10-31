class spi_vip_sequencer extends uvm_sequencer #(spi_vip_item);
  `uvm_component_utils(spi_vip_sequencer)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
