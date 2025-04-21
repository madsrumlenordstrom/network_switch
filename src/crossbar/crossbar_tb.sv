module crossbar_tb;
  // TB Parameters
  parameter real P_PERIOD = 10; // Clock period in ns

  // Module Parameters
  parameter int P_QUEUE_ADDR_WIDTH = 7;

  // Signals
  logic clk_i;
  logic rstn_i;

  // RX Data and control
  logic [7:0] rx_data [4];
  logic       rx_done [4];
  logic [2:0] rx_dest [4];

  // TX Data and control
  logic [7:0] tx_data [4];
  logic       tx_ctrl [4];

  // Reference tx data queues (including control)
  logic [7:0] tx_data_ref [4][$];
  int total_errors [4] = '{default: 0};
  int total_matches [4] = '{default: 0};

  logic [2:0] valid_tx_for_rx1 [4] = '{0, 2, 3, 4};
  logic [2:0] valid_tx_for_rx2 [4] = '{0, 1, 3, 4};
  logic [2:0] valid_tx_for_rx3 [4] = '{0, 1, 2, 4};
  int random_index1;
  int random_index2;
  int random_index3;

  // Instantiate the crossbar module
  crossbar #(
    .P_QUEUE_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH)
  ) u_crossbar (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .rx_data0(rx_data[0]),
    .rx_done0(rx_done[0]),
    .rx_dest0(rx_dest[0]),
    .rx_data1(rx_data[1]),
    .rx_done1(rx_done[1]),
    .rx_dest1(rx_dest[1]),
    .rx_data2(rx_data[2]),
    .rx_done2(rx_done[2]),
    .rx_dest2(rx_dest[2]),
    .rx_data3(rx_data[3]),
    .rx_done3(rx_done[3]),
    .rx_dest3(rx_dest[3]),
    .tx_data0(tx_data[0]),
    .tx_ctrl0(tx_ctrl[0]),
    .tx_data1(tx_data[1]),
    .tx_ctrl1(tx_ctrl[1]),
    .tx_data2(tx_data[2]),
    .tx_ctrl2(tx_ctrl[2]),
    .tx_data3(tx_data[3]),
    .tx_ctrl3(tx_ctrl[3])
  );

  // Clock Control
  always #(P_PERIOD/2) clk_i = ~clk_i;

  // Testbench logic
  initial begin
    // Initialize signals
    clk_i = 0;
    rstn_i = 0;
    rx_data = '{default: 0};
    rx_done = '{default: 0};
    rx_dest = '{default: 5}; // data not valid when tx_port is over 4

    // Dump signals to VCD
    $dumpfile("dump.vcd");
    $dumpvars(0, crossbar_tb);

    // Reset the design
    $display("############## SIM STARTED  ##############");
    #(P_PERIOD*2) rstn_i = 1;
    $display("############# RESET RELEASED #############");

    // Send frames 3 times per RX port to predictable TX ports non-overlapping
    repeat (3) begin
      fork
        begin
          send_frame(0, 8'hAA, 3'h1); // RX0 to TX1
        end
        begin
          send_frame(1, 8'hCC, 3'h2); // RX1 to TX2
        end
        begin
          send_frame(2, 8'hEE, 3'h3); // RX2 to TX3
        end
        begin
          send_frame(3, 8'h11, 3'h0); // RX3 to TX0
        end
      join;
    end
    // Wait for all frames to be processed
    #(P_PERIOD*5);

    // Send frames of random sizes to random TX ports
    repeat (1) begin
      fork
        begin
          send_frame(0, 8'hAA, (3)'($urandom_range(4,1)), $urandom_range(64,8)); // RX0 to random TX
        end
        begin
          // generate random TX port can be 0,2,3,4 but not 1
          random_index1 = $urandom_range(3,0);
          send_frame(1, 8'hCC, valid_tx_for_rx1[random_index1], $urandom_range(64,8)); // RX1 to random TX
        end
        begin
          random_index2 = $urandom_range(3,0);
          send_frame(2, 8'hEE, valid_tx_for_rx2[random_index2], $urandom_range(64,8)); // RX2 to random TX
        end
        begin
          random_index3 = $urandom_range(3,0);
          send_frame(3, 8'h11, valid_tx_for_rx3[random_index3], $urandom_range(64,8)); // RX3 to random TX
        end
      join;
    end
    #(P_PERIOD*10); // Wait for all frames to be processed

    // Currenttly reference queues won't work when there is contention for the same TX port, so print errors now (and waveform can be used to debug the following) 
    // Check for errors in TX data
    display("############# CHECKING ERRORS #############");
    $display("Total Matches: TX0: %0d, TX1: %0d, TX2: %0d, TX3: %0d", total_matches[0], total_matches[1], total_matches[2], total_matches[3]);
    if (total_errors[0] == 0 && total_errors[1] == 0 && total_errors[2] == 0 && total_errors[3] == 0) begin
      $display("All TX data matched with reference data.");
    end else begin
      $display("Total Errors: TX0: %0d, TX1: %0d, TX2: %0d, TX3: %0d", total_errors[0], total_errors[1], total_errors[2], total_errors[3]);
    end
    $display("##########################################");

    // Send broadcast frames to all TX ports from RX0
    send_frame(0, 8'hAA, 3'h4); // RX0 to all TX ports
    #(5*P_PERIOD); // Wait for all frames to be processed


    // Send frames from all RX ports (excluding RX0) to TX0
    repeat (2) begin
      fork
        begin
          send_frame(1, 8'hCC, 3'h0); // RX1 to TX0
        end
        begin
          send_frame(2, 8'hEE, 3'h0); // RX2 to TX0
        end
        begin
          send_frame(3, 8'h11, 3'h0); // RX3 to TX0
        end
      join;
    end

    $display("############## SIM FINISHED ##############");
    $finish;
  end

  // Monitor the TX data and control signals
  always_ff @(posedge clk_i) begin
    for(int i = 0; i < 4; i++) begin
      if (tx_ctrl[i]) begin
        $display("TX%0d: Data: %h Matches REF: %h", i, tx_data[i], tx_data_ref[i][$]);
        total_matches[i] += 1;
        if (tx_data_ref[i].size() > 0) begin
          if (tx_data[i] != tx_data_ref[i].pop_back()) begin
            $display("Mismatch on TX%0d: Expected %h, got %h", i, tx_data_ref[i][$], tx_data[i]);
            total_errors[i] += 1;
          end
        end else begin
          $display("Unexpected data on TX%0d: %h", i, tx_data[i]);
          total_errors[i] += 1;
        end
      end
    end
  end

  // Task to send a frame
  task automatic send_frame(input int rx_port, input logic [7:0] start_byte, input logic [2:0] tx_port, input int frame_size = 8);
    if (tx_port < 5 && (32)'(tx_port) != rx_port) begin
      $display("Sending frame from RX%0d to TX%0d with size %0d", rx_port, tx_port, frame_size);
      for (int i = 0; i < frame_size; i++) begin
        rx_data[rx_port] = start_byte + (8)'(i);
        rx_done[rx_port] = (i == (frame_size - 1));
        rx_dest[rx_port] = tx_port;
        
        if (tx_port < 4) begin
          tx_data_ref[tx_port[1:0]].push_front(rx_data[rx_port]); // Store the reference data
        end else begin
          for (int i = 0; i < 4; i++) begin // Broadcast to all TX ports
              if (i != rx_port) begin
                tx_data_ref[i].push_front(rx_data[rx_port]); // Store the reference data
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

endmodule