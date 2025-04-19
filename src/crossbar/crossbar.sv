// ############################################################################
//  Module: Crossbar
//  Description: This module implements a crossbar switch with 4 inputs 
//               and 4 outputs. Virtual channels are used to separate the
//               data streams. (Queues are instantiated in switchcore)  
//               Each output has a round-robin arbiter with grant holding 
//               to select the input data stream.            
//  Parameters: None
// ############################################################################

module crossbar #() (
  input  logic clk_i,
  input  logic rstn_i,
  // Virtual channels (data comprises rx_data and bit for eof) first bit is origin, second bit is destination
  // Output port tx0
  input  logic [8:0] vc10_data_i,
  input  logic       vc10_empty_i,
  output logic       vc10_read_i, // Queues are FWFT, so first element is present when empty is low
  input  logic [8:0] vc20_data_i,
  input  logic       vc20_empty_i,
  output logic       vc20_read_i,
  input  logic [8:0] vc30_data_i,
  input  logic       vc30_empty_i,
  output logic       vc30_read_i,
  // Output port tx1
  input  logic [8:0] vc01_data_i,
  input  logic       vc01_empty_i,
  output logic       vc01_read_i,
  input  logic [8:0] vc21_data_i,
  input  logic       vc21_empty_i,
  output logic       vc21_read_i,
  input  logic [8:0] vc31_data_i,
  input  logic       vc31_empty_i,
  output logic       vc31_read_i,
  // Output port tx2
  input  logic [8:0] vc02_data_i,
  input  logic       vc02_empty_i,
  output logic       vc02_read_i,
  input  logic [8:0] vc12_data_i,
  input  logic       vc12_empty_i,
  output logic       vc12_read_i,
  input  logic [8:0] vc32_data_i,
  input  logic       vc32_empty_i,
  output logic       vc32_read_i,
  // Output port tx3
  input  logic [8:0] vc03_data_i,
  input  logic       vc03_empty_i,
  output logic       vc03_read_i,
  input  logic [8:0] vc13_data_i,
  input  logic       vc13_empty_i,
  output logic       vc13_read_i,
  input  logic [8:0] vc23_data_i,
  input  logic       vc23_empty_i,
  output logic       vc23_read_i,
  // TX Data and control
  output logic [7:0] tx_data0,
  output logic       tx_ctrl0,
  output logic [7:0] tx_data1,
  output logic       tx_ctrl1,
  output logic [7:0] tx_data2,
  output logic       tx_ctrl2,
  output logic [7:0] tx_data3,
  output logic       tx_ctrl3

);
// NOTES: The idea is to have a buffered crossbar where each input has a buffer for each output. (ie input[0] has a queue for output[3:1]) 
//        Currently assuming that the queues are FIFOs with FWFT read instantiated in the switchcore.
//        Also assuming that the frames put into the FIFO are accompanied by a bit indicating eof for the last element of the frame. (otherwise 0)

  // ##########################################################################
  //  Signals 
  // ##########################################################################
  logic [2:0] requests_tx0; // TODO comments in arbiter connections
  logic [2:0] requests_tx1;
  logic [2:0] requests_tx2;
  logic [2:0] requests_tx3;

  logic [2:0] grants_tx0;
  logic [2:0] grants_tx1;
  logic [2:0] grants_tx2;
  logic [2:0] grants_tx3;

  logic       vc10_eof_delay;
  logic       vc20_eof_delay;
  logic       vc30_eof_delay;
  logic       vc01_eof_delay;
  logic       vc21_eof_delay;
  logic       vc31_eof_delay;
  logic       vc02_eof_delay;
  logic       vc12_eof_delay;
  logic       vc32_eof_delay;
  logic       vc03_eof_delay;
  logic       vc13_eof_delay;
  logic       vc23_eof_delay;


  // ############################################################################
  //  Module Instatiations
  // ############################################################################
  // Arbiter for port tx0 
  arbiter #(.P_WIDTH(3)) arbiter_tx0 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx0),
    .grant_o(grants_tx0)
  );
  // Arbiter for port tx1
  arbiter #(.P_WIDTH(3)) arbiter_tx1 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx1),
    .grant_o(grants_tx1)
  );
  // Arbiter for port tx2
  arbiter #(.P_WIDTH(3)) arbiter_tx2 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx2),
    .grant_o(grants_tx2)
  );
  // Arbiter for port tx3
  arbiter #(.P_WIDTH(3)) arbiter_tx3 (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .request_i(requests_tx3),
    .grant_o(grants_tx3)
  );


  // ##########################################################################
  //  Combinational Logic
  // ##########################################################################
  // Make requests for each port
  assign requests_tx0 = {vc30_empty_i & ~vc30_eof_delay, vc20_empty_i & ~vc20_eof_delay, vc10_empty_i & ~vc10_eof_delay};
  assign requests_tx1 = {vc31_empty_i & ~vc31_eof_delay, vc21_empty_i & ~vc21_eof_delay, vc01_empty_i & ~vc01_eof_delay};
  assign requests_tx2 = {vc32_empty_i & ~vc32_eof_delay, vc12_empty_i & ~vc12_eof_delay, vc02_empty_i & ~vc02_eof_delay};
  assign requests_tx3 = {vc23_empty_i & ~vc23_eof_delay, vc13_empty_i & ~vc13_eof_delay, vc03_empty_i & ~vc03_eof_delay};
  
  // Read from Virtual channels on grant
  assign {vc23_read_i, vc13_read_i, vc03_read_i} = grants_tx3; 
  assign {vc32_read_i, vc12_read_i, vc02_read_i} = grants_tx2;
  assign {vc31_read_i, vc21_read_i, vc01_read_i} = grants_tx1;
  assign {vc30_read_i, vc20_read_i, vc10_read_i} = grants_tx0;

  // Multiplex data and control signals
  always_comb begin
    // Port Tx 0
    unique case (grants_tx0)
      3'b001: begin // Grant from rx port 1
        tx_data0 = vc10_data_i[7:0];
        tx_ctrl0 = 1'b1;
      end
      3'b010: begin // Grant from rx port 2
        tx_data0 = vc20_data_i[7:0];
        tx_ctrl0 = 1'b1;
      end
      3'b100: begin // Grant from rx port 3
        tx_data0 = vc30_data_i[7:0];
        tx_ctrl0 = 1'b1;
      end
      default: begin // No grant
        tx_data0 = 8'b0;
        tx_ctrl0 = 1'b0;
      end
    endcase
    // Port Tx 1
    unique case (grants_tx1)
      3'b001: begin // Grant from rx port 0
        tx_data1 = vc01_data_i[7:0];
        tx_ctrl1 = 1'b1;
      end
      3'b010: begin // Grant from rx port 2
        tx_data1 = vc21_data_i[7:0];
        tx_ctrl1 = 1'b1;
      end
      3'b100: begin // Grant from rx port 3
        tx_data1 = vc31_data_i[7:0];
        tx_ctrl1 = 1'b1;
      end
      default: begin // No grant
        tx_data1 = 8'b0;
        tx_ctrl1 = 1'b0;
      end
    endcase
    // Port Tx 2
    unique case (grants_tx2)
      3'b001: begin // Grant from rx port 0
        tx_data2 = vc02_data_i[7:0];
        tx_ctrl2 = 1'b1;
      end
      3'b010: begin // Grant from rx port 1
        tx_data2 = vc12_data_i[7:0];
        tx_ctrl2 = 1'b1;
      end
      3'b100: begin // Grant from rx port 3
        tx_data2 = vc32_data_i[7:0];
        tx_ctrl2 = 1'b1;
      end
      default: begin // No grant
        tx_data2 = 8'b0;
        tx_ctrl2 = 1'b0;
      end
    endcase
    // Port Tx 3
    unique case (grants_tx3)
      3'b001: begin // Grant from rx port 0
        tx_data3 = vc03_data_i[7:0];
        tx_ctrl3 = 1'b1;
      end
      3'b010: begin // Grant from rx port 1
        tx_data3 = vc13_data_i[7:0];
        tx_ctrl3 = 1'b1;
      end
      3'b100: begin // Grant from rx port 2
        tx_data3 = vc23_data_i[7:0];
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
      vc10_eof_delay <= vc10_data_i[8];
      vc20_eof_delay <= vc20_data_i[8];
      vc30_eof_delay <= vc30_data_i[8];
      vc01_eof_delay <= vc01_data_i[8];
      vc21_eof_delay <= vc21_data_i[8];
      vc31_eof_delay <= vc31_data_i[8];
      vc02_eof_delay <= vc02_data_i[8];
      vc12_eof_delay <= vc12_data_i[8];
      vc32_eof_delay <= vc32_data_i[8];
      vc03_eof_delay <= vc03_data_i[8];
      vc13_eof_delay <= vc13_data_i[8];
      vc23_eof_delay <= vc23_data_i[8];
    end
  end


endmodule
