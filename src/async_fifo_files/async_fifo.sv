`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2025 09:01:07 AM
// Design Name: 
// Module Name: async_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
) (
    input wclk,
    input rclk,
    input reset,
    input write_enable,
    input read_enable,
    input [DATA_WIDTH-1:0] write_data_in,
    
    output [ADDR_WIDTH-1:0] fifo_occu_out,
    output [ADDR_WIDTH-1:0] fifo_occu_in,
    output full,
    output empty,
    output [DATA_WIDTH-1:0] read_data_out
    );
    
    
    wire [ADDR_WIDTH:0] rptr;
    wire [ADDR_WIDTH:0] rptr_sync;
    wire [ADDR_WIDTH:0] wptr;
    wire [ADDR_WIDTH:0] wptr_sync;
    wire wen;
    wire ren; 
    wire [ADDR_WIDTH-1:0] waddr;
    wire [ADDR_WIDTH-1:0] raddr;
    
    
    fifo_read rfifo(
        .rptr(rptr),
        .wptr(wptr_sync),
        .ren(ren),
        .raddr(raddr),
        .rclk(rclk),
        .reset(reset),
        .read_enable(read_enable),
        .fifo_occu_out(fifo_occu_out),
        .empty(empty)
    );
    
    fifo_write wfifo(
        .rptr(rptr_sync),
        .wptr(wptr),
        .wen(wen),
        .waddr(waddr),
        .wclk(wclk),
        .reset(reset),
        .write_enable(write_enable),
        .fifo_occu_in(fifo_occu_in),
        .full(full)
    );
    
    sync wsync(
        .reset(reset),
        .clk_dst(rclk),
        .clk_src(wclk),
        .ptr_in(wptr),
        .ptr_out(wptr_sync)
    );
    
    
    sync rsync(
        .reset(reset),
        .clk_dst(wclk),
        .clk_src(rclk),
        .ptr_in(rptr),
        .ptr_out(rptr_sync)
    );
    
    dual_port_memory ram(
        .write_data_in(write_data_in),
        .read_data_out(read_data_out),
        .waddr(waddr),
        .wen(wen),
        .raddr(raddr),
        .ren(ren),
        .rclk(rclk),
        .wclk(wclk)
    );
    
    
endmodule    
