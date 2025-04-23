// ############################################################################
//  Module: Crossbar
//  Description: This module implements a crossbar switch with 4 inputs 
//               and 4 outputs. Virtual channels are used to separate the
//               data streams to avoid blocking.  
//               Each output has a round-robin arbiter with grant holding 
//               to select the input data stream.            
//  Parameters: P_QUEUE_ADDR_WIDTH - Address width, in turn size for the queues
// ############################################################################

// NOTES: The idea is to have a buffered crossbar where each input has a buffer for each output. (ie input[0] has a queue for output[3:1]) 
//        Currently assuming that the queues are FIFOs with FWFT read instantiated in this module. 
//        The input is from the FCS check modules which provides data, done and destination signal. The done signal is high for the last byte of data in the packet.
//        Destination signal is 3 bits where 0-3 are the output ports and 4 is broadcast. If rx dest == tx port, data is not valid. 5-7 indicates data is not valid.
//        

module crossbar #(
  parameter int P_QUEUE_ADDR_WIDTH = 11 // Address width for the queues // TODO: figure out actual value, currently set to 11 for 2048 bytes per queue
) (
  input  logic clk_i,
  input  logic rstn_i,

  // RX Data and control
  input  logic [7:0] rx_data0,
  input  logic       rx_done0, // rx_done accompanies the last byte of data
  input  logic [2:0] rx_dest0, // 0: tx0, 1: tx1, 2: tx2, 3: tx3, 4: broadcast, 5-7: not valid (data also not valid if dest == port)
  input  logic [7:0] rx_data1,
  input  logic       rx_done1,
  input  logic [2:0] rx_dest1,
  input  logic [7:0] rx_data2,
  input  logic       rx_done2,
  input  logic [2:0] rx_dest2,
  input  logic [7:0] rx_data3,
  input  logic       rx_done3,
  input  logic [2:0] rx_dest3,

  // TX Data and control
  output logic [7:0] tx_data0,
  output logic       tx_ctrl0, // tx_ctrl accompanies valid bytes of data
  output logic [7:0] tx_data1,
  output logic       tx_ctrl1,
  output logic [7:0] tx_data2,
  output logic       tx_ctrl2,
  output logic [7:0] tx_data3,
  output logic       tx_ctrl3
);

  // ##########################################################################
  //  Signals 
  // ##########################################################################
  logic [3:0][2:0] requests_tx;
  logic [3:0][2:0] grants_tx;

  // Virtual channels (data comprises rx_data and bit for eof) first bit is origin, second bit is destination
  // Output port tx0
  logic [8:0] vc10_data;
  logic       vc10_empty;
  logic       vc10_read; // Queues are FWFT, so first element is present when empty is low
  logic       vc10_write;
  logic       vc10_eof_delay;

  logic [8:0] vc20_data;
  logic       vc20_empty;
  logic       vc20_read;
  logic       vc20_write;
  logic       vc20_eof_delay;
  
  logic [8:0] vc30_data;
  logic       vc30_empty;
  logic       vc30_read;
  logic       vc30_write;
  logic       vc30_eof_delay;
  // Output port tx1
  logic [8:0] vc01_data;
  logic       vc01_empty;
  logic       vc01_read;
  logic       vc01_write;
  logic       vc01_eof_delay;

  logic [8:0] vc21_data;
  logic       vc21_empty;
  logic       vc21_read;
  logic       vc21_write;
  logic       vc21_eof_delay;

  logic [8:0] vc31_data;
  logic       vc31_empty;
  logic       vc31_read;
  logic       vc31_write;
  logic       vc31_eof_delay;
  // Output port tx2
  logic [8:0] vc02_data;
  logic       vc02_empty;
  logic       vc02_read;
  logic       vc02_write;
  logic       vc02_eof_delay;

  logic [8:0] vc12_data;
  logic       vc12_empty;
  logic       vc12_read;
  logic       vc12_write;
  logic       vc12_eof_delay;
  
  logic [8:0] vc32_data;
  logic       vc32_empty;
  logic       vc32_read;
  logic       vc32_write;
  logic       vc32_eof_delay;
  // Output port tx3
  logic [8:0] vc03_data;
  logic       vc03_empty;
  logic       vc03_read;
  logic       vc03_write;
  logic       vc03_eof_delay;

  logic [8:0] vc13_data;
  logic       vc13_empty;
  logic       vc13_read;
  logic       vc13_write;
  logic       vc13_eof_delay;
  
  logic [8:0] vc23_data;
  logic       vc23_empty;
  logic       vc23_read;
  logic       vc23_write;
  logic       vc23_eof_delay;


  // ############################################################################
  //  Module Instatiations
  // ############################################################################
  // QUEUES (FIFOs)
  // Queue for port rx1 to tx0
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc10 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc10_write),
    .data_i({rx_done1,rx_data1}),
    .rd_i(vc10_read),
    .data_o(vc10_data),
    .fill_level_o(),
    .empty_o(vc10_empty),
    .full_o()
  );
  // Queue for port rx2 to tx0
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc20 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc20_write),
    .data_i({rx_done2,rx_data2}),
    .rd_i(vc20_read),
    .data_o(vc20_data),
    .fill_level_o(),
    .empty_o(vc20_empty),
    .full_o()
  );
  // Queue for port rx3 to tx0
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc30 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc30_write),
    .data_i({rx_done3,rx_data3}),
    .rd_i(vc30_read),
    .data_o(vc30_data),
    .fill_level_o(),
    .empty_o(vc30_empty),
    .full_o()
  );
  // Queue for port rx0 to tx1
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc01 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc01_write),
    .data_i({rx_done0,rx_data0}),
    .rd_i(vc01_read),
    .data_o(vc01_data),
    .fill_level_o(),
    .empty_o(vc01_empty),
    .full_o()
  );
  // Queue for port rx2 to tx1
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc21 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc21_write),
    .data_i({rx_done2,rx_data2}),
    .rd_i(vc21_read),
    .data_o(vc21_data),
    .fill_level_o(),
    .empty_o(vc21_empty),
    .full_o()
  );
  // Queue for port rx3 to tx1
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc31 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc31_write),
    .data_i({rx_done3,rx_data3}),
    .rd_i(vc31_read),
    .data_o(vc31_data),
    .fill_level_o(),
    .empty_o(vc31_empty),
    .full_o()
  );
  // Queue for port rx0 to tx2 
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc02 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc02_write),
    .data_i({rx_done0,rx_data0}),
    .rd_i(vc02_read),
    .data_o(vc02_data),
    .fill_level_o(),
    .empty_o(vc02_empty),
    .full_o()
  );
  // Queue for port rx1 to tx2
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc12 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc12_write),
    .data_i({rx_done1,rx_data1}),
    .rd_i(vc12_read),
    .data_o(vc12_data),
    .fill_level_o(),
    .empty_o(vc12_empty),
    .full_o()
  );
  // Queue for port rx3 to tx2
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc32 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc32_write),
    .data_i({rx_done3,rx_data3}),
    .rd_i(vc32_read),
    .data_o(vc32_data),
    .fill_level_o(),
    .empty_o(vc32_empty),
    .full_o()
  );
  // Queue for port rx0 to tx3
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc03 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc03_write),
    .data_i({rx_done0,rx_data0}),
    .rd_i(vc03_read),
    .data_o(vc03_data),
    .fill_level_o(),
    .empty_o(vc03_empty),
    .full_o()
  );
  // Queue for port rx1 to tx3
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc13 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc13_write),
    .data_i({rx_done1,rx_data1}),
    .rd_i(vc13_read),
    .data_o(vc13_data),
    .fill_level_o(),
    .empty_o(vc13_empty),
    .full_o()
  );
  // Queue for port rx2 to tx3
  sync_fifo_core #(
    .P_DATA_WIDTH(9), // 8 bits of data + 1 bit for eof
    .P_ADDR_WIDTH(P_QUEUE_ADDR_WIDTH),
    .P_FWFT(1)
  ) u_sync_fifo_core_vc23 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_i(vc23_write),
    .data_i({rx_done2,rx_data2}),
    .rd_i(vc23_read),
    .data_o(vc23_data),
    .fill_level_o(),
    .empty_o(vc23_empty),
    .full_o()
  );
  
  // ARBITERS
  // Arbiter for port tx0 
  arbiter #(.P_WIDTH(3)) arbiter_tx0 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx[0]),
    .grant_o(grants_tx[0])
  );
  // Arbiter for port tx1
  arbiter #(.P_WIDTH(3)) arbiter_tx1 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx[1]),
    .grant_o(grants_tx[1])
  );
  // Arbiter for port tx2
  arbiter #(.P_WIDTH(3)) arbiter_tx2 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx[2]),
    .grant_o(grants_tx[2])
  );
  // Arbiter for port tx3
  arbiter #(.P_WIDTH(3)) arbiter_tx3 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx[3]),
    .grant_o(grants_tx[3])
  );


  // ##########################################################################
  //  Combinational Logic
  // ##########################################################################
  // Place data into queues
  assign vc01_write = ((rx_dest0 == 3'h1) || (rx_dest0 == 3'h4));
  assign vc02_write = ((rx_dest0 == 3'h2) || (rx_dest0 == 3'h4));
  assign vc03_write = ((rx_dest0 == 3'h3) || (rx_dest0 == 3'h4));

  assign vc10_write = ((rx_dest1 == 3'h0) || (rx_dest1 == 3'h4));
  assign vc12_write = ((rx_dest1 == 3'h2) || (rx_dest1 == 3'h4));
  assign vc13_write = ((rx_dest1 == 3'h3) || (rx_dest1 == 3'h4));

  assign vc20_write = ((rx_dest2 == 3'h0) || (rx_dest2 == 3'h4));
  assign vc21_write = ((rx_dest2 == 3'h1) || (rx_dest2 == 3'h4));
  assign vc23_write = ((rx_dest2 == 3'h3) || (rx_dest2 == 3'h4));

  assign vc30_write = ((rx_dest3 == 3'h0) || (rx_dest3 == 3'h4));
  assign vc31_write = ((rx_dest3 == 3'h1) || (rx_dest3 == 3'h4));
  assign vc32_write = ((rx_dest3 == 3'h2) || (rx_dest3 == 3'h4));

  // Make requests for each port
  assign requests_tx[0] = {~vc30_empty & ~vc30_eof_delay, ~vc20_empty & ~vc20_eof_delay, ~vc10_empty & ~vc10_eof_delay};
  assign requests_tx[1] = {~vc31_empty & ~vc31_eof_delay, ~vc21_empty & ~vc21_eof_delay, ~vc01_empty & ~vc01_eof_delay};
  assign requests_tx[2] = {~vc32_empty & ~vc32_eof_delay, ~vc12_empty & ~vc12_eof_delay, ~vc02_empty & ~vc02_eof_delay};
  assign requests_tx[3] = {~vc23_empty & ~vc23_eof_delay, ~vc13_empty & ~vc13_eof_delay, ~vc03_empty & ~vc03_eof_delay};
  
  // Read from Virtual channels on grant
  assign {vc23_read, vc13_read, vc03_read} = grants_tx[3]; 
  assign {vc32_read, vc12_read, vc02_read} = grants_tx[2];
  assign {vc31_read, vc21_read, vc01_read} = grants_tx[1];
  assign {vc30_read, vc20_read, vc10_read} = grants_tx[0];

  // Multiplex data and control signals
  always_comb begin
    // Port Tx 0
    unique case (grants_tx[0])
      3'b001: begin // Grant from rx port 1
        tx_data0 = vc10_data[7:0];
        tx_ctrl0 = 1'b1;
      end
      3'b010: begin // Grant from rx port 2
        tx_data0 = vc20_data[7:0];
        tx_ctrl0 = 1'b1;
      end
      3'b100: begin // Grant from rx port 3
        tx_data0 = vc30_data[7:0];
        tx_ctrl0 = 1'b1;
      end
      default: begin // No grant
        tx_data0 = 8'b0;
        tx_ctrl0 = 1'b0;
      end
    endcase
    // Port Tx 1
    unique case (grants_tx[1])
      3'b001: begin // Grant from rx port 0
        tx_data1 = vc01_data[7:0];
        tx_ctrl1 = 1'b1;
      end
      3'b010: begin // Grant from rx port 2
        tx_data1 = vc21_data[7:0];
        tx_ctrl1 = 1'b1;
      end
      3'b100: begin // Grant from rx port 3
        tx_data1 = vc31_data[7:0];
        tx_ctrl1 = 1'b1;
      end
      default: begin // No grant
        tx_data1 = 8'b0;
        tx_ctrl1 = 1'b0;
      end
    endcase
    // Port Tx 2
    unique case (grants_tx[2])
      3'b001: begin // Grant from rx port 0
        tx_data2 = vc02_data[7:0];
        tx_ctrl2 = 1'b1;
      end
      3'b010: begin // Grant from rx port 1
        tx_data2 = vc12_data[7:0];
        tx_ctrl2 = 1'b1;
      end
      3'b100: begin // Grant from rx port 3
        tx_data2 = vc32_data[7:0];
        tx_ctrl2 = 1'b1;
      end
      default: begin // No grant
        tx_data2 = 8'b0;
        tx_ctrl2 = 1'b0;
      end
    endcase
    // Port Tx 3
    unique case (grants_tx[3])
      3'b001: begin // Grant from rx port 0
        tx_data3 = vc03_data[7:0];
        tx_ctrl3 = 1'b1;
      end
      3'b010: begin // Grant from rx port 1
        tx_data3 = vc13_data[7:0];
        tx_ctrl3 = 1'b1;
      end
      3'b100: begin // Grant from rx port 2
        tx_data3 = vc23_data[7:0];
        tx_ctrl3 = 1'b1;
      end
      default: begin // No grant
        tx_data3 = 8'b0;
        tx_ctrl3 = 1'b0;
      end
    endcase
  end

  // ############################################################################
  //  Sequential Logic (delay for eof)
  // ############################################################################
  always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
      vc10_eof_delay <= 0;
      vc20_eof_delay <= 0;
      vc30_eof_delay <= 0;
      vc01_eof_delay <= 0;
      vc21_eof_delay <= 0;
      vc31_eof_delay <= 0;
      vc02_eof_delay <= 0;
      vc12_eof_delay <= 0;
      vc32_eof_delay <= 0;
      vc03_eof_delay <= 0;
      vc13_eof_delay <= 0;
      vc23_eof_delay <= 0;
    end else begin
      vc10_eof_delay <= vc10_data[8];
      vc20_eof_delay <= vc20_data[8];
      vc30_eof_delay <= vc30_data[8];
      vc01_eof_delay <= vc01_data[8];
      vc21_eof_delay <= vc21_data[8];
      vc31_eof_delay <= vc31_data[8];
      vc02_eof_delay <= vc02_data[8];
      vc12_eof_delay <= vc12_data[8];
      vc32_eof_delay <= vc32_data[8];
      vc03_eof_delay <= vc03_data[8];
      vc13_eof_delay <= vc13_data[8];
      vc23_eof_delay <= vc23_data[8];
    end
  end


endmodule
