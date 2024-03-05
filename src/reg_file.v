module reg_file #(
   parameter BYTE_ADDR_WIDTH = 6, // Width of the byte-level address; default to 6 address bits (64 bytes)
   parameter BYTES_PER_WORD = 4,  // Number of bytes in one word; this MUST be a power of 2; default is 4 (32-bit word)
   localparam BYTES_PER_WORD_LOG2 = $clog2(BYTES_PER_WORD),
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
         for (integer unsigned i = 0; i < BYTES_PER_WORD; i++ )
            if (byte_en[i])
               register[{wr_addr, i[BYTES_PER_WORD_LOG2-1:0]}] <= wr_data[8*i +: 8];
      end
   end
   
   // Read Buffers
   always @(posedge clk) begin
      if (rst) begin
         rd_data0 <= {(8*BYTES_PER_WORD){1'b0}};
         rd_data1 <= {(8*BYTES_PER_WORD){1'b0}};
      end
      else begin
         if (rd_en0)
            for (integer unsigned i = 0; i < BYTES_PER_WORD; i++)
               rd_data0[8*i +: 8] <= register[{rd_addr0, i[BYTES_PER_WORD_LOG2-1:0]}];
         if (rd_en1)
            for (integer unsigned i = 0; i < BYTES_PER_WORD; i++)
               rd_data1[8*i +: 8] <= register[{rd_addr1, i[BYTES_PER_WORD_LOG2-1:0]}];
      end
   end

endmodule
