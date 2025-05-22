// ############################################################################
//  Module: fcs_check
//  Description: Frame Check Sequence (FCS) checker module.
//               Computes CRC across incoming Ethernet frame data,
//               extracts source and destination MAC addresses,
//               and signals FCS errors and control events.
//  Parameters: 
//    - P_SRC_PORT: Source port identifier used in output metadata.
// ############################################################################

`timescale 1ns / 1ps

module fcs_check #(
  parameter logic [2:0] P_SRC_PORT = 3'd0 // Source port associated with FCS module
) (
  input  logic clk,
  input  logic reset,

  // Input stream
  input  logic        rx_ctrl,      // Indicates valid byte, used for SOF/EOF detection
  input  logic [7:0]  data_in,      // Input byte
  input  logic [2:0]  dst_port_in,  // Destination port to pass through

  // Outputs to next stages
  output logic [7:0]  data_out,     // Output byte
  output logic [2:0]  dst_port_out, // Propagated destination port
  output logic [2:0]  src_port,     // Set to static P_SRC_PORT
  output logic [47:0] dst_mac,      // Extracted destination MAC
  output logic [47:0] src_mac,      // Extracted source MAC
  output logic [1:0]  fcs_error,    // FCS status: 01 = default, 10 = OK, 11 = error
  output logic        en_crossbar_fifo_write, // Enable pulse for crossbar FIFO
  output logic        en_mac_fifo_write,      // Enable pulse for MAC learning FIFO
  output logic        rx_done       // Frame fully received
);

  // ##########################################################################
  //  Internal Signals
  // ##########################################################################

  logic [31:0] fcs_reg;
  logic [1:0]  complement_counter;
  logic [7:0]  data;

  logic [3:0]  byte_count;
  logic        prev_rx_ctrl;
  wire         start_of_frame;
  wire         end_of_frame;

  enum int unsigned {idle, complement_start, process_middle, complement_end} state, next_state;

  // ##########################################################################
  //  Combinational Assignments
  // ##########################################################################

  assign dst_port_out = dst_port_in;
  assign src_port = P_SRC_PORT;
  assign rx_done = end_of_frame;
  assign data_out = data;
  assign start_of_frame =  rx_ctrl & ~prev_rx_ctrl;
  assign end_of_frame   = ~rx_ctrl &  prev_rx_ctrl;

  // ##########################################################################
  //  MAC Address Extraction
  // ##########################################################################

  always_ff @(posedge clk) begin
    if (reset) begin
      prev_rx_ctrl <= 1'b0;
      byte_count   <= 4'd0;
      dst_mac      <= 48'd0;
      src_mac      <= 48'd0;
    end else begin
      prev_rx_ctrl <= rx_ctrl;

      if (start_of_frame) begin
        byte_count <= 1;
        dst_mac    <= {40'h0, data_in};
        src_mac    <= 48'd0;
      end else if (byte_count != 0 && byte_count < 14) begin
        if (byte_count < 6)
          dst_mac <= {dst_mac[39:0], data_in};
        else if (byte_count < 12)
          src_mac <= {src_mac[39:0], data_in};
        byte_count <= byte_count + 1;
      end
    end
  end

  // ##########################################################################
  //  FSM and Output Control
  // ##########################################################################

  always_comb begin
    next_state = idle;
    data = data_in;
    fcs_error = 2'b01;
    en_mac_fifo_write = (byte_count == 12);
    en_crossbar_fifo_write = (byte_count == 14 && state == process_middle);

    case(state)
      idle: begin
        if (start_of_frame) begin
          data = ~data_in;
          next_state = complement_start;
        end else begin
          next_state = idle;
        end
      end

      complement_start: begin
        if (complement_counter < 3) begin
          data = ~data_in;
          next_state = complement_start;
        end else begin
          next_state = process_middle;
        end
      end

      process_middle: begin
        if (end_of_frame) begin
          data = ~data_in;
          next_state = complement_end;
        end else begin
          next_state = process_middle;
        end
      end

      complement_end: begin
        if (complement_counter < 3) begin
          data = ~data_in;
          next_state = complement_end;
        end else if (complement_counter == 3 && fcs_reg == 0) begin
          next_state = idle;
          fcs_error = 2'b10; // FCS OK
        end else begin
          next_state = idle;
          fcs_error = 2'b11; // FCS Error
        end
      end
    endcase
  end

  // ##########################################################################
  //  CRC Computation and State Updates
  // ##########################################################################

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= idle;
      fcs_reg <= 32'd0;
      complement_counter <= 0;
    end else begin
      state <= next_state;

      if (start_of_frame || state != idle && next_state != idle) begin
       begin
            fcs_reg[0]  <= fcs_reg[24] ^ fcs_reg[30] ^ data[0];
            fcs_reg[1]  <= fcs_reg[24] ^ fcs_reg[25] ^ fcs_reg[30] ^ fcs_reg[31] ^ data[1];
            fcs_reg[2]  <= fcs_reg[24] ^ fcs_reg[25] ^ fcs_reg[26] ^ fcs_reg[30] ^ fcs_reg[31] ^ data[2];
            fcs_reg[3]  <= fcs_reg[25] ^ fcs_reg[26] ^ fcs_reg[27] ^ fcs_reg[31] ^ data[3];
            fcs_reg[4]  <= fcs_reg[24] ^ fcs_reg[26] ^ fcs_reg[27] ^ fcs_reg[28] ^ fcs_reg[30] ^ data[4];
            fcs_reg[5]  <= fcs_reg[24] ^ fcs_reg[25] ^ fcs_reg[27] ^ fcs_reg[28] ^ fcs_reg[29] ^ fcs_reg[30] ^ fcs_reg[31] ^ data[5];
            fcs_reg[6]  <= fcs_reg[25] ^ fcs_reg[26] ^ fcs_reg[28] ^ fcs_reg[29] ^ fcs_reg[30] ^ fcs_reg[31] ^ data[6];
            fcs_reg[7]  <= fcs_reg[24] ^ fcs_reg[26] ^ fcs_reg[27] ^ fcs_reg[29] ^ fcs_reg[31] ^ data[7];    
            fcs_reg[8]  <= fcs_reg[0]  ^ fcs_reg[24] ^ fcs_reg[25] ^ fcs_reg[27] ^ fcs_reg[28];
            fcs_reg[9]  <= fcs_reg[1]  ^ fcs_reg[25] ^ fcs_reg[26] ^ fcs_reg[28] ^ fcs_reg[29];
            fcs_reg[10] <= fcs_reg[2]  ^ fcs_reg[24] ^ fcs_reg[26] ^ fcs_reg[27] ^ fcs_reg[29];
            fcs_reg[11] <= fcs_reg[3]  ^ fcs_reg[24] ^ fcs_reg[25] ^ fcs_reg[27] ^ fcs_reg[28];
            fcs_reg[12] <= fcs_reg[4]  ^ fcs_reg[24] ^ fcs_reg[25] ^ fcs_reg[26] ^ fcs_reg[28] ^ fcs_reg[29] ^ fcs_reg[30];
            fcs_reg[13] <= fcs_reg[5]  ^ fcs_reg[25] ^ fcs_reg[26] ^ fcs_reg[27] ^ fcs_reg[29] ^ fcs_reg[30] ^ fcs_reg[31];
            fcs_reg[14] <= fcs_reg[6]  ^ fcs_reg[26] ^ fcs_reg[27] ^ fcs_reg[28] ^ fcs_reg[30] ^ fcs_reg[31];
            fcs_reg[15] <= fcs_reg[7]  ^ fcs_reg[27] ^ fcs_reg[28] ^ fcs_reg[29] ^ fcs_reg[31];
            fcs_reg[16] <= fcs_reg[8]  ^ fcs_reg[24] ^ fcs_reg[28] ^ fcs_reg[29];
            fcs_reg[17] <= fcs_reg[9]  ^ fcs_reg[25] ^ fcs_reg[29] ^ fcs_reg[30];
            fcs_reg[18] <= fcs_reg[10] ^ fcs_reg[26] ^ fcs_reg[30] ^ fcs_reg[31];
            fcs_reg[19] <= fcs_reg[11] ^ fcs_reg[27] ^ fcs_reg[31];
            fcs_reg[20] <= fcs_reg[12] ^ fcs_reg[28];
            fcs_reg[21] <= fcs_reg[13] ^ fcs_reg[29];
            fcs_reg[22] <= fcs_reg[14] ^ fcs_reg[24];
            fcs_reg[23] <= fcs_reg[15] ^ fcs_reg[24] ^ fcs_reg[25] ^ fcs_reg[30];
            fcs_reg[24] <= fcs_reg[16] ^ fcs_reg[25] ^ fcs_reg[26] ^ fcs_reg[31];
            fcs_reg[25] <= fcs_reg[17] ^ fcs_reg[26] ^ fcs_reg[27];
            fcs_reg[26] <= fcs_reg[18] ^ fcs_reg[24] ^ fcs_reg[27] ^ fcs_reg[28] ^ fcs_reg[30];
            fcs_reg[27] <= fcs_reg[19] ^ fcs_reg[25] ^ fcs_reg[28] ^ fcs_reg[29] ^ fcs_reg[31];
            fcs_reg[28] <= fcs_reg[20] ^ fcs_reg[26] ^ fcs_reg[29] ^ fcs_reg[30];
            fcs_reg[29] <= fcs_reg[21] ^ fcs_reg[27] ^ fcs_reg[30] ^ fcs_reg[31];
            fcs_reg[30] <= fcs_reg[22] ^ fcs_reg[28] ^ fcs_reg[31];
            fcs_reg[31] <= fcs_reg[23] ^ fcs_reg[29];
      end

      end else begin
        fcs_reg <= 32'd0;
      end

      // Complement counter for pre/post-processing
      if (start_of_frame || end_of_frame) begin
        complement_counter <= 0;
      end else if (complement_counter < 3) begin
        complement_counter <= complement_counter + 1;
      end
    end
  end

endmodule

