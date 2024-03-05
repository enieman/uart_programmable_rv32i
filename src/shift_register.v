module shift_register #(
   parameter NUM_BITS = 8,
   parameter RST_VALUE = 0)
(
   input  wire clk,
   input  wire rst,
   input  wire serial_in,
   input  wire shift_enable,
   input  wire [NUM_BITS-1:0] parallel_in,
   input  wire load_enable,
   output wire serial_out,
   output wire [NUM_BITS-1:0] parallel_out);

   reg [NUM_BITS-1:0] register;

   always @(posedge clk) begin
      if (rst) register <= RST_VALUE[NUM_BITS-1:0];
      else if (load_enable) register <= parallel_in;
      else if (shift_enable) begin
         for (integer unsigned i = 0; i < NUM_BITS-1; i++) register[i] <= register[i+1];
         register[NUM_BITS-1] <= serial_in;
      end
   end

   assign parallel_out = register;
   assign serial_out = register[0];

endmodule
