`timescale 1ns / 1ps

module mux4to1 #(
    parameter int WIDTH = 8           // width of each data input
  )(
    input  logic [WIDTH-1:0] in0,     // data input 0
    input  logic [WIDTH-1:0] in1,     // data input 1
    input  logic [WIDTH-1:0] in2,     // data input 2
    input  logic [WIDTH-1:0] in3,     // data input 3
    input  logic [3:0]       sel,     // one-hot select signal
    output logic [WIDTH-1:0] out      // mux output
  );

  always_comb
  begin
    unique case (sel)
             4'b0001:
               out = in0;
             4'b0010:
               out = in1;
             4'b0100:
               out = in2;
             4'b1000:
               out = in3;
             default:
               out = '0;  // safe default if no or multiple bits set
           endcase
         end

       endmodule
