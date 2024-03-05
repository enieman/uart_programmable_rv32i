module synchronizer (
   input  wire clk,    //your local clock
   input  wire async,  //unsynchronized signal
   output wire sync); //synchronized signal

   // Create a signal buffer
   reg [1:0] buff;

   always_ff @ (posedge clk) 
      buff <= {buff[0], async};

   assign sync = buff[1];

endmodule
