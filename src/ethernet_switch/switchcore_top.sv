`timescale 1ns / 1ps
// This module has the same name and port map as the (dummy) switchcore in the De4_SWitch project

module switchcore #(
    parameter int P_ADDR_WIDTH = 7
  ) (
    input  logic                         clk,
    input  logic                         reset,
    input  logic [3:0]                   link_sync, // High indicates a peer connection at the physical layer
    output logic [31:0]                  tx_data,   // [7:0]=TXD0 ... [31:24]=TXD3
    output logic [3:0]                   tx_ctrl,   // 0=TXC0 ... 3=TXC3
    input  logic [31:0]                  rx_data,   // [7:0]=RXD0 ... [31:24]=RXD3
    input  logic [3:0]                   rx_ctrl    // 0=RXC0 ... 3=RXC3
  );

  ///////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  ///////////////////////////////////////////////////////////////////////////////

  //--------------------------------------------------------------------------
  // Signals for crossbar
  //--------------------------------------------------------------------------
  logic [7:0]     rx_data0;
  logic [7:0]     rx_data1;
  logic [7:0]     rx_data2;
  logic [7:0]     rx_data3;
  logic [7:0]     tx_data0;
  logic [7:0]     tx_data1;
  logic [7:0]     tx_data2;
  logic [7:0]     tx_data3;

  assign rx_data0 = rx_data[7:0];
  assign rx_data1 = rx_data[15:8];
  assign rx_data2 = rx_data[23:16];
  assign rx_data3 = rx_data[31:24];

  assign tx_data[7:0]   = tx_data0;
  assign tx_data[15:8]  = tx_data1;
  assign tx_data[23:16] = tx_data2;
  assign tx_data[31:24] = tx_data3;

  //--------------------------------------------------------------------------
  // Clock & Reset
  //--------------------------------------------------------------------------
  logic clk_i;
  logic rstn_i;
  assign clk_i = clk;
  assign rstn_i = reset;

  //--------------------------------------------------------------------------
  // FCS-check nets (one bit per of 4 lanes)
  //--------------------------------------------------------------------------
  logic [7:0]  data_in        [3:0];
  logic [2:0]  dst_port_in    [3:0];
  logic [1:0]  fcs_error      [3:0];
  logic        en_crossbar_fifo_read [3:0];
  logic        en_mac_fifo_read      [3:0];
  logic [47:0] dst_mac        [3:0];
  logic [47:0] src_mac        [3:0];
  logic [2:0]  src_port       [3:0];
  logic [2:0]  dst_port       [3:0];
  logic [7:0]  data_out       [3:0];
  logic        rx_done        [3:0];
  logic [2:0]  dst_port_out   [3:0];
  logic        done_in        [3:0];

  assign data_in[0] = rx_data0;
  assign data_in[1] = rx_data1;
  assign data_in[2] = rx_data2;
  assign data_in[3] = rx_data3;


  //--------------------------------------------------------------------------
  // Signals for FIFO control between FCS-check and crossbar
  //--------------------------------------------------------------------------
  logic [8:0]  data_fifo_fcs_out[3:0];

  logic [12:0] fill_level_o_fcs [3:0]; // Maybe not needed
  logic        empty_o_fcs [3:0]; // Maybe not needed
  logic        full_o_fcs  [3:0]; // Maybe not needed


  //--------------------------------------------------------------------------
  // Signals for FIFO control between FCS-check and mac learning
  //--------------------------------------------------------------------------
  logic  [3:0]       en_mac_fifo_write;
  logic [98:0]  data_mac_fifo_out    [3:0];

  logic [P_ADDR_WIDTH:0] fill_level_o_mac[3:0];
  logic  [3:0]       empty_o_mac;
  logic  [3:0]      full_o_mac;

  //--------------------------------------------------------------------------
  // Signals for Trash Control
  //--------------------------------------------------------------------------
  logic en_crossbar_fifo_write [3:0];
  logic sel [3:0];
  logic [2:0] rx_dst_port [3:0];


  //--------------------------------------------------------------------------
  // Signals for demuxing the data from the FCS check
  //--------------------------------------------------------------------------
  logic [8:0]  data_fifo_demux_out [3:0];

  //--------------------------------------------------------------------------
  // Signals for arbiter control between FCS-check and mac learning
  //--------------------------------------------------------------------------
  logic        busy_mac;
  wire  [3:0]  arb_request = ~empty_o_mac & {4{~busy_mac}};


  //--------------------------------------------------------------------------
  // Signals for muxing the data from the MAC learning
  //--------------------------------------------------------------------------
  logic [47:0] src_mac_mux;
  logic [47:0] dst_mac_mux;
  logic [2:0]  src_port_mux;



  //------------------------------------------------------------------------
  // Signals for MAC learning
  //------------------------------------------------------------------------
  logic [2:0]  dst_port_mac;
  logic        done_mac;
  logic [1:0]  tag_port;


  //--------------------------------------------------------------------------
  // Signals for demuxing the data from the MAC learning
  //--------------------------------------------------------------------------


  ///////////////////////////////////////////////////////////////////////////////
  // MODULE INSTANTIATIONS
  ///////////////////////////////////////////////////////////////////////////////

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1)
    begin : lane
      // 4 x FCS check modules
      fcs_check #(.P_SRC_PORT(i)) fcs_check_inst (
                  .clk            (clk),
                  .reset          (reset),
                  .rx_ctrl        (rx_ctrl[i]),
                  .data_in        (data_in[i]),
                  .done_in        (done_in[i]),
                  .dst_port_in    (dst_port_in[i]),
                  .fcs_error      (fcs_error[i]),
                  .en_crossbar_fifo_read (en_crossbar_fifo_read[i]),
                  .en_mac_fifo_read   (en_mac_fifo_read[i]),
                  .dst_mac        (dst_mac[i]),
                  .src_mac        (src_mac[i]),
                  .src_port       (src_port[i]),
                  .data_out       (data_out[i]),
                  .rx_done       (rx_done[i]),
                  .dst_port_out   (dst_port_out[i])
                );

      // 4 x Sync‐FIFO buffer
      // between the FCS check and the crossbar
      sync_fifo_core #(.P_ADDR_WIDTH(12), .P_DATA_WIDTH(9) ) fifo_fcs_out (
                       .clk_i         (clk),
                       .rstn_i        (reset),
                       .wr_i          (en_crossbar_fifo_write[i]),
                       .data_i        ({data_out[i], rx_done[i]}),
                       .rd_i          (en_crossbar_fifo_read[i]),
                       .data_o        (data_fifo_fcs_out[i]),
                       .fill_level_o  (fill_level_o_fcs[i]),
                       .empty_o       (empty_o_fcs[i]),
                       .full_o        (full_o_fcs[i])
                     );

      // 4 x Sync‐FIFO buffer
      // between the FCS check and the MAC learning
      sync_fifo_core #(.P_ADDR_WIDTH(7), .P_DATA_WIDTH(99) ) fifo_mac_learning (
                       .clk_i         (clk),
                       .rstn_i        (reset),
                       .wr_i          (en_mac_fifo_write[i]),
                       .data_i({src_mac[i], dst_mac[i], src_port[i]}),
                       .rd_i          (en_mac_fifo_read[i]),
                       .data_o        (data_mac_fifo_out[i]),
                       .fill_level_o  (fill_level_o_mac[i]),
                       .empty_o       (empty_o_mac[i]),
                       .full_o        (full_o_mac[i])
                     );

      // 4 x Trash Control
      trash_control trash_control (
                      .clk(clk),
                      .reset(reset),
                      .fcs_error(fcs_error[i]),
                      .done(data_fifo_fcs_out[i][8]), // done signal from the FCS check
                      .dst_port(dst_port_out[i]), // dst_port from the FCS check
                      .en(en_crossbar_fifo_write[i]),
                      .sel(sel[i]),
                      .rx_dst_port(rx_dst_port[i])
                    );


      // 4 x Demux for the FCS check
      demux1to2 demux_fcs_out (
                  .din(data_fifo_fcs_out[i]),
                  .sel(sel[i]),
                  .out(data_fifo_demux_out[i]),
                  .trash() // Not used
                );

    end

  endgenerate

  // 1 x Crossbar
  crossbar #(.P_QUEUE_ADDR_WIDTH(11)) crossbar_module (
             .clk_i(clk),
             .rstn_i(reset),
             .rx_dest0(rx_dst_port[0]),
             .rx_dest1(rx_dst_port[1]),
             .rx_dest2(rx_dst_port[2]),
             .rx_dest3(rx_dst_port[3]),
             .rx_data0(data_fifo_demux_out[0][7:0]),
             .rx_data1(data_fifo_demux_out[1][7:0]),
             .rx_data2(data_fifo_demux_out[2][7:0]),
             .rx_data3(data_fifo_demux_out[3][7:0]),
             .rx_done0(data_fifo_demux_out[0][8]),
             .rx_done1(data_fifo_demux_out[1][8]),
             .rx_done2(data_fifo_demux_out[2][8]),
             .rx_done3(data_fifo_demux_out[3][8]),
             .tx_data0(tx_data0),
             .tx_data1(tx_data1),
             .tx_data2(tx_data2),
             .tx_data3(tx_data3),
             .tx_ctrl0(tx_ctrl[0]),
             .tx_ctrl1(tx_ctrl[1]),
             .tx_ctrl2(tx_ctrl[2]),
             .tx_ctrl3(tx_ctrl[3])
           );



  // 1 x Arbiter for the MAC learning
  arbiter #(.P_WIDTH(4)) fifo_arb (
            .clk_i     (clk),
            .rstn_i    (reset),
            .request_i (arb_request),    // q_empty[i]=1 means FIFO is empty
            .grant_o   (en_mac_fifo_write)         // arb_rd[i]=1 pulses rd_i for FIFO i
          );

  // 1 x Mux for the MAC learning
  mux4to1 #(.WIDTH(99)) mux_mac_learning (
            .sel(en_mac_fifo_write),
            .in0(data_mac_fifo_out[0]),
            .in1(data_mac_fifo_out[1]),
            .in2(data_mac_fifo_out[2]),
            .in3(data_mac_fifo_out[3]),
            .out({src_mac_mux, dst_mac_mux, src_port_mux})
          );



  // 1 x Mac learning
  mac_learning #( .TIMER_SIZE(30) ) m_learn_module (
                 .clk(clk),
                 .rst(reset),
                 .src_mac(src_mac_mux),
                 .dst_mac(dst_mac_mux),
                 .src_port(src_port_mux),
                 .dst_port(dst_port_mac),
                 .en(|en_mac_fifo_write),
                 .done(done_mac),
                 .tag_port(tag_port),
                 .busy(busy_mac)
               );

  // 1 x Demux for the MAC learning
  demux1to4 #(.WIDTH(4)) demux_mac_learning (
              .sel(tag_port),
              .data_in({done_mac, dst_port_mac}),
              .data_out0({done_in[0], dst_port_in[0]}),
              .data_out1({done_in[1], dst_port_in[1]}),
              .data_out2({done_in[2], dst_port_in[2]}),
              .data_out3({done_in[3], dst_port_in[3]})
            );



endmodule














