module pos_edge_detector (
   input  wire clk,
   input  wire rst,
   input  wire signal_in,
   output wire edge_detected);

   reg register;

   always @(posedge clk) begin
      if (rst) register <= 1;
      else register <= signal_in;
   end

   assign edge_detected = ~register & signal_in;

endmodule
