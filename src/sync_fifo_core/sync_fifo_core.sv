module sync_fifo_core #(
  parameter int P_DATA_WIDTH = 32,
  parameter int P_ADDR_WIDTH = 7,
  parameter int P_FWFT = 0
) (
  // Clock & Reset
  input  logic clk_i,
  input  logic rstn_i,
  // Control & Data
  input  logic wr_i,
  input  logic [P_DATA_WIDTH-1:0] data_i,
  input  logic rd_i,
  output logic [P_DATA_WIDTH-1:0] data_o,
  // Status
  output logic [P_ADDR_WIDTH:0] fill_level_o,
  output logic empty_o,
  output logic full_o
);
  // Initialize signals
  logic [P_ADDR_WIDTH:0] wr_ptr;
  logic [P_ADDR_WIDTH:0] rd_ptr;
  logic wr_fifo_mem;
  logic rd_fifo_mem;

  // Memory module instantiation
  sdp_1clk_ram #(
    .P_DATA_WIDTH(P_DATA_WIDTH),
    .P_ADDR_WIDTH(P_ADDR_WIDTH)
  ) u_sdp_1clk_ram (
    .clk_i(clk_i),
    .wr_i(wr_fifo_mem),
    .addr_wr_i(wr_ptr[P_ADDR_WIDTH-1:0]),
    .data_wr_i(data_i),
    .rd_i(rd_fifo_mem),
    .addr_rd_i(rd_ptr[P_ADDR_WIDTH-1:0]),
    .data_rd_o(data_o)
  );

  // Combinational logic
  assign full_o       = ({~wr_ptr[P_ADDR_WIDTH],wr_ptr[P_ADDR_WIDTH-1:0]} == rd_ptr);
  assign fill_level_o = (wr_ptr - rd_ptr);

  assign wr_fifo_mem = (wr_i & ~full_o);
  
  // Logic depending on if FIFO is FWFT or not
  generate
    if (P_FWFT == 1) begin: g_fwft_fifo
      logic has_data;
      assign has_data = (wr_ptr != rd_ptr);
      assign rd_fifo_mem = ((rd_i | empty_o) & has_data);

      always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
          empty_o <= 1;
        end else begin
          if (rd_fifo_mem) begin
            empty_o <= 0;
          end else if (rd_i) begin
            empty_o <= 1;
          end
        end
      end

    end else begin: g_no_fwft_fifo
      assign empty_o     = (wr_ptr == rd_ptr);
      assign rd_fifo_mem = (rd_i & ~empty_o);
    
    end
  endgenerate

  // Sequential logic
  always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
      wr_ptr <= 0; 
      rd_ptr <= 0;
    end else begin
      if (wr_fifo_mem) wr_ptr <= wr_ptr + 1;
      if (rd_fifo_mem) rd_ptr <= rd_ptr + 1;
    end
  end

endmodule