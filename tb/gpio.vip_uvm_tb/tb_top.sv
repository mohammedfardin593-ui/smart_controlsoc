module tb_top;
  import uvm_pkg::*;
  import gpio_vip_pkg::*;
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst_n = 0;
  initial #20 rst_n = 1;
  gpio_vip_if vif(clk, rst_n);
  initial begin
    uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "vif", vif);
    run_test("gpio_vip_test");
  end
endmodule
