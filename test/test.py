# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

async def send_packet(dut, data):
  # Start & Stop bit
  packet = (data << 1) + 0x200
  # Feedback data (for logging)
  feedback = 0
  # Send bits
  for i in range(0,10):
    if (packet & 1) == 1:
      dut.ui_in.value = 4
      feedback = feedback | (1 << i)
    else:
      dut.ui_in.value = 0
    await Timer(8681, units="ns") # 115200 bit/sec
    packet = packet >> 1
  # Return feedback
  return ((feedback >> 1) & 0xFF)

async def read_packet(dut):
  # Wait for start bit
  while (dut.uo_out.value & 4) == 4:
    await ClockCycles(dut.clk, 1)
  # Wait out start bit, align with middle of first data bit
  await Timer(13022, units="ns") # 115200 bit/sec, 1.5 bits
  # Read data
  data = 0
  for i in range(0,8):
    if (dut.uo_out.value & 4) == 4:
      data = data | (1 << i)
    await Timer(8681, units="ns") # 115200 bit/sec, 1 bit
  # Wait out rest of data bit
  await Timer(4341, units="ns") # 115200 bit/sec, 0.5 bit
  return(data)

async def reset_dut(dut):
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 4    # Set ui_in[2] to 1, UART inactive value
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1

async def send_program(dut, file_name):
  # Open binary file, read contents, close file
  bin_file = open(file_name, "rb")
  data_list = list(bin_file.read())
  bin_file.close()
  # Send data to dut
  dut._log.info('Writing "' + file_name + '" to I-Memory...')
  for i in range(0, len(data_list)):
    data = await send_packet(dut, data_list[i])
    dut._log.info("Sent Byte %d of %d (0x%0.2X)" % ((i+1), len(data_list), data))
  dut._log.info('Write of "' + file_name + '" to I-Memory complete.')

async def read_data(dut):
  await cocotb.start(send_packet(dut, 0x55))
  data_list = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] # 16 bytes of memory, starting out as zero
  for i in range(0,16):
    data_list[i] = await read_packet(dut)
  for i in range(0,4):
    dut._log.info("D-Memory Word %0.2d: 0x%0.2X%0.2X_%0.2X%0.2X" % (i, data_list[4*i+3], data_list[4*i+2], data_list[4*i+1], data_list[4*i]))
  return(data_list)

async def run_test_program(dut, program_file_name):
  await reset_dut(dut)
  await send_program(dut, program_file_name)
  dut._log.info('Excecuting "' + program_file_name + '" on RV32I core...')
  await ClockCycles(dut.clk, 100) # Give a good amount of time for program to terminate
  return(await read_data(dut))

@cocotb.test()
async def test_top(dut):
  dut._log.info("Start")
  
  # Set clock to 50MHz
  clock = Clock(dut.clk, 20, units="ns") 
  cocotb.start_soon(clock.start())
  
  # Run through test programs
  program_list = ["rw_dmem", "rw_reg", "wr_reg_zero"] # Leaving out "sum_one_to_nine" for now
  for program in program_list:
    dut._log.info('Running "' + program + '.bin"')
    output = await run_test_program(dut, "bin/" + program + ".bin")

  # Run "sum_one_to_nine" program
  dut._log.info('Running "sum_one_to_nine.bin"')
  output = await run_test_program(dut, "bin/sum_one_to_nine.bin")
  assert output[4] == 1+2+3+4+5+6+7+8+9
