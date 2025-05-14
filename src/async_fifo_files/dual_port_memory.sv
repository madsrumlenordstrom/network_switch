
module dual_port_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
) (
    input rclk, wclk, wen, ren,
    input [ADDR_WIDTH-1:0] waddr, raddr,
    input [DATA_WIDTH-1:0] write_data_in,
    output reg [DATA_WIDTH-1:0] read_data_out
);

reg [DATA_WIDTH-1:0] ram [(1 << ADDR_WIDTH) - 1:0];

always @(posedge wclk) begin
if (wen)
    ram[waddr] <= write_data_in;
end

always @(posedge rclk) begin
if (ren)
    read_data_out <= ram[raddr];
end

endmodule