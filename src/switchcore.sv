// This module has the same name and port map as the (dummy) switchcore in the De4_SWitch project

module switchcore (
  input  logic                         clk,
  input  logic                         reset,
  input  logic [3:0]                   link_sync, // High indicates a peer connection at the physical layer
  output logic [31:0]                  tx_data,   // [7:0]=TXD0 ... [31:24]=TXD3
  output logic [3:0]                   tx_ctrl,   // 0=TXC0 ... 3=TXC3
  input  logic [31:0]                  rx_data,   // [7:0]=RXD0 ... [31:24]=RXD3
  input  logic [3:0]                   rx_ctrl    // 0=RXC0 ... 3=RXC3
);

  // This is just the Default connections from de4_switch project
  always_ff @(posedge clk or negedge reset) begin
    if(!reset) begin
      tx_data <= 0;
      tx_ctrl <= 0;
    end else begin
      tx_data[15:8] <= rx_data[7:0];
      tx_data[7:0] <= rx_data[15:8];
      tx_ctrl[1] <= rx_ctrl[0];
      tx_ctrl[0] <= rx_ctrl[1];
    end
  end

///////////////////////////////////////////////////////////////////////////////
// SIGNALS
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// MODULE INSTANTIATIONS
///////////////////////////////////////////////////////////////////////////////

// 4 x FCS check modules

// 4 x buffers (sync fifo)

// Mac learning

// Crossbar

///////////////////////////////////////////////////////////////////////////////
// COMBINATIONAL
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

endmodule