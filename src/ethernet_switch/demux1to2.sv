module demux1to2 #(parameter W = 9) (
	 input  logic clk,
    input  logic [W-1:0] din,
    input  logic         sel,
    output logic [W-1:0] out,
    output logic [W-1:0] trash
  );
  
  
  logic d_sel;
  always @(posedge clk) begin
   $display("DEMUX1TO2: At time = %0d, trash = %0h",$time, trash);
	d_sel <= sel;  
  end

  
assign out   = (d_sel == 1'b1) ? din : '0;
assign trash = (d_sel == 1'b0) ? din : '0;

  
  
endmodule
