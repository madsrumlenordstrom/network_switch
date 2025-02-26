`timescale 1ns / 1ps

module serial_crc_tb;
  
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz clock)
  
    // DUT (Device Under Test) Signals
    logic clk;
    logic reset;
    logic start_of_frame;
    logic end_of_frame;
    logic data_in;
    logic fcs_error; // Output from DUT

    // Instantiate DUT
    serial_crc #(.packet_byte_size_max(89)) DUT (
        .clk(clk),
        .reset(reset),
        .start_of_frame(start_of_frame),
        .end_of_frame(end_of_frame),
        .data_in(data_in),
        .fcs_error(fcs_error)
    );

    // Hexadecimal sequence (original data)
    byte packet_data [0:67] = '{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
                                8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12,
                                8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h00,
                                8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
                                8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
                                8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
                                8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
                                8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
                                8'h0E, 8'h0F, 8'h10, 8'h11 }; // 51 Bytes in total
                                
    byte packet_remaineder[0:3] = '{8'hE6, 8'hC5, 8'h3D, 8'hB2}; 
    
    // Variables
    int bit_index = 0;
    int byte_index = 0;

    // Clock Generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Task to transmit data bit by bit
    task transmit_packet;
        begin
            start_of_frame = 1; // Indicate start of frame
            @(posedge clk);
            start_of_frame = 0;

            for (byte_index = 0; byte_index < $size(packet_data); byte_index++) begin
                for (bit_index = 7; bit_index >= 0; bit_index--) begin
                    data_in = packet_data[byte_index][bit_index]; // Send LSB first
                    @(posedge clk); // Wait for one clock cycle
                end
            end
            
            byte_index = 0;
            bit_index = 0;
            end_of_frame = 1; // Indicate end of frame
            
            for (byte_index = 0; byte_index < $size(packet_remaineder); byte_index++) begin
                for (bit_index = 7; bit_index >= 0; bit_index--) begin
                    data_in = packet_remaineder[byte_index][bit_index]; // Send LSB first
                    @(posedge clk); // Wait for one clock cycle
                    end_of_frame = 0;
                end
            end
            
            @(posedge clk);
            
        end
    endtask

    // Test Sequence
    initial begin
        // Initialize Signals
        clk = 0;
        reset = 1;
        start_of_frame = 0;
        end_of_frame = 0;
        data_in = 0;

        // Reset pulse
        #20 reset = 0;

        // Start transmitting data
        transmit_packet();

        // Wait for CRC processing to complete
        #100000;

        // Check if FCS error is detected
        if (!fcs_error)
            $display("CRC Error Detected!");
        else
            $display("Frame Passed CRC Check!");

        // End Simulation
        #100;
        $finish;
    end

    // Monitor Output
    initial begin
        $monitor("Time: %t | Data In: %b | Start: %b | End: %b | FCS Error: %b", 
                 $time, data_in, start_of_frame, end_of_frame, fcs_error);
    end

endmodule
