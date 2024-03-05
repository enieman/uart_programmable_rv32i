module word_to_byte #(
   parameter BYTE_ADDR_WIDTH = 6, // Width of the byte-level address; default to 6 address bits (64 bytes)
   parameter BYTES_PER_WORD = 4,  // Number of bytes in one word; this MUST be a power of 2; default is 4 (32-bit word)
   localparam BYTES_PER_WORD_LOG2 = $clog2(BYTES_PER_WORD),
   localparam BITS_PER_WORD = 8*BYTES_PER_WORD)
(
   input  wire [BYTE_ADDR_WIDTH-1:0]                     byte_addr_in,
   output wire [7:0]                                     byte_data_out,
   output wire [BYTE_ADDR_WIDTH-BYTES_PER_WORD_LOG2-1:0] word_addr_out,
   input  wire [BITS_PER_WORD-1:0]                       word_data_in);
   
   wire [BYTES_PER_WORD_LOG2+2:0] index;
   
   assign index         = { byte_addr_in[BYTES_PER_WORD_LOG2-1:0], 3'b000 };
   assign word_addr_out = byte_addr_in[BYTE_ADDR_WIDTH-1:BYTES_PER_WORD_LOG2];
   assign byte_data_out = word_data_in[index +: 8];
   
endmodule
