module keccak_avst(clk, reset, data_in, end_in, valid_in, ready_in,
		   data_out, end_out, valid_out, ready_out);

   input 	clk;
   input 	reset;

   input [7:0] 	data_in;
   input 	end_in;
   input 	valid_in;
   output 	ready_in;

   output [7:0] data_out;
   output 	end_out;
   output 	valid_out;
   input 	ready_out;
		
   reg 		in_ready; // To dut of keccak.v
   reg 		stage; // toggles to 1 once the output is ready
   reg 		valid_out;
   reg 		end_out;

   reg [5:0] 	count_out; 
   
   reg 		ready_in; 
   wire 	buffer_full; // From dut of keccak.v
   wire [511:0] out; // From dut of keccak.v
   wire 	out_ready; // From dut of keccak.v
   
   reg [511:0] 	out_reg;

   wire [7:0] 	data_out;

   assign data_out = out_reg[511:504];
   
   always @(posedge clk)
      if (reset)
	 ready_in <= 1;
      else
	ready_in <= end_out | ((~ end_in) & ready_in);

   always @(posedge clk) begin
      if(reset) begin
	 out_reg <= 0;
	 stage <= 0;
	 count_out <= 0;
	 valid_out <= 0;
	 end_out <= 0;
      end
      else if(stage == 1) begin
	 if(ready_out) begin
	    out_reg[511:0] <= {out_reg[503:0], 8'h00};
	    if(count_out == 'h3f) begin
	       count_out <= 0;
	       stage <= 0;
	       valid_out <= 0;
	       end_out <= 1;
	    end
	    else begin
	       count_out <= count_out + 1;
	       end_out <= 0;
	    end
	 end
      end
      else begin
	 if(out_ready) begin
	    valid_out <= 1;
	    out_reg <= out;
	    stage <= 1;
	 end
      end
   end

   keccak dut (
	       .in			(data_in[7:0]),
	       .clk			(clk),
	       .reset			(reset),
	       .in_ready		(valid_in),
	       .is_last			(end_in),
	       /*AUTOINST*/
	       // Outputs
	       .buffer_full		(buffer_full),
	       .out			(out[511:0]),
	       .out_ready		(out_ready));
	       // Inputs
endmodule
  
