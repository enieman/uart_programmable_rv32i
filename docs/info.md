<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## Motivation
This project was developed as a part of the MEST ChipCraft course. As a part of the course, students are walked through the design and implementation of a RISC-V core. At the time that I took this course, students opting to tape out their RISC-V core were limited to a single, hard-wired program in place of a true instruction "memory". This led me to put together a simple UART controller tied to a small register file that could act as programmable instruction memory. Future students (or anyone experimenting with processor design) can utilize the UART modules in this design to enable programmability of their processor designs.

## How it works

This project implements a simplified RISC-V core that runs instructions from a 64-byte register file that is programmed by the user via a UART interface.

The RISC-V core adheres to RV32I with the following exceptions:
1. Does not implement FENCE, ECALL, or EBREAK instructions.
2. Only 32-bit loads are implemented. LH, LHU, LB, LBU are all treated as LW.
3. Only 32-bit stores are implemented. SH and SB are treated as SW.
4. Only implements 16 registers (x0 - x15)

Instruction memory and data memory are isolated. Instruction memory and data memory are implemented as 64-byte (16-word) and 16-byte (4-word) register files that are written to and read from via a UART interface.

The UART controller operates in two modes: "PROGRAM" and "DATA READ". Upon reset of the device, the controller enters "PROGRAM MODE". During this time, the user sends a sync packet, followed by the RV32I binary (64-bytes max). Once 64 bytes have been written (unused space can be filled with "add x0, x0, x0" instructions), the controller will enter "DATA READ" mode. In this mode, the user can read the contents of data memory by sending a single packet (the contents of this packet do not matter).

For those wanting to implement their own processor design, the "uart_top" module (src/uart_top.sv) can be used to add programmability. If using "uart_top" in your own design, be sure to include the following files from src: uart_top.sv, mem_rf.sv, uart_ctrl.sv, uart_tx.sv, uart_rx.sv, shift_register.sv, neg_edge_detector.sv, pos_edge_detector.sv, and synchronizer.sv. "uart_top" is parameterized with IMEM_BYTE_ADDR_WIDTH and DMEM_BYTE_ADDR_WIDTH; these can be configured to set the size of instruction memory and data memory (e.g. size of instruction memory in bytes = 2^IMEM_BYTE_ADDR_WIDTH).

Step-by-step usage:
1. Connect the USBUART PMOD to the demo board via jumpers and a breadboard. The RX pin of the PMOD connects to in2, the TX pin to out2, and PWR/GND should be connected. No other pins of the PMOD are used.
2. Connect the four push-button PMOD to the demo board. This PMOD should connect only to in4-in7.
3. Connect LED PMOD to out4-out7 (optional). out7 is high when reset button is pushed, out6 is high when device is in "PROGRAM" mode, out5 is high when zeros are transmitted on RX, out4 is high when zeros are transmitted on TX.
4. Connect the host computer to the PMOD via USB. A serial terminal will be needed on the laptop.
5. Connect the demo board to power.
6. Press BTN3 (in7) to reset the device.
7. Configure the serial terminal for 8 data bits, no parity, and one stop bit. It is recommended to set the baud rate to the lowest setting (38400 is the highest that has been tested with an FPGA implementation).
8. Send a single sync packet. A packet of hex value 0x55 is recommended, however the only requirement is that it should be an odd-numbered value (the device measures the width of the start bit in clocks).
9. Send instructions as packets. Start with the least-significant byte of the first instruction, end with the most-significant byte of the last instruction.
10. The device will not switch to "DATA READ" until all instruction memory is written. If less than 16 instructions were written, fill in with no-ops (e.g. "add x0, x0, x0").
11. Read data memory by sending a single packet. The content of the packet does not matter.
12. To run a different program, go back to step #6.

## How to test

Used Makerchip IDE (makerchip.com) for initial testing of RISC-V core. Used Psychogenic (https://psychogenic.com) TinyTapeout 3 Demo Board and FPGA daughter board to test UART controller and UART-Programmable RISC-V core. Open src/rv32i_pipelined_core.tlv in Makerchip IDE (makerchip.com) to get started with simulation; may have to comment out "uart_top" module and uncomment imem and dmem macros.

## External hardware

1. USBUART PMOD
2. Button Module PMOD
3. LED PMOD (Optional)
