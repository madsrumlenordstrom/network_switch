// ############################################################################
//  Module: crossbar
//  Description: This module implements a crossbar switch with 4 inputs 
//               and 4 outputs. Virtual channels are used to separate the
//               data streams to avoid blocking.
//               Each output has a round-robin arbiter with grant holding 
//               to select between the VCs.            
//  Parameters: P_QUEUE_ADDR_WIDTH - Address width, in turn size for the queues
// ############################################################################

module crossbar #(
  parameter int P_QUEUE_ADDR_WIDTH = 12 // Address width for the queues (Default (currently): 12 , 2^12 = 4096)
) (
  input  logic clk_i,
  input  logic rstn_i,

  // RX Data and control
  input  logic [3:0][7:0] rx_data,
  input  logic [3:0]      rx_done, // rx_done accompanies the last byte of data
  input  logic [3:0][2:0] rx_dest, // 0: tx0, 1: tx1, 2: tx2, 3: tx3, 4: broadcast, 5-7: not valid (data also not valid if dest == port)

  // TX Data and control
  output logic [3:0][7:0] tx_data,
  output logic [3:0]      tx_ctrl // tx_ctrl accompanies valid bytes of data
);

  // ##########################################################################
  //  Signals 
  // ##########################################################################
  // Requests and grants for arbiters (one set for each tx port)
  logic [3:0][2:0] requests_tx;
  logic [3:0][2:0] grants_tx;

  // Virtual channels (data comprises rx_data and bit for eof, therefore 9 bits)
  // There are 12 virtual channels (3 rx ports queuing for a given tx port)
  // Note that rx index does necessarily correspond to rx port
  // IDX: RX   TX
  logic [2:0][3:0]      vc_empty;
  logic [2:0][3:0]      vc_read; // Queues are FWFT, so first element is present when empty is low
  logic [2:0][3:0]      vc_write;
  logic [2:0][3:0]      vc_eof_delay;
  logic [2:0][3:0][8:0] vc_data; 
  logic [2:0][3:0][8:0] vc_temp; // Temporary data output from the queues

  logic [3:0][3:0] tx_delay_countdown; // 4 bits to hold the countdown for each tx port (12 cycles)

  // ############################################################################
  //  Module Instatiations
  // ############################################################################
  generate // Use the old generate statement, since Quartus does not support the newer "for (genvar " syntax ...
    genvar tx;
    genvar rx_idx;
    for (tx = 0; tx < 4; tx++) begin: g_tx_dimension
      for (rx_idx = 0; rx_idx < 3; rx_idx++) begin: g_rx_dimension
        // Avoid queues where ports rx = tx (if rx variable is greater than tx variable, add 1 to it)
        int rx_p = (rx_idx>=tx) ? (rx_idx+1) : rx_idx; // rx_p is the true port number, rx_idx is rx index

        // Instantiate the virtual channel queues (FIFO) 12 total (each tx port has 3 queues, for all other than the rx=tx port)
        sync_fifo_core #(
          .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
          .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
          .P_FWFT(1)
        ) u_sync_fifo_core (
          .clk_i(clk_i),
          .rstn_i(rstn_i),
          .wr_i(vc_write[rx_idx][tx]),
          .data_i({rx_done[rx_p],rx_data[rx_p]}),
          .rd_i(vc_read[rx_idx][tx]),
          .data_o(vc_temp[rx_idx][tx]),
          .fill_level_o(),
          .empty_o(vc_empty[rx_idx][tx]),
          .full_o()
        );
      end: g_rx_dimension

      // Instantiate the arbiters for each tx port
      arbiter #(.P_WIDTH(3)) arbiter_tx (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .request_i(requests_tx[tx]),
        .grant_o(grants_tx[tx])
      );
    end: g_tx_dimension
  endgenerate

  // ##########################################################################
  //  Combinational Logic
  // ##########################################################################
  always_comb begin
    for (int tx = 0; tx < 4; tx++) begin: tx_comb
      for (int rx_idx = 0; rx_idx < 3; rx_idx++) begin: rx_comb
        int rx_p = (rx_idx>=tx) ? (rx_idx+1) : rx_idx; // As above, avoid queues where ports rx = tx
      
        // Place data into queues
        vc_write[rx_idx][tx] = ((rx_dest[rx_p] == (3)'(tx)) || (rx_dest[rx_p] == 3'h4));

        vc_data[rx_idx][tx] = (vc_empty[rx_idx][tx] == 0) ? vc_temp[rx_idx][tx] : 9'h0; // If the queue is not empty, read the data from the queue

      end: rx_comb

      // Make requests for each TX port arbiter
      if (tx_delay_countdown[tx] == 0) begin
      requests_tx[tx] = {~vc_empty[2][tx] & ~vc_eof_delay[2][tx], ~vc_empty[1][tx] & ~vc_eof_delay[1][tx], ~vc_empty[0][tx] & ~vc_eof_delay[0][tx]};
      end else begin
        requests_tx[tx] = 3'b000; // No requests if delay countdown is not zero
      end

      // Read from Virtual channels on grant
      {vc_read[2][tx], vc_read[1][tx], vc_read[0][tx]} = grants_tx[tx];

      // Multiplex data and control signals
      unique case (grants_tx[tx])
        3'b001: begin // Grant from rx port 1/0 (1 if tx port 0, 0 if tx port 1,2,3)
          tx_data[tx] = vc_data[0][tx][7:0];
          tx_ctrl[tx] = 1'b1;
        end
        3'b010: begin // Grant from rx port 2/1 (2 if tx port 0,1, 1 if tx port 2,3)
          tx_data[tx] = vc_data[1][tx][7:0];
          tx_ctrl[tx] = 1'b1;
        end
        3'b100: begin // Grant from rx port 3/2 (3 if tx port 0,1,2, 2 if tx port 3)
          tx_data[tx] = vc_data[2][tx][7:0];
          tx_ctrl[tx] = 1'b1;
        end
        default: begin // No grant
          tx_data[tx] = 8'b0;
          tx_ctrl[tx] = 1'b0;
        end
      endcase

    end: tx_comb
  end

  // ############################################################################
  //  Sequential Logic (delay for eof)
  // ############################################################################
  always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
      vc_eof_delay <= 0; // Reset all eof delay signals
      tx_delay_countdown <= 0; // Reset all delay countdowns
    end else begin // explanaition of rx ports see reset case
      for (int tx = 0; tx < 4; tx++) begin: tx_sequential
        
        if (tx_delay_countdown[tx] > 0) begin // Decrement the delay countdown if not zero
          tx_delay_countdown[tx] <= tx_delay_countdown[tx] - 4'h1;
        end else if (vc_data[0][tx][8] | vc_data[1][tx][8] | vc_data[2][tx][8]) begin // If any eof, set the delay countdown
          tx_delay_countdown[tx] <= 12; // Set the delay countdown to 12 cycles on eof
        end

        for (int rx_idx = 0; rx_idx < 3; rx_idx++) begin: rx_sequential
          vc_eof_delay[rx_idx][tx] <= vc_data[rx_idx][tx][8];  
        end: rx_sequential
      end: tx_sequential
    end
  end

endmodule
