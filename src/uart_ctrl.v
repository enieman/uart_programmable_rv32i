module uart_ctrl #(
   parameter IMEM_BYTE_ADDR_WIDTH = 6, // 64 bytes of storage
   parameter DMEM_BYTE_ADDR_WIDTH = 6) // 64 bytes of storage
(
   input  wire clk,
   input  wire rst,
   input  wire rx_ready,
   input  wire tx_empty,
   input  wire tx_error,
   output wire cpu_rst,
   output reg  tx_req,
   output wire imem_ctrl,
   output wire imem_wr_en,
   output reg  [IMEM_BYTE_ADDR_WIDTH-1:0] imem_addr,
   output wire dmem_ctrl,
   output wire dmem_rd_en,
   output reg  [DMEM_BYTE_ADDR_WIDTH-1:0] dmem_addr);

   // Local Parameters
   localparam NUM_IMEM_BYTES = 2**IMEM_BYTE_ADDR_WIDTH;
   localparam NUM_DMEM_BYTES = 2**DMEM_BYTE_ADDR_WIDTH;
   
   // States
   localparam STATE_RESET = 2'b00;
   localparam STATE_DATA_WRITE = 2'b01;
   localparam STATE_IDLE = 2'b10;
   localparam STATE_DATA_READ = 2'b11;

   // Declare intermediate wires
   wire rd_complete, wr_data_ready, all_imem_written, tx_ready;
   reg [1:0] state;

   // Assign intermediate wires
   /* verilator lint_off WIDTHEXPAND */
   assign rd_complete = ((state == STATE_DATA_READ) && (dmem_addr == NUM_DMEM_BYTES-1) && dmem_rd_en) ? 1'b1 : 1'b0;
   assign all_imem_written = ((state == STATE_DATA_WRITE) && (imem_addr == NUM_IMEM_BYTES-1) && imem_wr_en) ? 1'b1 : 1'b0;
   /* verilator lint_on WIDTHEXPAND */
   
   // Write Data from UART RX Ready
   pos_edge_detector wr_data_ready_detect (
      .clk(clk),
      .rst(rst),
      .signal_in(rx_ready),
      .edge_detected(wr_data_ready));
   
   // Ready to read data from D-Memory
   pos_edge_detector tx_ready_detect (
      .clk(clk),
      .rst(rst),
      .signal_in((state == STATE_DATA_READ) & tx_empty),
      .edge_detected(tx_ready));

   // State machine logic
   always @(posedge clk) begin
      if (rst) state <= STATE_RESET;
      else begin
         case (state)
            STATE_RESET:      if (!rst)             state <= STATE_DATA_WRITE;
            STATE_DATA_WRITE: if (all_imem_written) state <= STATE_IDLE;
            STATE_IDLE:       if (wr_data_ready)    state <= STATE_DATA_READ;
            STATE_DATA_READ:  if (rd_complete)      state <= STATE_IDLE;
         endcase
      end // else
   end // always_ff

   // I-Memory Address Counter
   always @(posedge clk) begin
      if (rst) imem_addr <= '0;
      else if (state == STATE_RESET) imem_addr <= '0;
      else if (state == STATE_IDLE)  imem_addr <= '0;
      else if (state == STATE_DATA_WRITE && imem_wr_en) imem_addr <= imem_addr + 1;
   end //always_ff

   // D-Memory Address Counter
   always @(posedge clk) begin
      if (rst) dmem_addr <= '0;
      else if (state == STATE_RESET) dmem_addr <= '0;
      else if (state == STATE_IDLE)  dmem_addr <= '0;
      else if (state == STATE_DATA_READ && tx_req) dmem_addr <= dmem_addr + 1;
   end //always_ff
   
   // Delay TX Request One Cycle from D-Mem Read Enable
   always @(posedge clk) begin
      if (rst) tx_req <= 1'b0;
      else tx_req <= dmem_rd_en;
   end

   // Connect outputs
   assign cpu_rst    = (state == STATE_RESET || state == STATE_DATA_WRITE || rst) ? 1'b1 : 1'b0;
   assign imem_ctrl  = cpu_rst;
   assign dmem_ctrl  = cpu_rst;
   assign dmem_rd_en = (state == STATE_DATA_READ && tx_ready) ? 1'b1 : 1'b0;
   assign imem_wr_en = (state == STATE_DATA_WRITE && wr_data_ready) ? 1'b1 : 1'b0;
   // assign tx_req     = dmem_rd_en;

endmodule
