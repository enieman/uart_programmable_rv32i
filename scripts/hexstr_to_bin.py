#!/usr/bin/env python3

program_list = ["bge_bltu_bgeu", "bne_beq_blt", "rw_dmem", "rw_reg", "sum_one_to_nine", "wr_reg_zero"]

for program in program_list:
   hex_file = open("../test/hexstr/" + program + ".hexstr", "r")
   bin_file = open("../test/bin/" + program + ".bin", "wb")
   bin_file.write(b'\x55')
   for line in hex_file.readlines():
      bin_file.write(int(line, 16).to_bytes(length=4, byteorder='little'))
   hex_file.close()
   bin_file.close()
