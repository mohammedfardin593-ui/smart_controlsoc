// =============================================================================
// GPIO VIP Sequence Item: gpio_vip_item
// =============================================================================

`ifndef GPIO_VIP_ITEM_SV
`define GPIO_VIP_ITEM_SV

class gpio_vip_item extends uvm_sequence_item;
  rand bit [31:0] gpio_data;
  rand bit [31:0] gpio_mask; // 1 = drive active, 0 = high-Z
  bit [31:0]      sampled_gpio;

  `uvm_object_utils_begin(gpio_vip_item)
    `uvm_field_int(gpio_data, UVM_ALL_ON)
    `uvm_field_int(gpio_mask, UVM_ALL_ON)
    `uvm_field_int(sampled_gpio, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "gpio_vip_item");
    super.new(name);
    gpio_data = 32'h0;
    gpio_mask = 32'h0;
  endfunction
endclass : gpio_vip_item

`endif // GPIO_VIP_ITEM_SV
