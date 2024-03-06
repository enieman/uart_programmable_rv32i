module word_to_byte #(
   parameter BYTE_ADDR_WIDTH = 6) // Width of the byte-level address; default to 6 address bits (64 bytes)
(
   input  wire [BYTE_ADDR_WIDTH-1:0] byte_addr_in,
   output reg  [7:0]                 byte_data_out,
   output reg  [BYTE_ADDR_WIDTH-3:0] word_addr_out,
   input  wire [31:0]                word_data_in);
   
   always @(*) begin
      word_addr_out = byte_addr_in[BYTE_ADDR_WIDTH-1:2];
      case (byte_addr_in[1:0])
         2'b00: byte_data_out = word_data_in[7:0];
         2'b01: byte_data_out = word_data_in[15:8];
         2'b10: byte_data_out = word_data_in[23:16];
         2'b11: byte_data_out = word_data_in[31:24];
      endcase
   end
   
endmodule
