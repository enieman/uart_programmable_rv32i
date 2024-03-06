module reg_file #(
   parameter BYTE_ADDR_WIDTH = 6, // Width of the byte-level address; default to 6 address bits (64 bytes)
   localparam NUM_BYTES = 2**BYTE_ADDR_WIDTH)
(
   input  wire clk,
   input  wire rst,
   // Read Channel 0
   input  wire rd_en0,
   input  wire [BYTE_ADDR_WIDTH-3:0] rd_addr0,
   output reg  [31:0] rd_data0,
   // Read Channel 1
   input  wire rd_en1,
   input  wire [BYTE_ADDR_WIDTH-3:0] rd_addr1,
   output reg  [31:0] rd_data1,
   // Write Channel
   input  wire wr_en,
   input  wire [BYTE_ADDR_WIDTH-3:0] wr_addr,
   input  wire [3:0] byte_en,
   input  wire [31:0] wr_data);
   
   reg [7:0] register [NUM_BYTES];
   
   // Register File
   always @(posedge clk) begin
      if (rst)
         for (integer unsigned i = 0; i < NUM_BYTES; i++)
            register[i] = 8'h00;
      else if (wr_en) begin
         if (byte_en[3]) register[{wr_addr, 2'b11}] <= wr_data[31:24];
         if (byte_en[2]) register[{wr_addr, 2'b10}] <= wr_data[23:16];
         if (byte_en[1]) register[{wr_addr, 2'b01}] <= wr_data[15:8];
         if (byte_en[0]) register[{wr_addr, 2'b00}] <= wr_data[7:0];
      end
   end
   
   // Read Buffers
   always @(posedge clk) begin
      if (rst) begin
         rd_data0 <= 32'h0000_0000;
         rd_data1 <= 32'h0000_0000;
      end
      else begin
         if (rd_en0) rd_data0 <= {
            register[{rd_addr0, 2'b11}],
            register[{rd_addr0, 2'b10}],
            register[{rd_addr0, 2'b01}],
            register[{rd_addr0, 2'b00}]};
         if (rd_en1) rd_data1 <= {
            register[{rd_addr1, 2'b11}],
            register[{rd_addr1, 2'b10}],
            register[{rd_addr1, 2'b01}],
            register[{rd_addr1, 2'b00}]};
      end
   end

endmodule
