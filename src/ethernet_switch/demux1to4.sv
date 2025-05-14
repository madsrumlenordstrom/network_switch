module demux1to4 #(
    parameter int WIDTH = 8
  ) (
    input  logic        [1:0] sel,       // 2-bit select
    input  logic [WIDTH-1:0] data_in,    // data input
    output logic [WIDTH-1:0] data_out0,  // routed output 0
    output logic [WIDTH-1:0] data_out1,  // routed output 1
    output logic [WIDTH-1:0] data_out2,  // routed output 2
    output logic [WIDTH-1:0] data_out3   // routed output 3
  );

  always_comb
  begin
    // default all outputs to zero when disabled or not selected
    data_out0 = '0;
    data_out1 = '0;
    data_out2 = '0;
    data_out3 = '0;

    begin
      case (sel)
        2'd0:
          data_out0 = data_in;
        2'd1:
          data_out1 = data_in;
        2'd2:
          data_out2 = data_in;
        2'd3:
          data_out3 = data_in;
      endcase
    end
  end

endmodule
