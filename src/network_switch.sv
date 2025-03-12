module network_switch #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
) (
    input logic reset,
    input logic wclk,
    input logic rclk,
    input logic write_enable,
    input logic read_enable,
    output logic full,
    output logic empty,
    input logic [DATA_WIDTH-1:0] write_data_in,
    output logic [DATA_WIDTH-1:0] read_data_out
);
    async_fifo #(
        DATA_WIDTH,
        ADDR_WIDTH
    ) DUT (
        .reset(reset),
        .wclk(wclk),
        .rclk(rclk),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .full(full),
        .empty(empty),
        .write_data_in(write_data_in),
        .read_data_out(read_data_out)
    );
endmodule
