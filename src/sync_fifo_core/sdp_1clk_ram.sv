// Module: Simple dual port RAM with single clock
// Parameters:
//   - P_DATA_WIDTH: Width of the words in RAM (default 32)
//   - P_ADDR_WIDTH: Width of the address for the RAM

module sdp_1clk_ram #(
  parameter int P_DATA_WIDTH = 8,
  parameter int P_ADDR_WIDTH = 4
) (
  // Clocks
  input  logic clk_i,
  // Write port
  input  logic wr_i,
  input  logic [P_ADDR_WIDTH-1:0] addr_wr_i,
  input  logic [P_DATA_WIDTH-1:0] data_wr_i,
  // Read port
  input  logic rd_i,
  input  logic [P_ADDR_WIDTH-1:0] addr_rd_i,
  output logic [P_DATA_WIDTH-1:0] data_rd_o
); 
  // RAM STYLE (Attribute for Quartus) can also be "MLAB", "M144K" or "logic" (used "M9K")
  (* ramstyle = "M10K" *) logic [P_DATA_WIDTH-1:0] ram [2**P_ADDR_WIDTH];

  always_ff @(posedge clk_i) begin
    if (wr_i) ram[addr_wr_i] <= data_wr_i;
    if (rd_i) data_rd_o <= ram[addr_rd_i];
  end
  
endmodule