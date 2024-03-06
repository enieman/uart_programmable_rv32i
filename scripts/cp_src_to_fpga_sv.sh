#!/usr/bin/env bash

echo "// Auto-assembled from src .v files by cp_src_to_fpga_sv.sh" > ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/tt_um_enieman.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/synchronizer.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/neg_edge_detector.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/pos_edge_detector.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/byte_to_word.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/word_to_byte.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/shift_register.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/uart_rx.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/uart_tx.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/uart_ctrl.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/reg_file.v >> ../fpga/top.v
echo >> ../fpga/top.v
cat ../src/uart_top.v >> ../fpga/top.v
sed -i -e 's/tt_um_enieman/tt_um_template/g' ../fpga/top.v
sed -i -e 's/input  wire \[7\:0\] uio_in/\/\/ input  wire \[7\:0\] uio_in/g' ../fpga/top.v
sed -i -e 's/output wire \[7\:0\] uio_out/\/\/ output wire \[7\:0\] uio_out/g' ../fpga/top.v
sed -i -e 's/output wire \[7:0\] uio_oe/\/\/ output wire \[7:0\] uio_oe/g' ../fpga/top.v
sed -i -e 's/assign uio/\/\/ assign uio/g' ../fpga/top.v
