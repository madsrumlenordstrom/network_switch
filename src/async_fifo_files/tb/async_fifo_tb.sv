`timescale 1ns / 1ps

module async_fifo_tb;
  
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz clock)
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 5;

    logic reset;
    logic wclk;
    logic rclk;
    logic full;
    logic empty;
    logic [ADDR_WIDTH:0] fifo_occu_in;
    logic [ADDR_WIDTH:0] fifo_occu_out;
    logic [DATA_WIDTH-1:0] write_data_in;
    logic [DATA_WIDTH-1:0] read_data_out;

    wire write_enable = full ? 0 : 1;
    wire read_enable = empty ? 0 : 1;

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
      .read_data_out(read_data_out),
      .full(full),
      .empty(empty)
    );
    
    byte packet_data [] = '{
        8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12,
        8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h00,
        8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
        8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
        8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
        8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
        8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
        8'h0E, 8'h0F, 8'h10, 8'h11, 8'hE6, 8'hC5, 8'h3D, 8'hB2
    }; 
    
    int byte_index;
    int counter;
    
    always #(CLK_PERIOD/2) wclk = ~wclk;
    always #(CLK_PERIOD) rclk = ~rclk; 
    
    task automatic two_to_one_data(input byte data[]);
        begin
            for (byte_index = 0; byte_index < data.size(); byte_index++) begin
                write_data_in = data[byte_index];
                @(posedge rclk);
                 $display("Time: %t | Data In: %b | Empty flag: %b | Full flag: %b |  FIFO Occupancy In: %b,  FIFO Occupancy Out: %b", 
                          $time, write_data_in, empty, full, fifo_occu_in, fifo_occu_out);

            end
        $display();
        end
        #CLK_PERIOD;
    endtask              
                
                
  
    initial begin
      $dumpfile("async_fifo_tb.vcd");
      $dumpvars();
      // Initialize signals 
      // wclk will be 2 times faster than write clock
      wclk = 0;
      rclk = 0;
      reset = 1;
      
      // Reset
      #20 reset = 0;
      
      two_to_one_data(packet_data);
      
      $finish;
    end
endmodule