module sync_fifo_core_tb;

  // TB parameters 
  parameter real PERIOD_A = 6;
  parameter real PERIOD_B = 10;

  // Module parameters 
  parameter int P_DATA_WIDTH = 8;
  parameter int P_ADDR_WIDTH = 4;
  parameter int P_FWFT = 1; // 1: FWFT, 0: Non-FWFT

  // Clocks and reset
  logic clk_i = 0;
  logic rst_i = 1;

  logic                    wr_i = 0;
  logic [P_ADDR_WIDTH:0]   fill_level_o;
  logic [P_DATA_WIDTH-1:0] data_i = 0;
  logic                    rd_i = 0;
  logic [P_DATA_WIDTH-1:0] data_o;  
  logic                    empty_o;
  logic                    full_o;

  sync_fifo_core #(
    .P_DATA_WIDTH(P_DATA_WIDTH),
    .P_ADDR_WIDTH(P_ADDR_WIDTH),
    .P_FWFT(P_FWFT)
  ) u_sync_fifo_core(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wr_i(wr_i),
    .data_i(data_i),
    .rd_i(rd_i),
    .data_o(data_o),
    .fill_level_o(fill_level_o),
    .empty_o(empty_o),
    .full_o(full_o)
  );

  // Reference model
  logic [P_DATA_WIDTH-1:0] ref_fifo [$];
  int mismatches = 0;
  int total_read = 0;
  int total_written = 0;
  logic rd_delay;
  int burst_len;
  int fifo_free_space;

  assign rd_i = ~empty_o & ~rst_i; // Always read when data present in FIFO

  initial begin
    // Dump Waveform
    $dumpfile("dump.vcd");
    $dumpvars();
    $display("############## SIM STARTED  ##############");
    #(PERIOD_A*2) rst_i = 0;
    $display("############# RESET RELEASED #############");
    #(PERIOD_A*3);

    $display("#### FIFO Out Matched with Reference  ####");
    for(int i = 0; i<100; i++) begin // Random stimuli in bursts (behaving nicely not trying to overfill FIFO)
      fifo_free_space = (32)'((2**P_ADDR_WIDTH)-fill_level_o);
      if(fifo_free_space == 0) begin
        #PERIOD_A;
      end else begin
        burst_len = $urandom_range(fifo_free_space, 1);
        write_fifo(burst_len);
      end
    end

    // Try to overfill FIFO
    burst_len = 100; // Set burst high, so we keep trying to write (no pauses)
    write_fifo(burst_len);
    
    #(PERIOD_A*100);
    $display("############## SIM FINISHED ##############");
    if (total_read == total_written) $display("## Total elements through FIFO: %0d", total_read);
    else $display("## Elements READ from FIFO:%0d\n## Elements WRITTEN to FIFO: %0d (ERROR NOT MATCHING)",total_read,total_written);
    $display("## Amount of data mismatches: %0d", mismatches);
    $finish;

  end

  // Clock Control
  initial forever begin // CLOCK A
    #(PERIOD_A/2) clk_i = ~clk_i;
  end


  // Check data read from FIFO  
  if (P_FWFT == 1) begin: g_read_fwft
    always_ff @(posedge clk_i) begin
      if (rd_i) begin 
        total_read++;
        $display("FIFO: %h\tREF:%h",data_o,ref_fifo[$]);
        if (ref_fifo.pop_back() != data_o) mismatches++; // Increment mismatches if not equal to reference
      end

    end
  end else begin: g_read_non_fwft
    always_ff @(posedge clk_i) begin
      rd_delay <= rd_i; // Propagate read signal (so we have a signal corresponding to data out)
      if (rd_i) total_read++;
      if (rd_delay) begin // If data on output
        $display("FIFO: %h\tREF:%h",data_o,ref_fifo[$]);
        if (ref_fifo.pop_back() != data_o) mismatches++; // Increment mismatches if not equal to reference
      end

    end
  end

  // TASKS
  task automatic write_fifo(int burst_len);
    logic [P_DATA_WIDTH-1:0] write_data;
    
    @(posedge clk_i);
    wr_i = 1;
    for(int i = 0; i<burst_len; i++) begin
      write_data = (P_DATA_WIDTH)'($urandom());
      data_i = write_data;
      if (ref_fifo.size()<(2**P_ADDR_WIDTH-1)) begin // Check against reference model
        ref_fifo.push_front(write_data); // Don't add to ref model if FIFO full
        total_written++;
      end
      #PERIOD_A;
    end
    wr_i = 0;
    data_i = 0;
    #PERIOD_A;

  endtask


endmodule