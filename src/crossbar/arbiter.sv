// ############################################################################
//  Module: arbiter
//  Description: This module implements a round-robin arbiter 
//               with grant holding.
//  Parameters: P_WIDTH - Number of requests (default: 3)
// ############################################################################

module arbiter #(
  parameter int P_WIDTH = 3 // Number of requests
) (
  input  logic               clk_i,
  input  logic               rstn_i,
  input  logic [P_WIDTH-1:0] request_i,
  output logic [P_WIDTH-1:0] grant_o
);
  // Signals
  logic [P_WIDTH-1:0]        last_grant; 
  logic [P_WIDTH-1:0]        cur_priority;
  logic [P_WIDTH*2-1:0]      carry_chain;
  logic [P_WIDTH-1:0]        temp_grant;
  logic [P_WIDTH-1:0]        hold;
  logic [P_WIDTH - 1:0]      next_priority;

  // Carry
  always_comb begin // Avoid cyclic carry_chain chain, double the arbiter slices and OR outputs
    for (int i = 0; i < (P_WIDTH*2); i++) begin
      if (i == 0) carry_chain[i] = 0; // Carry lsb is always 0
      else        carry_chain[i] = (~request_i[(i-1)%P_WIDTH] & (carry_chain[i-1] | cur_priority[(i-1)%P_WIDTH]));
      // Modulo P_WIDTH used for indexing because the doubled (unfolded) carry chain (prio and req indexing will start over))
    end
  end

  // Temporary grant    (Split into two parts because of carry_chain size)
  assign temp_grant = (request_i & (carry_chain[P_WIDTH*2-1:P_WIDTH] | cur_priority)) | (request_i & (carry_chain[P_WIDTH-1:0] | cur_priority));

  // Hold and grant
  assign hold = request_i & last_grant;
  assign grant_o = (|hold) ? hold : temp_grant;

  // Round-Robin Next priority
  assign next_priority = (|grant_o) ? {grant_o[P_WIDTH-2:0], grant_o[P_WIDTH-1]} : cur_priority;

  // Sequential
  always_ff @(posedge clk_i) begin
    if(!rstn_i) begin
      last_grant   <= 0;
      cur_priority <= 1; // Reset priority to ..01
    end else begin
      last_grant   <= grant_o; // Register for last_grant
      cur_priority <= next_priority; // Register for priority
    end
  end

endmodule
