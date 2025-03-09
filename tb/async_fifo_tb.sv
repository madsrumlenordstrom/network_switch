`timescale 1ns / 1ps

module async_fifo_tb;
  
    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    logic reset;
    logic wclk;
    logic rclk;
    logic write_enable;
    logic read_enable;
    logic full;
    logic empty;
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
        .full(full),
        .empty(empty),
        .write_data_in(write_data_in),
        .read_data_out(read_data_out)
    );

    // Asynchronous clocks
    always #10ns wclk = ~wclk;
    always #35ns rclk = ~rclk;

    // Variable to hold pushed data
    reg [DATA_WIDTH-1:0] write_data_q[$], write_data;

    // Indicates that test can stop
    logic write_done;

    initial begin
        reset = 1;
        write_done = 0;

        // Reset pulse
        #20 reset = 0;
    end
  
    initial begin
        // Initialize Signals
        wclk = 0;
        write_data_in = 0;
        write_enable = 0;
        #20;

        repeat(5) begin
            for (int i=0; i<100; i++) begin
                @(posedge wclk iff !full);
                write_enable = (i%2 == 0)? 1'b1 : 1'b0;
                if (write_enable) begin
                    write_data_in = $urandom[DATA_WIDTH-1:0];
                    write_data_q.push_back(write_data_in);
                end
            end
            #50;
        end
        write_done = 1;
    end

    initial begin
        // Initialize Signals
        rclk = 0;
        read_enable = 0;
        #20;

        repeat(5) begin
            for (int i=0; i<100; i++) begin
                @(posedge rclk iff !empty || (empty && write_done));
                read_enable = (i%2 == 0)? 1'b1 : 1'b0;
                if (read_enable) begin
                    write_data = write_data_q.pop_front();
                    if(read_data_out !== write_data) $error("Time = %0t: Comparison Failed: expected write_data = %h, read_data_out = %h", $time, write_data, read_data_out);
                    else $display("Time = %0t: Comparison Passed: write_data = %h and read_data_out = %h",$time, write_data, read_data_out);
                end
            end
            #50;
        end
        $finish;
    end

    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars;
    end
endmodule
