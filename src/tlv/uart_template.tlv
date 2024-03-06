\m5_TLV_version 1d --hdl=verilog --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
\m5
   use(m5-1.0)
   
   // #################################################################
   // #                                                               #
   // #  Starting-Point Code for MEST Course Tiny Tapeout RISC-V CPU  #
   // #                                                               #
   // #################################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   // To build within Makerchip for the FPGA or ASIC:
   //   o Use first line of file: \m5_TLV_version 1d --hdl=verilog --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
   //   o set(MAKERCHIP, 0)  // (below)
   //   o For ASIC, set my_design (below) to match the configuration of your repositoy:
   //       - tt_um_fpga_hdl_demo for tt_fpga_hdl_demo repo
   //       - tt_um_example for tt06_verilog_template repo
   //   o var(target, FPGA)  // or ASIC (below)
   set(MAKERCHIP, 0)   /// 1 for simulating in Makerchip.
   var(my_design, tt_um_enieman)   /// The name of your top-level TT module, to match your info.yml.
   var(target, ASIC)  /// FPGA or ASIC
   var(enable_uart, 1) /// 1 for connecting to UART module and register file IMem & DMem
   //-------------------------------------------------------
   
   // Input debouncing--not important for the CPU which has no inputs,but the setting is here for final projects based on the CPU.
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_neq(m5_MAKERCHIP, 1): Debounce unless in Makerchip.
   
   // CPU configs
   var(num_regs, 16)  // 32 for full reg file.
   var(imem_size, 16) // Size of IMem, in 32-bit words; a power of 2.
   var(imem_bits, 4)  // log2(imem_size)
   var(dmem_size, 4)  // Size of DMem, in 32-bit words; a power of 2.
   var(dmem_bits, 2)  // log2(dmem_size)
   
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))
   
   
   // ==================
   // Sum 1 to 9 Program
   // ==================
   
   TLV_fn(riscv_sum_prog, {
      ~assemble(['
         # Add 1,2,3,...,9 (in that order).
         #
         # Regs:
         #  x10 (a0): In: 0, Out: final sum
         #  x12 (a2): 10
         #  x13 (a3): 1..10
         #  x14 (a4): Sum
         #
         # External to function:
         reset:
            ADD x10, x0, x0             # Initialize r10 (a0) to 0.
         # Function:
            ADD x14, x10, x0            # Initialize sum register a4 with 0x0
            ADDI x12, x10, 10            # Store count of 10 in register a2.
            ADD x13, x10, x0            # Initialize intermediate sum register a3 with 0
         loop:
            ADD x14, x13, x14           # Incremental addition
            ADDI x13, x13, 1            # Increment count register by 1
            BLT x13, x12, loop          # If a3 is less than a2, branch to label named <loop>
         done:
            ADD x10, x14, x0            # Store final result to register a0 so that it can be read by main program
      '])
   })
   
\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])  
   m4_include_lib(['https:/']['/raw.githubusercontent.com/efabless/chipcraft---mest-course/main/tlv_lib/risc-v_shell_lib.tlv'])
   
   // Include CPU Design
   m4_include_lib(['https:/']['/raw.githubusercontent.com/enieman/uart_programmable_rv32i/main/src/tlv/cpu_custom.tlv'])


\TLV cpu()
   
   m5+riscv_gen()
   m5+riscv_sum_prog()
   m5_define_hier(IMEM, m5_NUM_INSTRS)
   // -----------------------------------------------------------------------------------------------------------------------------------------------------
   // ---------------------------- UNCOMMENT THIS BLOCK IF CREATING CPU IN THIS FILE INSTEAD OF CONNECTING EXTERNAL CPU DESIGN ----------------------------
   // -----------------------------------------------------------------------------------------------------------------------------------------------------
   // |cpu
   //    @0
   //       $reset = *reset;
   //       
   //       
   //       
   //    // ==================
   //    // |                |
   //    // | YOUR CODE HERE |
   //    // |                |
   //    // ==================
   //    
   //    // Note that pipesignals assigned here can be found under /fpga_pins/fpga.
   //    
   // -----------------------------------------------------------------------------------------------------------------------------------------------------
   
   // Connect External CPU - COMMENT THESE TWO LINES OUT IF CREATING CPU IN THIS FILE (ABOVE)
   m5_if(m5_MAKERCHIP || !m5_enable_uart,['m5+cpu_custom(|cpu, m5_IMEM_INDEX_CNT, m5_dmem_bits, *reset, $imem_rd_en, $imem_rd_addr, $imem_rd_data, $dmem_rd_en, $dmem_wr_en, $dmem_addr, $dmem_wr_byte_en, $dmem_rd_data, $dmem_wr_data)'])
   m5_if(!m5_MAKERCHIP && m5_enable_uart, ['m5+cpu_custom(|cpu, m5_imem_bits, m5_dmem_bits, *reset, *imem_rd_en, *imem_rd_addr, *imem_rd_data, *dmem_rd_en, *dmem_wr_en, *dmem_addr, *dmem_wr_byte_en, *dmem_rd_data, *dmem_wr_data)'])
   
   // Assert these to end simulation (before Makerchip cycle limit).
   // Note, for Makerchip simulation these are passed in uo_out to top-level module's passed/failed signals.
   m5_if(m5_MAKERCHIP || !m5_enable_uart, ['*passed = (|cpu/xreg[10]>>5$value == (1+2+3+4+5+6+7+8+9));'])
   m5_if(m5_MAKERCHIP || !m5_enable_uart, ['*failed = 1'b0;'])
   
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   m5_if(m5_MAKERCHIP || !m5_enable_uart, ['*uo_out = {6'b0, *failed, *passed};'])
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])
   
   // Macro instantiations to be uncommented when instructed for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   |cpu
      m4+rf(@2, @3) // Args: (read stage, write stage) - if equal, no register bypass is required
      m5_if(m5_MAKERCHIP || !m5_enable_uart, ['m4+imem(@1)']) // Args: (read stage)
      m5_if(m5_MAKERCHIP || !m5_enable_uart, ['m4+dmem(@4)']) // Args: (read/write stage)
      
   m5_if(m5_MAKERCHIP, ['m4+cpu_viz(@4)']) // For visualisation, argument should be at least equal to the last stage of CPU logic. @4 would work for all labs.

\SV

m5_if(m5_MAKERCHIP, ['
// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0] uio_in,  uio_out, uio_oe;'])
   assign ui_in = 8'b0;
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   // Passed/failed to control Makerchip simulation, passed from Tiny Tapeout module's uo_out pins.
   assign passed = uo_out[0];
   assign failed = uo_out[1];
endmodule
'])


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   m5_if(m5_MAKERCHIP || !m5_enable_uart, ['
   logic passed, failed; // Connected to uo_out[0] and uo_out[1] respectively, which connect to Makerchip passed/failed.
   wire reset = ! rst_n;
   '])

   // UART Connections
   m5_if(!m5_MAKERCHIP && m5_enable_uart, ['
   
   // Parameters for Memory Sizing and UART Baud
   localparam COUNTER_WIDTH = 16;       // Width of the clock counters in the UART RX and TX modules; at 50MHz, 16 bits should allow baud as low as 763
   localparam IMEM_BYTE_ADDR_WIDTH = m5_imem_bits + 2; // 64 bytes / 16 words of I-Memory
   localparam DMEM_BYTE_ADDR_WIDTH = m5_dmem_bits + 2; // 16 bytes /  4 words of D-Memory
   // CPU Reset
   wire reset;

   // User Interface
   wire rst = ! rst_n | ui_in[7]; // Provide a dedicated button input for RESET
   wire rx_in = ui_in[2];         // Should be wired to Pin 2 of the USBUART Pmod (data from host to Pmod)
   wire tx_out;
   assign uo_out[7] = rst;        // Feedback of RST button, intended to use with LED
   assign uo_out[6] = reset;      // Feedback of CPU reset, indicates if UART controller is in write mode (reset = 1) or read mode (reset = 0)
   assign uo_out[5] = ~rx_in;     // Feedback of RX line, intended to use with LED
   assign uo_out[4] = ~tx_out;    // Feedback of TX line, intended to use with LED
   assign uo_out[3] = 1'b0;       // Unused
   assign uo_out[2] = tx_out;     // Should be wired to Pin 3 of the USBUART Pmod (data from Pmod to host)
   assign uo_out[1] = 1'b0;       // Unused
   assign uo_out[0] = 1'b0;       // Unused

   // I-Memory Interface
   wire uart_imem_ctrl;
   wire imem_rd_en, uart_imem_wr_en;
   wire [IMEM_BYTE_ADDR_WIDTH-3:0] imem_rd_addr, uart_imem_addr;
   wire [3:0] uart_imem_byte_en;
   wire [31:0] imem_rd_data, uart_imem_wr_data;

   // D-Memory Interface
   wire dmem_rd_en, dmem_wr_en, uart_dmem_rd_en;
   wire [DMEM_BYTE_ADDR_WIDTH-3:0] dmem_addr, uart_dmem_addr;
   wire [3:0] dmem_wr_byte_en;
   wire [31:0] dmem_wr_data, dmem_rd_data, uart_dmem_rd_data;

   // UART Module
   uart_top #(
      .COUNTER_WIDTH(COUNTER_WIDTH),
      .IMEM_BYTE_ADDR_WIDTH(IMEM_BYTE_ADDR_WIDTH),
      .DMEM_BYTE_ADDR_WIDTH(DMEM_BYTE_ADDR_WIDTH))
   uart_top0 (
      .clk(clk),
      .rst(rst),
      .rx_in(rx_in),
      .tx_out(tx_out),
      .cpu_rst(reset),
      .imem_ctrl(uart_imem_ctrl),
      .imem_wr_en(uart_imem_wr_en),
      .imem_addr(uart_imem_addr),
      .imem_byte_en(uart_imem_byte_en),
      .imem_wr_data(uart_imem_wr_data),
      .dmem_ctrl(),
      .dmem_rd_en(uart_dmem_rd_en),
      .dmem_addr(uart_dmem_addr),
      .dmem_rd_data(uart_dmem_rd_data));

   // I-Memory
   reg_file #(
      .BYTE_ADDR_WIDTH(IMEM_BYTE_ADDR_WIDTH))
   imem0 (
      .clk(clk),
      .rst(rst),
      .rd_en0(uart_imem_ctrl ? 1'b0 : imem_rd_en),
      .rd_addr0(uart_imem_ctrl ? {(IMEM_BYTE_ADDR_WIDTH-2){1'b0}} : imem_rd_addr),
      .rd_data0(imem_rd_data),
      .rd_en1(1'b0),
      .rd_addr1({(IMEM_BYTE_ADDR_WIDTH-2){1'b0}}),
      .rd_data1(),
      .wr_en(uart_imem_ctrl ? uart_imem_wr_en : 1'b0),
      .wr_addr(uart_imem_ctrl ? uart_imem_addr : {(IMEM_BYTE_ADDR_WIDTH-2){1'b0}}),
      .byte_en(uart_imem_ctrl ? uart_imem_byte_en : 4'h0),
      .wr_data(uart_imem_ctrl ? uart_imem_wr_data : 32'h0));

   // D-Memory
   reg_file #(
      .BYTE_ADDR_WIDTH(DMEM_BYTE_ADDR_WIDTH))
   dmem0 (
      .clk(clk),
      .rst(rst),
      .rd_en0(dmem_rd_en),
      .rd_addr0(dmem_addr),
      .rd_data0(dmem_rd_data),
      .rd_en1(uart_dmem_rd_en),
      .rd_addr1(uart_dmem_addr),
      .rd_data1(uart_dmem_rd_data),
      .wr_en(dmem_wr_en),
      .wr_addr(dmem_addr),
      .byte_en(dmem_wr_byte_en),
      .wr_data(dmem_wr_data));
   
   '])
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , cpu)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV
endmodule
