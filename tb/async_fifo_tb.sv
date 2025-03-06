`timescale 1ns / 1ps

module async_fifo_tb;
  
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz clock)
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    logic reset;
    logic wclk;
    logic rclk;
    logic write_enable;
    logic read_enable;
    logic [ADDR_WIDTH:0] fifo_occu_in;
    logic [ADDR_WIDTH:0] fifo_occu_out;
    logic [DATA_WIDTH-1:0] write_data_in;
    logic [DATA_WIDTH-1:0] read_data_out;

    async_fifo #(
      DATA_WIDTH,
      ADDR_WIDTH
    ) DUT (
      .reset(reset),
      .wclk(wclk),
      .rclk(rclk),
      .write_enable(write_enable),
      .read_enable(read_enable),
      .fifo_occu_in(fifo_occu_in),
      .fifo_occu_out(fifo_occu_out),
      .write_data_in(write_data_in),
      .read_data_out(read_data_out)
    );
  
    initial begin
      $display("TODO");
      $finish;
    end
endmodule
