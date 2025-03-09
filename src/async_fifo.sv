`timescale 1ns / 1ps

module async_fifo #(
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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Write clock domain signals
    logic [ADDR_WIDTH-1:0] waddr;
    logic [PTR_WIDTH-1:0] wptr;
    logic [PTR_WIDTH-1:0] rptr_sync;
    logic [ADDR_WIDTH-1:0] raddr_sync;

    // Read clock domain signals
    logic [ADDR_WIDTH-1:0] raddr;
    logic [PTR_WIDTH-1:0] rptr;
    logic [PTR_WIDTH-1:0] wptr_sync;
    logic [ADDR_WIDTH-1:0] waddr_sync;

    // Synchronizers
    data_synchronizer #(
        PTR_WIDTH
    ) wptr_synchronizer (
        .data_in(wptr),
        .clk_in(wclk),
        .data_out(wptr_sync),
        .clk_out(rclk)
    );

    data_synchronizer #(
        PTR_WIDTH
    ) rptr_synchronizer (
        .data_in(rptr),
        .clk_in(rclk),
        .data_out(rptr_sync),
        .clk_out(wclk)
    );

    logic [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    always_comb begin
        waddr = wptr[ADDR_WIDTH-1:0];
        raddr = rptr[ADDR_WIDTH-1:0];

        waddr_sync = wptr_sync[ADDR_WIDTH-1:0];
        raddr_sync = rptr_sync[ADDR_WIDTH-1:0];

        full = (waddr == raddr_sync) && (wptr[PTR_WIDTH-1] != rptr_sync[PTR_WIDTH-1]);
        empty = (waddr_sync == raddr) && (wptr_sync[PTR_WIDTH-1] == rptr[PTR_WIDTH-1]);

        read_data_out = ram[raddr];
    end

    // Write operation
    always_ff @(posedge wclk or posedge reset) begin
        if (reset) begin
            wptr <= 0;
        end else if (write_enable && !full) begin
            ram[waddr] <= write_data_in;
            wptr <= wptr + 1;
        end
    end

    // Read operation
    always_ff @(posedge rclk or posedge reset) begin
        if (reset) begin
            rptr <= 0;
        end else if (read_enable && !empty) begin
            rptr <= rptr + 1;
        end
    end
endmodule
