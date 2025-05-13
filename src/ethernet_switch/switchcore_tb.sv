`timescale 1ns/1ps

module switchcore_tb;
  // Parameters
  parameter int P_ADDR_WIDTH = 7;

  // Clock and reset
  logic clk;
  logic reset;

  // Link sync signals
  logic [3:0] link_sync;

  // RX interface
  logic [31:0] rx_data;
  logic [3:0]  rx_ctrl;

  // TX interface (outputs)
  wire [31:0] tx_data;
  wire [3:0]  tx_ctrl;

  // Instantiate DUT
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

  // Clock generation: 10 ns period
  initial
    clk = 0;
  always #5 clk = ~clk;

  // Test stimulus
  initial
  begin
    // Initialize
    reset      = 1;
    link_sync  = 4'b1111;  // all links up
    rx_data    = 32'h0000_0000;
    rx_ctrl    = 4'b0000;

    // Release reset
    #20;
    reset = 0;

    // Send a simple frame on lane 0
    // Drive rx_ctrl to signal start-of-frame on bit 0
    rx_ctrl = 4'b0001;
    rx_data = 32'hAA_BB_CC_DD;
    #10;
    rx_ctrl = 4'b0001;
    rx_data = 32'h11_22_33_44;
    #10;
    // End of frame
    rx_ctrl = 4'b0000;
    rx_data = 32'h00_00_00_00;

    // Wait and finish
    #1000;
    $finish;
  end

  // Optional: monitor outputs
  initial
  begin
    $display("Time   clk reset link_sync rx_ctrl rx_data      -> tx_ctrl tx_data");
    $monitor("%0t   %b   %b    %b       %b       0x%08h -> %b      0x%08h",
             $time, clk, reset, link_sync, rx_ctrl, rx_data, tx_ctrl, tx_data);
  end

endmodule
