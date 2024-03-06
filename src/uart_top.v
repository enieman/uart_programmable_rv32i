module uart_top #(
   parameter COUNTER_WIDTH = 24,       // Width of the clock-cycle counter used in auto-baud-detection
   parameter IMEM_BYTE_ADDR_WIDTH = 6, // Width of the byte-level address; default to 64 bytes of storage
   parameter DMEM_BYTE_ADDR_WIDTH = 6) // Width of the byte-level address; default to 64 bytes of storage
(
   input  wire clk,
   // User Interface
   input  wire rst,
   input  wire rx_in,
   output wire tx_out,
   // CPU Interface
   output wire cpu_rst,
   // I-Memory Interface
   output wire imem_ctrl,
   output wire imem_wr_en,
   output wire [IMEM_BYTE_ADDR_WIDTH-3:0] imem_addr,
   output wire [3:0] imem_byte_en,
   output wire [31:0] imem_wr_data,
   // D-Memory Interface
   output wire dmem_ctrl,
   output wire dmem_rd_en,
   output wire [DMEM_BYTE_ADDR_WIDTH-3:0] dmem_addr,
   input  wire [31:0] dmem_rd_data);

   wire rx_ready, tx_empty, tx_error, tx_req;
   wire [IMEM_BYTE_ADDR_WIDTH-1:0] imem_byte_addr;
   wire [DMEM_BYTE_ADDR_WIDTH-1:0] dmem_byte_addr;
   wire [7:0] rx_data, tx_data;
   wire [COUNTER_WIDTH-1:0] cycles_per_bit;

   uart_rx #(
      .COUNTER_WIDTH(COUNTER_WIDTH))
   uart_rx0 (
      .clk(clk),
      .rst(rst),
      .uart_rx_in(rx_in),
      .data(rx_data),
      .cycles_per_bit(cycles_per_bit),
      .ready(rx_ready));

   uart_tx #(
      .COUNTER_WIDTH(COUNTER_WIDTH))
   uart_tx0 (
      .clk(clk),
      .rst(rst),
      .uart_tx_out(tx_out),
      .data(tx_data),
      .req(tx_req),
      .cycles_per_bit(cycles_per_bit),
      .empty(tx_empty),
      .error(tx_error));

   uart_ctrl #(
      .IMEM_BYTE_ADDR_WIDTH(IMEM_BYTE_ADDR_WIDTH),
      .DMEM_BYTE_ADDR_WIDTH(DMEM_BYTE_ADDR_WIDTH))
   uart_ctrl0 (
      .clk(clk),
      .rst(rst),
      .rx_ready(rx_ready),
      .tx_empty(tx_empty),
      .tx_error(tx_error),
      .cpu_rst(cpu_rst),
      .tx_req(tx_req),
      .imem_ctrl(imem_ctrl),
      .imem_wr_en(imem_wr_en),
      .imem_addr(imem_byte_addr),
      .dmem_ctrl(dmem_ctrl),
      .dmem_rd_en(dmem_rd_en),
      .dmem_addr(dmem_byte_addr));

   byte_to_word #(
      .BYTE_ADDR_WIDTH(IMEM_BYTE_ADDR_WIDTH))
   byte_to_word0 (
      .byte_addr_in(imem_byte_addr),
      .byte_data_in(rx_data),
      .word_addr_out(imem_addr),
      .word_byte_en_out(imem_byte_en),
      .word_data_out(imem_wr_data));
   
   word_to_byte #(
      .BYTE_ADDR_WIDTH(DMEM_BYTE_ADDR_WIDTH))
   word_to_byte0 (
      .byte_addr_in(dmem_byte_addr),
      .byte_data_out(tx_data),
      .word_addr_out(dmem_addr),
      .word_data_in(dmem_rd_data));
   
endmodule
