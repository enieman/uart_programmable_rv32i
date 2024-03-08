#!/usr/bin/env python3

program_file = open("../test/programs.f", "r")
program_list = program_file.read().splitlines()
program_file.close()

for program in program_list:
   # Read hex strings from text file
   hex_file = open("../test/hexstr/" + program + ".hexstr", "r")
   lines = hex_file.read().splitlines()
   hex_file.close()
   
   # Write hex strings as byte to binary file
   bin_file = open("../test/bin/" + program + ".bin", "wb")
   bin_file.write(b'\x55')
   for i in range(0, 16):
      if i < len(lines):
         bin_file.write(int(lines[i], 16).to_bytes(length=4, byteorder='little'))
      else:
         bin_file.write(int("00000033", 16).to_bytes(length=4, byteorder='little'))
   bin_file.close()
