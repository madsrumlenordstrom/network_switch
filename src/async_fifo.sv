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
    output logic [ADDR_WIDTH:0] fifo_occu_in, // Check width
    output logic [ADDR_WIDTH:0] fifo_occu_out, // Check width
    input logic [DATA_WIDTH-1:0] write_data_in,
    output logic [DATA_WIDTH-1:0] read_data_out
);
    // Write clock domain signals
    logic wen;
    logic [ADDR_WIDTH-1:0] waddr;
    logic [ADDR_WIDTH:0] wptr;
    logic [ADDR_WIDTH:0] rptr_sync;

    // Read clock domain signals
    logic ren;
    logic [ADDR_WIDTH-1:0] raddr;
    logic [ADDR_WIDTH:0] rptr;
    logic [ADDR_WIDTH:0] wptr_sync;

    // Synchronizers
    data_synchronizer #(
        ADDR_WIDTH + 1
    ) wptr_synchronizer (
        .data_in(wptr),
        .clk_in(wclk),
        .data_out(wptr_sync),
        .clk_out(rclk)
    );

    data_synchronizer #(
        ADDR_WIDTH + 1
    ) rptr_synchronizer (
        .data_in(rptr),
        .clk_in(rclk),
        .data_out(rptr_sync),
        .clk_out(wclk)
    );

    logic [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    logic full;
    logic empty;
    logic fifo_occupancy;

    always_comb begin
        waddr = wptr[ADDR_WIDTH-1:0];
        raddr = rptr[ADDR_WIDTH-1:0];
        // full = (waddr == raddr) && (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]); // maybe remove since not sync
        // empty = (waddr == raddr) && (wptr[ADDR_WIDTH] == rptr[ADDR_WIDTH]); // maybe remove since not sync
        if (wptr[ADDR_WIDTH] == rptr_sync[ADDR_WIDTH]) begin
            fifo_occu_in = wptr[ADDR_WIDTH-1:0] - rptr_sync[ADDR_WIDTH-1:0];
        end else begin
            fifo_occu_in = (1<<ADDR_WIDTH) - (rptr_sync[ADDR_WIDTH-1:0] - wptr[ADDR_WIDTH-1:0]);
        end

        if (wptr_sync[ADDR_WIDTH] == rptr[ADDR_WIDTH]) begin
            fifo_occu_out = wptr_sync[ADDR_WIDTH-1:0] - rptr[ADDR_WIDTH-1:0];
        end else begin
            fifo_occu_out = (1<<ADDR_WIDTH) - (rptr[ADDR_WIDTH-1:0] - wptr_sync[ADDR_WIDTH-1:0]);
        end
    end

    // Write operation
    always_ff @(posedge wclk) begin
        if (wen) begin
            ram[waddr] <= write_data_in;
            wptr <= wptr + 1;
        end
    end

    // Read operation
    always_ff @(posedge rclk) begin
        if (ren) begin
            // Maybe only rptr should be updated in
            // Does is make sense to put read data in register???
            read_data_out <= ram[raddr];
            rptr <= rptr + 1;
        end
    end
endmodule
