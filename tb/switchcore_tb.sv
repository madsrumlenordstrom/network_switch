// ############################################################################
//  Module: switchcore_top_tb
//  Description: Testbench for the switchcore_top
// ############################################################################

`timescale 1ns/1ps

module switchcore_tb;
  parameter int  P_ADDR_WIDTH = 7;
  parameter      CLK_PERIOD = 8ns;
  localparam int PACKET_LEN = 64;
  localparam int PACKET0_LEN = 114;

    // 64-byte test packet (including FCS E6 C5 3D B2)
	logic [7:0] packet_data_array0 [0:63] = '{
		8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12,
		8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h00,
		8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
		8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
		8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
		8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
		8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
		8'h0E, 8'h0F, 8'h10, 8'h11, 8'hE6, 8'hC5, 8'h3D, 8'hB2
	}; 

	 // 64-byte test packet (including FCS 1F F3 C6 0D) 
	 // Has the same dst address as the src address of packet_data_array0
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

	 // 64-byte test packet (including FCS D6 FE 75 54) 
	 // Has the same dst address as the src address of packet_data_array0
	logic [7:0] packet_data_array3 [0:63] = '{
		 8'h00, 8'h12, 8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00,
		 8'h45, 8'h00, 8'h00, 8'h2E, 8'h08, 8'h00, 8'h45, 8'h00,
		 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'hFF,
		 8'hFF, 8'h40, 8'hFF, 8'hA8, 8'hFF, 8'h2C, 8'hC0, 8'hFF,
		 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
		 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
		 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
		 8'h0E, 8'h0F, 8'h10, 8'h11, 8'hD6, 8'hFE, 8'h75, 8'h54
	};

	 // 64-byte test packet (including FCS D6 0A D5 4A)
	 // Broadcasts
	logic [7:0] packet_data_array4 [0:63] = '{
		 8'h00, 8'h12, 8'h34, 8'hEE, 8'hEE, 8'h08, 8'h00, 8'h45, 
		 8'h00, 8'h00, 8'h2E, 8'hEE, 8'hEE, 8'h45, 8'h00, 8'h00,
		 8'h2E, 8'hB3, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
		 8'hFF, 8'hFF, 8'hFF, 8'hA8, 8'hFF, 8'h2C, 8'hC0, 8'hFF,
		 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
		 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
		 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
		 8'h0E, 8'h0F, 8'h10, 8'h11, 8'hD6, 8'h0A, 8'hD5, 8'h4A
	};

	// 114-byte test packet (including FCS B4 38 56 E5) 
	// Has the same dst address as the src address of packet_data_array1
	logic [7:0] packet_data_array2 [0:113] = '{
		 8'h08, 8'h00, 8'h45, 8'h00, 8'h00, 8'h2E, 8'h08, 8'h22,
		 8'h22, 8'h00, 8'h00, 8'h2E, 8'h08, 8'h00, 8'h45, 8'h00,
		 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
		 8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
		 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
		 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
		 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
		 8'h01, 8'h22, 8'h19, 8'h02, 8'h32, 8'h08, 8'h00, 8'h45,
		 8'h00, 8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80,
		 8'h11, 8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0,
		 8'hA8, 8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00,
		 8'h1A, 8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04,
		 8'h05, 8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C,
		 8'h0D, 8'h01, 8'h22, 8'h19, 8'h02, 8'h32, 8'hB4, 8'h38,
		 8'h56, 8'hE5     
	};

	// Data but with a random bit flipped
	logic [7:0] packet_data_array0_incorrect [0:PACKET_LEN-1] = '{
		8'h00, 8'h10, 8'hA4, 8'h7B, 8'hEA, 8'h80, 8'h00, 8'h12,
		8'h34, 8'h56, 8'h78, 8'h90, 8'h08, 8'h00, 8'h45, 8'h10,
		8'h00, 8'h2E, 8'hB3, 8'hFE, 8'h00, 8'h00, 8'h80, 8'h11,
		8'h05, 8'h40, 8'hC0, 8'hA8, 8'h00, 8'h2C, 8'hC0, 8'hA8,
		8'h00, 8'h04, 8'h04, 8'h00, 8'h04, 8'h00, 8'h00, 8'h1A,
		8'h2D, 8'hE8, 8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
		8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D,
		8'h0E, 8'h0F, 8'h10, 8'h11, 8'hE6, 8'hC5, 8'h3D, 8'hB2
	}; 

 
   // Module signals
   logic clk;
   logic reset;
   logic [3:0] link_sync;
   // RX interface
   logic [31:0] rx_data;
   logic [3:0]  rx_ctrl;
   // TX interface
   logic [31:0] tx_data;
   logic [3:0]  tx_ctrl;
	
	// Clock period
   always #(CLK_PERIOD / 2) clk = ~clk;
	
	// Variable 
	int byte_index;
	
	
  // ##########################################################################
  //  Testbench Queues, Signals and Variables
  // ##########################################################################	
  
   logic [7:0] tx_data_ref [4][0:2048];
	int total_errors [4] = '{default: 0};
	int total_matches [4] = '{default: 0};
	int tx_data_idx[4] = '{default: 0};
	int total_error_sum = 0;
	int total_match_sum = 0;


  // ##########################################################################
  //  Module instantiation (DUT: switchcore_top)
  // ##########################################################################
  
	switchcore #(
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
	
	
  // ##########################################################################
  //  CONSTANTS FOR EASIER DEBUGGING
  // ##########################################################################
	  
	int offset_short = 46;
	int offset_long = 96;
	int offset_mac = 14;
  
  // ##########################################################################
  //  Testbench Sequence
  // ##########################################################################
  
  
	// Test Sequence
	initial begin
		// Initialize Signals
		clk   = 0;
		reset = 1;
		rx_data   = 0;
		rx_ctrl   = 0;
		link_sync = 0;

		
		// Dump signals to VCD
		$dumpfile("dump.vcd");
		$dumpvars(0, switchcore_top_tb);

		// Pull Reset
		$display("############## SIM STARTED  ##############");
		#(CLK_PERIOD*2) reset = 1;
		#(CLK_PERIOD*2) reset = 0;
		$display("############# RESET RELEASED #############");
		
		transmit_longer_packet(packet_data_array2, 0);
		#2000
		
		
		for (int j = 1; j < 4; j++) begin
			for (int i = 0; i < offset_long; i++) begin
				if (tx_data_ref[j][i] !== packet_data_array2[i+offset_mac]) begin
					total_errors[j]++;
					$display("Mismatch at byte %0d of port %0d", i, j);
					$display("The actual value = %0h, the expected value %0h",tx_data_ref[j][i], packet_data_array2[i+offset_mac]);
				end else
					total_matches[j]++;
			end
			  total_error_sum += total_errors[j];
			  total_match_sum += total_matches[j];
		end
		
		
		transmit_two_packet_async(packet_data_array0, packet_data_array1, 0, 1); // First broadcast and second one is broadcast
		#2000

		for (int j = 0; j < 4; j++) begin
			for (int i = offset_long; i < (offset_long + offset_short); i++) begin
				if (j == 0) begin
						if (tx_data_ref[j][i-offset_long] !== packet_data_array1[(i-offset_long)+offset_mac]) begin
						total_errors[j]++;
						$display("Mismatch at byte %0d of port %0d", i, j);
						$display("The actual value = %0h, the expected value %0h",tx_data_ref[j][i-offset_long], packet_data_array1[(i-offset_long)+offset_mac]);
					end else
						total_matches[j]++;
				end else begin
					if (tx_data_ref[j][i] !== packet_data_array0[(i-offset_long)+offset_mac]) begin
						total_errors[j]++;
						$display("Mismatch at byte %0d of port %0d", i, j);
						$display("The actual value = %0h, the expected value %0h",tx_data_ref[j][i], packet_data_array0[(i-96)+14]);
					end else
						total_matches[j]++;				
				end
			end
			  total_error_sum += total_errors[j];
			  total_match_sum += total_matches[j];
		end
		
		
		transmit_longer_packet(packet_data_array2, 2);
		#2000
		
		
		for (int j = 1; j < 2; j++) begin
			for (int i = offset_long + offset_short; i < offset_long + offset_long + offset_short; i++) begin
				if (tx_data_ref[j][i] !== packet_data_array2[i-(offset_long + offset_short)+offset_mac]) begin
					total_errors[j]++;
					$display("Mismatch at byte %0d of port %0d", i, j);
					$display("The actual value = %0h, the expected value %0h",tx_data_ref[j][i], packet_data_array2[i-(offset_long + offset_short)+offset_mac]);
				end else
					total_matches[j]++;
			end
			  total_error_sum += total_errors[j];
			  total_match_sum += total_matches[j];
		end
		
		
	   $display("############## SIM FINISHED ##############"); 
		$display("Total amount of byte matches were %0d", total_match_sum);
		$display("Total amount of byte errors were %0d", total_error_sum);
		$display("##########################################");
		
		$finish;
	end

	always_ff @(posedge clk) begin
		for (int i = 0; i < 4; i++) begin
			if (tx_ctrl[i]) begin
			tx_data_ref[i][tx_data_idx[i]] <= tx_data[8*i +: 8];
			tx_data_idx[i]++;
			end
		end
	end
   

	 
	 
	 
  // ##########################################################################
  //  Tasks: Different variant of data packet transmissions
  // ##########################################################################
	task automatic transmit_longer_packet(
		input logic [7:0] data[0:PACKET0_LEN-1], 
		input int         lane 
	);
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
			end
			@(negedge clk);
		end
	endtask

	task automatic transmit_packet(
		input logic [7:0] data[0:PACKET_LEN-1], 
		input int         lane 
	);
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
			end
			@(negedge clk);
		end
	endtask

	task automatic transmit_two_packet(
		input logic [7:0] data_first_lane[0:PACKET_LEN-1], 
		input logic [7:0] data_second_lane[0:PACKET_LEN-1],
		input int first_lane, 
		input int second_lane 
	);
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
			end
			@(negedge clk);
		end
	endtask

	task automatic transmit_two_packet_async(
		input  logic [7:0] data_first_lane [0:PACKET_LEN-1],
		input  logic [7:0] data_second_lane[0:PACKET_LEN-1],
		input  int         first_lane,
		input  int         second_lane
	);
		localparam int OFFSET = 2;
		int total_cycles = PACKET_LEN + OFFSET;
		int idx2;
		begin
			for (byte_index = 0; byte_index < total_cycles; byte_index++) begin
				@(negedge clk);
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
		@(negedge clk);
		end
	endtask
	 
endmodule
