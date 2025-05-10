// ############################################################################
//  Module: crossbar_tb
//  Description: Testbench for the Crossbar module. Checks the functionality
//               of the crossbar by sending frames from RX ports to TX ports
//               and comparing the output with reference data. The testbench
//               also checks that the reference queues are empty 
//               post simulation. A waveform is also generated for debugging.
// ############################################################################

module crossbar_tb;
  // TB Parameters
  parameter time P_PERIOD = 8ns; // Clock period in ns
  parameter int  P_DEBUG = 0; // Set to 1 for displaying data matches

  // Module Parameters
  parameter int P_QUEUE_ADDR_WIDTH = 13; // Make sure queues are large enough (8192 bytes for now)

  // Module Signals
  logic clk_i;
  logic rstn_i;

  // RX Data and control
  logic [3:0][7:0] rx_data; // 4 RX ports, 8b data
  logic [3:0]      rx_done; // 4 RX ports, 1b done signal (high accompanying last byte of data)
  logic [3:0][2:0] rx_dest; // 4 RX ports, 3b destination port (0-3 for respective TX) (4 is broadcast to all TX ports) (5-7 are invalid)

  // TX Data and control
  logic [3:0][7:0] tx_data; // 4 TX ports, 8-bit data
  logic [3:0]      tx_ctrl; // 4 TX ports, 1b control signal (high when data is valid)

  // Clock Control
  always #(P_PERIOD/2) clk_i = ~clk_i;

  // ##########################################################################
  //  Testbench Queues, Signals and Variables
  // ##########################################################################
  // Reference tx data queues (seperate for each VC, should be 3, but is 4 for code simplicity the 4th should never be filled)
  logic [7:0] tx_data_ref [4][4][$]; 
  int total_errors [4] = '{default: 0};
  int total_matches [4] = '{default: 0};

  // Used to generate random TX port for RX ports 1-3
  logic [2:0] valid_tx_for_rx1 [4] = '{0, 2, 3, 4}; 
  logic [2:0] valid_tx_for_rx2 [4] = '{0, 1, 3, 4};
  logic [2:0] valid_tx_for_rx3 [4] = '{0, 1, 2, 4};
  int random_index1;
  int random_index2;
  int random_index3;

  // Used to inspect the grants for each TX port (needed to check reference queues)
  int grant_inspect [4];

  // ##########################################################################
  //  DELCARATION AND ASSIGNMENT OF SIGNALS FOR EASIER DEBUGGING
  // ##########################################################################
  logic [7:0] tx_data0;
  logic       tx_ctrl0;
  logic [7:0] tx_data1;
  logic       tx_ctrl1;
  logic [7:0] tx_data2;
  logic       tx_ctrl2;
  logic [7:0] tx_data3;
  logic       tx_ctrl3;
  assign tx_data0 = tx_data[0];
  assign tx_ctrl0 = tx_ctrl[0];
  assign tx_data1 = tx_data[1];
  assign tx_ctrl1 = tx_ctrl[1];
  assign tx_data2 = tx_data[2];
  assign tx_ctrl2 = tx_ctrl[2];
  assign tx_data3 = tx_data[3];
  assign tx_ctrl3 = tx_ctrl[3];
  
  logic vc_eof_delay_1_0;
  logic vc_eof_delay_2_0;
  logic vc_eof_delay_3_0;
  logic vc_eof_delay_0_1;
  logic vc_eof_delay_2_1;
  logic vc_eof_delay_3_1;
  logic vc_eof_delay_0_2;
  logic vc_eof_delay_1_2;
  logic vc_eof_delay_3_2;
  logic vc_eof_delay_0_3;
  logic vc_eof_delay_1_3;
  logic vc_eof_delay_2_3;
  assign vc_eof_delay_1_0 = u_crossbar.vc_eof_delay[0][0];
  assign vc_eof_delay_2_0 = u_crossbar.vc_eof_delay[1][0];
  assign vc_eof_delay_3_0 = u_crossbar.vc_eof_delay[2][0];
  assign vc_eof_delay_0_1 = u_crossbar.vc_eof_delay[0][1];
  assign vc_eof_delay_2_1 = u_crossbar.vc_eof_delay[1][1];
  assign vc_eof_delay_3_1 = u_crossbar.vc_eof_delay[2][1];
  assign vc_eof_delay_0_2 = u_crossbar.vc_eof_delay[0][2];
  assign vc_eof_delay_1_2 = u_crossbar.vc_eof_delay[1][2];
  assign vc_eof_delay_3_2 = u_crossbar.vc_eof_delay[2][2];
  assign vc_eof_delay_0_3 = u_crossbar.vc_eof_delay[0][3];
  assign vc_eof_delay_1_3 = u_crossbar.vc_eof_delay[1][3];
  assign vc_eof_delay_2_3 = u_crossbar.vc_eof_delay[2][3];

  logic [3:0] tx_delay_countdown0;
  logic [3:0] tx_delay_countdown1;
  logic [3:0] tx_delay_countdown2;
  logic [3:0] tx_delay_countdown3; 
  assign tx_delay_countdown0 = u_crossbar.tx_delay_countdown[0];
  assign tx_delay_countdown1 = u_crossbar.tx_delay_countdown[1];
  assign tx_delay_countdown2 = u_crossbar.tx_delay_countdown[2];
  assign tx_delay_countdown3 = u_crossbar.tx_delay_countdown[3];

  logic [2:0] requests_tx0;
  logic [2:0] requests_tx1;
  logic [2:0] requests_tx2;
  logic [2:0] requests_tx3;
  assign requests_tx0 = u_crossbar.requests_tx[0];
  assign requests_tx1 = u_crossbar.requests_tx[1];
  assign requests_tx2 = u_crossbar.requests_tx[2];
  assign requests_tx3 = u_crossbar.requests_tx[3];

  logic [2:0] grants_tx0;
  logic [2:0] grants_tx1;
  logic [2:0] grants_tx2;
  logic [2:0] grants_tx3;
  assign grants_tx0 = u_crossbar.grants_tx[0];
  assign grants_tx1 = u_crossbar.grants_tx[1];
  assign grants_tx2 = u_crossbar.grants_tx[2];
  assign grants_tx3 = u_crossbar.grants_tx[3];
  // ##########################################################################
  

  // ##########################################################################
  //  Module instantiation (DUT: crossbar)
  // ##########################################################################
  crossbar #(
    .P_QUEUE_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH)
  ) u_crossbar (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .rx_dest(rx_dest),
    .tx_data(tx_data),
    .tx_ctrl(tx_ctrl)
  );


  // ##########################################################################
  //  Testbench Sequence
  // ##########################################################################
  initial begin
    // Initialize signals
    clk_i = 0;
    rstn_i = 0;
    rx_data = 0;
    rx_done = 0;
    rx_dest = '{default: 5}; // data not valid when tx_port is over 4

    // Dump signals to VCD
    $dumpfile("dump.vcd");
    $dumpvars(0, crossbar_tb);

    // Pull Reset
    $display("############## SIM STARTED  ##############");
    #(P_PERIOD*2) rstn_i = 1;
    $display("############# RESET RELEASED #############");


    // Start sending frames
    $display("## SEND ALL PORTS NO CONTENTION         ##");
    repeat (3) begin // Send frames 3 times per RX port to predictable TX ports non-overlapping
      fork
        send_frame(0, 3'h1); // RX0 to TX1
        send_frame(1, 3'h2); // RX1 to TX2
        send_frame(2, 3'h3); // RX2 to TX3
        send_frame(3, 3'h0); // RX3 to TX0
      join;
    end
    #(P_PERIOD*20);


    $display("\n## TEST BROADCAST FROM RX0              ##");
    send_frame(0, 3'h4); // Broadcast from RX0 to all TX ports
    #(P_PERIOD*100);


    $display("\n## TEST ALL RX GOING TO SINGLE TX       ##");
    // Send frames from all RX ports (excluding RX0) to TX0
    repeat (5) begin
      fork
        send_frame(1, 3'h0, $urandom_range(1518,64)); // RX1 to TX0
        send_frame(2, 3'h0, $urandom_range(1518,64)); // RX2 to TX0
        send_frame(3, 3'h0, $urandom_range(1518,64)); // RX3 to TX0
      join;
    end
    #(5000*P_PERIOD); // (Long wait since all RX ports are going to TX0)


    $display("\n## SEND ALL PORTS RANDOM DEST AND SIZE  ##"); 
    repeat (20) begin // Send frames of random sizes to random TX ports 15 times
      fork
        begin
          send_frame(0, (3)'($urandom_range(4,1)), $urandom_range(1518,64)); // RX0 to random TX
        end
        begin
          random_index1 = $urandom_range(3,0); // generate random TX port can be 0,2,3,4 but not 1
          send_frame(1, valid_tx_for_rx1[random_index1], $urandom_range(1518,64)); // RX1 to random TX
        end
        begin
          random_index2 = $urandom_range(3,0);
          send_frame(2, valid_tx_for_rx2[random_index2], $urandom_range(1518,64)); // RX2 to random TX
        end
        begin
          random_index3 = $urandom_range(3,0);
          send_frame(3, valid_tx_for_rx3[random_index3], $urandom_range(1518,64)); // RX3 to random TX
        end
      join;
    end
    #(P_PERIOD*15000);


    $display("############## SIM FINISHED ##############");
    // Currenttly reference queues won't work when there is contention for the same TX port, so print errors now (and waveform can be used to debug the following) 
    // Check for errors in TX data
    $display("##  RESULTS                             ##");
    $display("Total Matches: TX0: %0d, TX1: %0d, TX2: %0d, TX3: %0d", total_matches[0], total_matches[1], total_matches[2], total_matches[3]);
    if (total_errors[0] == 0 && total_errors[1] == 0 && total_errors[2] == 0 && total_errors[3] == 0) begin
      $display("ALL TX data matched with reference data.");
    end else begin
      $display("Total ERRORS: TX0: %0d, TX1: %0d, TX2: %0d, TX3: %0d", total_errors[0], total_errors[1], total_errors[2], total_errors[3]);
    end
    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        if (tx_data_ref[i][j].size() > 0) begin
          $display("ERROR Reference queue[%0d][%0d] has %0d elements remaining", i, j, tx_data_ref[i][j].size());
        end
      end
    end
    $display("##########################################");

    $finish;
  end

  // Monitor the TX data and control signals
  // Check which RX ports are granted to TX ports for reference queues
  assign grant_inspect[0] = $clog2({u_crossbar.grants_tx[0],1'b0}); // ports for tx0 can be rx 1,2,3
  assign grant_inspect[1] = $clog2({u_crossbar.grants_tx[1][2:1],1'b0,u_crossbar.grants_tx[1][0]}); // ports for tx0 can be rx 0,2,3
  assign grant_inspect[2] = $clog2({u_crossbar.grants_tx[2][2],1'b0,u_crossbar.grants_tx[2][1:0]}); // ports for tx0 can be rx 0,1,3
  assign grant_inspect[3] = $clog2(u_crossbar.grants_tx[3]);    // ports for tx0 can be rx 0,1,2

  always_ff @(posedge clk_i) begin
    for(int i = 0; i < 4; i++) begin // For each TX port
      if (tx_ctrl[i]) begin // If TX ctrl high
        if (tx_data_ref[grant_inspect[i]][i].size() > 0) begin // Check if there is data in the reference queue
          // Compare with the reference data (queue depending on the grant)
          if (tx_data[i] == tx_data_ref[grant_inspect[i]][i][$]) begin
            if (P_DEBUG == 1) $display("TX%0d: Data: %h Matches REF: %h", i, tx_data[i], tx_data_ref[grant_inspect[i]][i][$]);
            total_matches[i] += 1;

          end else begin // If there is a mismatch
              $display("%d Mismatch on TX%0d: Expected %h, got %h",$time , i, tx_data_ref[grant_inspect[i]][i][$], tx_data[i]);
              total_errors[i] += 1;

          end
          tx_data_ref[grant_inspect[i]][i].pop_back(); // Remove the last element from the reference queue

        end else begin // If there is no data in the reference queue
          $display("Data on TX%0d: %h MISSING on Reference", i, tx_data[i]);
          total_errors[i] += 1;
        end
      end
    end
  end


  // ##########################################################################
  //  Task: send_frame
  //  Description: This task sends a frame from a RX port to a TX port.
  // ##########################################################################
  task automatic send_frame(input int rx_port, input logic [2:0] tx_port, input int frame_size = 64);
    logic [3:0] data [4] = '{4'hA, 4'hB, 4'hC, 4'hD}; // Have distinct data for each RX port

    if (tx_port < 5 && (32)'(tx_port) != rx_port) begin
      $display("Sending frame from RX%0d to TX%0d with size %0d", rx_port, tx_port, frame_size);
      for (int i = 0; i < frame_size; i++) begin
        rx_data[rx_port] = {data[rx_port], (4)'(i)};
        rx_done[rx_port] = (i == (frame_size - 1));
        rx_dest[rx_port] = tx_port;
        
        if (tx_port < 4) begin
          tx_data_ref[rx_port][tx_port[1:0]].push_front(rx_data[rx_port]); // Store the reference data
        end else begin
          for (int i = 0; i < 4; i++) begin // Broadcast to all TX ports
              if (i != rx_port) begin
                tx_data_ref[rx_port][i].push_front(rx_data[rx_port]); // Store the reference data
              end
            end
        end
        #(P_PERIOD);
      end
      // Clear signals after frame
      rx_data[rx_port] = 0; 
      rx_done[rx_port] = 0; 
      rx_dest[rx_port] = (3)'(rx_port); // Set to invalid destination
      #(P_PERIOD);
    end else begin
      $display("Invalid TX port %0d for RX port %0d", tx_port, rx_port);
    end
  endtask
  // ##########################################################################

endmodule