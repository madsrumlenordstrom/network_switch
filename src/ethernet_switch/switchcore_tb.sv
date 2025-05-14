`timescale 1ns/1ps

module switchcore_tb;
  // Parameters
  parameter int P_ADDR_WIDTH = 7;
  parameter CLK_PERIOD = 10; // 10ns clock period (100MHz clock)
  localparam int PACKET_LEN = 64;
  localparam int PACKET0_LEN = 114;

// 64-byte test packet (including FCS E6 C5 3D B2) 
    logic [7:0] packet_data_array0 [0:PACKET_LEN-1] = '{
        8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12,
        8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h00,
        8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
        8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
        8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
        8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
        8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
        8'h0E, 8'h0F, 8'h10, 8'h11, 8'hE6, 8'hC5, 8'h3D, 8'hB2
    }; 


	 // 64-byte test packet (including FCS 1F F3 C6 0D) has the same dst address as the src address of packet_data_array0
logic [7:0] packet_data_array1 [0:63] = '{
		8'h00, 8'h12, 8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 
		8'h45, 8'h00, 8'h00, 8'h2E, 8'h08, 8'h00, 8'h45, 8'h00, 
		8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11, 
		8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8, 
		8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A, 
		8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 
		8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
		8'h0E, 8'h0F, 8'h10, 8'h11, 8'h1F, 8'hF3, 8'hC6, 8'h0D
};



	 // 64-byte test packet (including FCS D6 FE 75 54) has the same dst address as the src address of packet_data_array0
logic [7:0] packet_data_array3 [0:63] = '{
    8'h00, 8'h12, 8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h2E, 8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'hFF, 8'hFF, 8'h40, 8'hFF, 8'hA8, 8'hFF, 8'h2C, 8'hC0, 8'hFF, 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A, 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F, 8'h10, 8'h11, 8'hD6, 8'hFE, 8'h75, 8'h54
};

	 // 64-byte test packet (including FCS D6 0A D5 4A), broadcasts
logic [7:0] packet_data_array4 [0:63] = '{
    8'h00, 8'h12, 8'h34, 8'hEE, 8'hEE, 8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h2E, 8'hEE, 8'hEE, 8'h45, 8'h00, 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hA8, 8'hFF, 8'h2C, 8'hC0, 8'hFF, 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A, 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F, 8'h10, 8'h11, 8'hD6, 8'h0A, 8'hD5, 8'h4A
};


	// 114-byte test packet (including FCS B4 38 56 E5) has the same dst address as the src address of packet_data_array1
logic [7:0] packet_data_array2 [0:113] = '{
    8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h2E, 8'h08, 8'h22, 8'h22, 8'h00, 8'h00, 8'h2E, 8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11, 8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8, 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A, 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h01, 8'h22, 8'h19, 8'h02, 8'h32, 8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11, 8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8, 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A, 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h01, 8'h22, 8'h19, 8'h02, 8'h32, 8'hB4, 8'h38, 8'h56, 8'hE5     
};

    // Data but with a random bit flipped
    logic [7:0] packet_data_array0_incorrect [0:PACKET_LEN-1] = '{
        8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12, 8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h10, 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11, 8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8, 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A, 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F, 8'h10, 8'h11, 8'hE6, 8'hC5, 8'h3D, 8'hB2
    }; 






  // Clock and reset
  logic clk;
  logic reset;

  // Link sync signals
  logic [3:0] link_sync;

  // RX interface
  logic [31:0] rx_data;
  logic [3:0]  rx_ctrl;

  // TX interface (outputs)
  logic [31:0] tx_data;
  logic [3:0]  tx_ctrl;
  

  // Instantiate DUT
  switchcore_top #(
               .P_ADDR_WIDTH(P_ADDR_WIDTH)
             ) uut (
               .clk       (clk),
               .reset     (reset),
               .link_sync (link_sync),
               .tx_data   (tx_data),
               .tx_ctrl   (tx_ctrl),
               .rx_data   (rx_data),
               .rx_ctrl   (rx_ctrl)
             );

// Variables
    int byte_index;

    // Clock Generation
    always #(CLK_PERIOD / 2) clk = ~clk;

task automatic transmit_longer_packet(input logic [7:0] data[0:PACKET0_LEN-1], input int lane );
        begin
            for (byte_index = 0; byte_index < PACKET0_LEN; byte_index++) begin
                @(negedge clk);
                if (byte_index == 0) begin
                    rx_ctrl[lane] = 1;
                end else if (byte_index < (PACKET0_LEN - 4)) begin
                    rx_ctrl[lane] = 1;
                end else if (byte_index == (PACKET0_LEN - 4)) begin
                    rx_ctrl[lane] = 0;
                end else begin
                    rx_ctrl[lane] = 0;
                end	
                rx_data[8*lane +: 8] = data[byte_index];
                // $display("Time: %t | Data In: %h | Start: %b | End: %b | FCS Error: %b", 
                //          $time, data_in, start_of_frame, end_of_frame, fcs_error);
            end
            @(negedge clk);
        end
    endtask


task automatic transmit_packet(input logic [7:0] data[0:PACKET_LEN-1], input int lane );
        begin
            for (byte_index = 0; byte_index < PACKET_LEN; byte_index++) begin
                @(negedge clk);
                if (byte_index == 0) begin
                    rx_ctrl[lane] = 1;
                end else if (byte_index < (PACKET_LEN - 4)) begin
                    rx_ctrl[lane] = 1;
                end else if (byte_index == (PACKET_LEN - 4)) begin
                    rx_ctrl[lane] = 0;
                end else begin
                    rx_ctrl[lane] = 0;
                end	
                rx_data[8*lane +: 8] = data[byte_index];
                // $display("Time: %t | Data In: %h | Start: %b | End: %b | FCS Error: %b", 
                //          $time, data_in, start_of_frame, end_of_frame, fcs_error);
            end
            @(negedge clk);
        end
    endtask

task automatic transmit_two_packet(input logic [7:0] data_first_lane[0:PACKET_LEN-1], input logic [7:0] data_second_lane[0:PACKET_LEN-1], input int first_lane, input int second_lane );
        begin
            for (byte_index = 0; byte_index < PACKET_LEN; byte_index++) begin
                @(negedge clk);
                if (byte_index == 0) begin
                    rx_ctrl[first_lane] = 1;
						  rx_ctrl[second_lane] = 1;
                end else if (byte_index < (PACKET_LEN - 4)) begin
                    rx_ctrl[first_lane] = 1;
						  rx_ctrl[second_lane] = 1;
                end else if (byte_index == (PACKET_LEN - 4)) begin
                    rx_ctrl[first_lane] = 0;
						  rx_ctrl[second_lane] = 0;
                end else begin
                    rx_ctrl[first_lane] = 0;
						  rx_ctrl[second_lane] = 0;
                end
                rx_data[8*first_lane +: 8] = data_first_lane[byte_index];
					 rx_data[8*second_lane +: 8] = data_second_lane[byte_index];
                // $display("Time: %t | Data In: %h | Start: %b | End: %b | FCS Error: %b", 
                //          $time, data_in, start_of_frame, end_of_frame, fcs_error);
            end
            @(negedge clk);
        end
    endtask

task automatic transmit_two_packet_async(
    input  logic [7:0] data_first_lane [0:PACKET_LEN-1],
    input  logic [7:0] data_second_lane[0:PACKET_LEN-1],
    input  int          first_lane,
    input  int          second_lane
);
    localparam int OFFSET = 2;
    int total_cycles = PACKET_LEN + OFFSET;
    int idx2;
    begin
        for (byte_index = 0; byte_index < total_cycles; byte_index++) begin
            @(negedge clk);

            //—— first lane control & data
            if (byte_index == 0) 
                rx_ctrl[first_lane] = 1;
            else if (byte_index < (PACKET_LEN - 4)) 
                rx_ctrl[first_lane] = 1;
            else 
                rx_ctrl[first_lane] = 0;

            if (byte_index < PACKET_LEN)
                rx_data[8*first_lane +:8] = data_first_lane[byte_index];
            else
                rx_data[8*first_lane +:8] = '0;

            //—— second lane control & data (offset by OFFSET)
            idx2 = byte_index - OFFSET;

            if (idx2 == 0) 
                rx_ctrl[second_lane] = 1;
            else if (idx2 > 0 && idx2 < (PACKET_LEN - 4)) 
                rx_ctrl[second_lane] = 1;
            else 
                rx_ctrl[second_lane] = 0;

            if (idx2 >= 0 && idx2 < PACKET_LEN)
                rx_data[8*second_lane +:8] = data_second_lane[idx2];
            else
                rx_data[8*second_lane +:8] = '0;
        end

        // one extra cycle to flush
        @(negedge clk);
    end
endtask




    // Test Sequence
    initial begin
        // Initialize Signals
        clk = 0;
        reset = 1;
        rx_data = 0;
        rx_ctrl = 0;
        link_sync = 0;
        // Reset pulse
        #20 reset = 0;
        #20
		  transmit_two_packet_async(packet_data_array0, packet_data_array4, 0, 1);
        //transmit_packet(packet_data_array0, 0);
		  #200
		  //transmit_two_packet(packet_data_array0, packet_data_array1, 0, 1);
		  transmit_longer_packet(packet_data_array2, 3);
		  
        // End Simulation
        #1000;
        $finish;
    end
endmodule




  // Optional: monitor outputs
  /*
  initial
  begin
    $display("Time   clk reset link_sync rx_ctrl rx_data      -> tx_ctrl tx_data");
    $monitor("%0t   %b   %b    %b       %b       0x%08h -> %b      0x%08h",
             $time, clk, reset, link_sync, rx_ctrl, rx_data, tx_ctrl, tx_data);
  end
*/

