`timescale 1ns / 1ps

module fcs_check_parallel_tb;
  
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz clock)
  
    // DUT (Device Under Test) Signals
    logic clk;
    logic reset;
    logic start_of_frame;
    logic end_of_frame;
    logic [7:0] data_in;
    logic fcs_error; // Output from DUT

    // Instantiate DUT
    fcs_check_parallel DUT (
        .clk(clk),
        .reset(reset),
        .start_of_frame(start_of_frame),
        .end_of_frame(end_of_frame),
        .data_in(data_in),
        .fcs_error(fcs_error)
    );

    // Correct data
    byte packet_data_correct [] = '{
        8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12,
        8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h00,
        8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
        8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
        8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
        8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
        8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
        8'h0E, 8'h0F, 8'h10, 8'h11, 8'hE6, 8'hC5, 8'h3D, 8'hB2
    }; 

    // Data but with a random bit flipped
    byte packet_data_incorrect [] = '{
        8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12,
        8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h10,
        8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
        8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
        8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
        8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
        8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
        8'h0E, 8'h0F, 8'h10, 8'h11, 8'hE6, 8'hC5, 8'h3D, 8'hB2
    }; 
    
    // Variables
    int byte_index;

    // Clock Generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    task automatic transmit_packet(input byte data[]);
        begin
            for (byte_index = 0; byte_index < data.size(); byte_index++) begin
                if (byte_index == 0) begin
                    start_of_frame = 1;
                end else if (byte_index == (data.size() - 4)) begin
                    end_of_frame = 1;
                end else begin
                    start_of_frame = 0;
                    end_of_frame = 0;
                end
                data_in = data[byte_index];
                @(negedge clk);
                // $display("Time: %t | Data In: %h | Start: %b | End: %b | FCS Error: %b", 
                //          $time, data_in, start_of_frame, end_of_frame, fcs_error);
            end
            if (fcs_error)
                $display("CRC Error Detected!");
            else
                $display("Frame Passed CRC Check!");
            #CLK_PERIOD;
        end
    endtask

    // Test Sequence
    initial begin
        $dumpfile("fcs_check_parallel_tb.vcd");
        $dumpvars();
        // Initialize Signals
        clk = 0;
        reset = 1;
        start_of_frame = 0;
        end_of_frame = 0;
        data_in = 0;

        // Reset pulse
        #20 reset = 0;

        transmit_packet(packet_data_correct);
        transmit_packet(packet_data_incorrect);

        // End Simulation
        #100;
        $finish;
    end
endmodule
