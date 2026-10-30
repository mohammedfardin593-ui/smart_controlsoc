#!/bin/bash
set -e

rm -rf csrc simv_axi simv_axi.daidir ucli.key axi_aes.fsdb

vcs -full64 -sverilog -debug_access+all \
+incdir+rtl/verilog \
rtl/verilog/aes_sbox.v \
rtl/verilog/aes_rcon.v \
rtl/verilog/aes_key_expand_128.v \
rtl/verilog/aes_cipher_top.v \
axi_aes_cipher_slave.v \
tb_axi_aes_cipher_slave.v \
-o simv_axi

./simv_axi
