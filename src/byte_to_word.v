module byte_to_word #(
   parameter BYTE_ADDR_WIDTH = 6) // Width of the byte-level address; default to 6 address bits (64 bytes)
(
   input  wire [BYTE_ADDR_WIDTH-1:0] byte_addr_in,
   input  wire [7:0]                 byte_data_in,
   output reg  [BYTE_ADDR_WIDTH-3:0] word_addr_out,
   output reg  [3:0]                 word_byte_en_out,
   output reg  [31:0]                word_data_out);
   
   always @(*) begin
      word_addr_out = byte_addr_in[BYTE_ADDR_WIDTH-1:2];
      case (byte_addr_in[1:0])
         2'b00: begin
                word_byte_en_out = 4'b0001;
                word_data_out = {24'h00_0000, byte_data_in};
                end
         2'b01: begin
                word_byte_en_out = 4'b0010;
                word_data_out = {16'h0000, byte_data_in, 8'h00};
                end
         2'b10: begin
                word_byte_en_out = 4'b0100;
                word_data_out = {8'h00, byte_data_in, 16'h0000};
                end
         2'b11: begin
                word_byte_en_out = 4'b1000;
                word_data_out = {byte_data_in, 24'h00_0000};
                end
      endcase
   end
   
endmodule
