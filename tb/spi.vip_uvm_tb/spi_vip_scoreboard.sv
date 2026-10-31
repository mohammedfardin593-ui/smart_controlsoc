class spi_vip_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_vip_scoreboard)
  function new(string n, uvm_component p);
    super.new(n, p);
  endfunction
endclass
