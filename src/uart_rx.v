module uart_rx #(
   parameter COUNTER_WIDTH = 24)
(
   input  wire clk,
   input  wire rst,
   input  wire uart_rx_in,
   output wire [7:0] data,                         // Valid only when "ready" is high, undefined otherwise
   output reg  [COUNTER_WIDTH-1:0] cycles_per_bit, // Length of the first packet starting bit in clock cycles
   output wire ready);                             // Held high for duration of STOP bit, low all other times

   // States
   localparam STATE_IDLE  = 4'h0;
   localparam STATE_START = 4'h1;
   localparam STATE_D0    = 4'h2;
   localparam STATE_D1    = 4'h3;
   localparam STATE_D2    = 4'h4;
   localparam STATE_D3    = 4'h5;
   localparam STATE_D4    = 4'h6;
   localparam STATE_D5    = 4'h7;
   localparam STATE_D6    = 4'h8;
   localparam STATE_D7    = 4'h9;
   localparam STATE_STOP  = 4'hA;

   // Declare intermediate wires
   reg baud_rate_known;
   reg [COUNTER_WIDTH-1:0] counter_val;
   reg [3:0] state;
   wire uart_rx_in_synced, start_detected, rising_edge, timer_rst, half_bit, full_bit, shift_en;

   // Upon Reset, Baud Rate is not known
   always @(posedge clk) begin
      if (rst) baud_rate_known <= 1'b0;
      else if ((state == STATE_STOP) && (start_detected || full_bit)) baud_rate_known <= 1'b1;
   end

   // Connect synchronizer
   synchronizer uart_rx_in_synchronizer(
      .clk(clk),
      .async(uart_rx_in),
      .sync(uart_rx_in_synced));

   // Connect edge detectors
   neg_edge_detector start_detector(
      .clk(clk),
      .rst(rst),
      .signal_in(uart_rx_in_synced),
      .edge_detected(start_detected));
   pos_edge_detector rising_edge_detector(
      .clk(clk),
      .rst(rst),
      .signal_in(uart_rx_in_synced),
      .edge_detected(rising_edge));

   // Connect shift register
   assign shift_en = ((state > STATE_START) && (state < STATE_STOP) && half_bit && baud_rate_known) ? 1'b1:1'b0;
   shift_register #(
      .NUM_BITS(8),
      .RST_VALUE(0))
   shift_reg(
      .clk(clk),
      .rst(rst),
      .serial_in(uart_rx_in_synced),
      .shift_enable(shift_en),
      .parallel_in(8'h0),
      .load_enable(1'b0),
      .serial_out(),
      .parallel_out(data));

   // Implement timer
   assign timer_rst = ((state == STATE_IDLE) || (state == STATE_STOP && start_detected) || full_bit || rst) ? 1'b1:1'b0;
   assign half_bit = counter_val == cycles_per_bit >> 1 ? 1'b1 : 1'b0;
   assign full_bit = (counter_val >= cycles_per_bit) || (state == STATE_START && !baud_rate_known && rising_edge) ? 1'b1 : 1'b0;
   always @(posedge clk) begin
      if (rst) cycles_per_bit <= {COUNTER_WIDTH{1'b1}};
      else if (state == STATE_START && rising_edge) cycles_per_bit <= counter_val;
   end
   always @(posedge clk) begin
      if (timer_rst) counter_val <= '0;
      else counter_val <= counter_val + 1;
   end

   // State machine logic
   always @(posedge clk) begin
      if (rst || (state > STATE_STOP)) state <= STATE_IDLE;
      else if (start_detected && (state == STATE_IDLE || state == STATE_STOP)) state <= STATE_START;
      else if (full_bit)
         case (state)
            STATE_START:    state <= STATE_D0;
            STATE_D0:       state <= STATE_D1;
            STATE_D1:       state <= STATE_D2;
            STATE_D2:       state <= STATE_D3;
            STATE_D3:       state <= STATE_D4;
            STATE_D4:       state <= STATE_D5;
            STATE_D5:       state <= STATE_D6;
            STATE_D6:       state <= STATE_D7;
            STATE_D7:       state <= STATE_STOP;
            STATE_STOP:     state <= STATE_IDLE;
            default:        state <= state;
         endcase
   end

   // Connect outputs
   assign ready = (state == STATE_STOP && baud_rate_known) ? 1'b1:1'b0;

endmodule
