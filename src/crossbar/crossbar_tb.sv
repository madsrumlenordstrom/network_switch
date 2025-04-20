module crossbar_tb;

  // Parameters
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
  always #5 clk_i = ~clk_i;

  // Testbench logic
  initial begin
    // Initialize signals
    clk_i = 0;
    rstn_i = 0;
    rx_data = '{default: 0};
    rx_done = '{default: 0};
    rx_dest = '{default: 5}; // data not valid when dest is over 4

    // Dump signals to VCD
    $dumpfile("dump.vcd");
    $dumpvars(0, crossbar_tb);

    // Reset the design
    #20 rstn_i = 1;

    // Send 5 frames per RX port
    repeat (5) begin
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
    #1000;

    // End simulation
    $finish;
  end

  // Task to send a frame
  task automatic send_frame(input int rx_port, input logic [7:0] start_byte, input logic [2:0] dest);
    for (int i = 0; i < 8; i++) begin
      rx_data[rx_port] = start_byte + (8)'(i);
      rx_done[rx_port] = (i == 7);
      rx_dest[rx_port] = dest;
      #10; // Wait for 1 clock cycle
    end
    // Clear signals after frame
    rx_data[rx_port] = 0; 
    rx_done[rx_port] = 0; 
    rx_dest[rx_port] = (3)'(rx_port); // Set to invalid destination
    #10; // Wait for 1 clock cycle
  endtask

endmodule