// 1:2 demux — route `din` to `out` when sel=0, to `trash` when sel=1
module demux1to2 #(parameter W = 9) (
    input  logic [W-1:0] din,
    input  logic         sel,
    output logic [W-1:0] out,
    output logic [W-1:0] trash
  );
  assign out   = sel ? '0 : din;    // when sel=1, drive out=0 (or leave high-Z)
  assign trash = sel ? din : '0;    // optional: capture “discarded” data
endmodule
