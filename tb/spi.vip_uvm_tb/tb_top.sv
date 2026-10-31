module tb_top;
  import uvm_pkg::*;
  import spi_vip_pkg::*;
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst_n = 0;
  initial #20 rst_n = 1;
  spi_vip_if vif(clk, rst_n);
  initial begin
    uvm_config_db#(virtual spi_vip_if)::set(null, "*", "vif", vif);
    run_test("spi_vip_test");
  end
endmodule
