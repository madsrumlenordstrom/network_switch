
module dual_port_memory #(
    parameter BIT_SIZE = 10
) (
    input rclk, wclk, wen, ren, wea,
    input [BIT_SIZE-1:0] waddr, raddr,
    input [BIT_SIZE-1:0] write_data_in,
    output reg [15:0] read_data_out
);

reg [15:0] ram [(1 << BIT_SIZE) - 1:0];

always @(posedge wclk) begin
if (wen)
    ram[waddr] <= write_data_in;
end

always @(posedge rclk) begin
if (ren)
    read_data_out <= ram[raddr];
end

endmodule