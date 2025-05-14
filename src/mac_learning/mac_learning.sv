`timescale 1ns / 1ps


module dual_port_bram #(
  parameter int HASH_WIDTH  = 32,
  parameter int BRAM_WIDTH  = 10,
  parameter int DATA_WIDTH  = 4
)(
  input  logic                    clk,
  input  logic                    wen,
  input  logic                    ren,
  input  logic [HASH_WIDTH-1:0]   addra,
  input  logic [HASH_WIDTH-1:0]   addrb,
  input  logic [DATA_WIDTH-1:0]   dia,
  output logic [DATA_WIDTH-1:0]   dob
);

  // Local constants
  localparam int DEPTH = 1 << BRAM_WIDTH;

  // Quartus RAM‐style attribute:
  // change "M10K" to "M9K" or "MLAB" if you prefer a different block
  (* ramstyle = "M10K" *) logic [DATA_WIDTH-1:0] ram [0:DEPTH-1];

  // Compute effective BRAM addresses by modulo
  wire [31:0] addr_a_full = addra & (DEPTH-1);
  wire [BRAM_WIDTH-1:0] addr_a = addr_a_full[BRAM_WIDTH-1:0];
  
  wire [31:0] addr_b_full = addrb & (DEPTH-1);
  wire [BRAM_WIDTH-1:0] addr_b = addr_b_full[BRAM_WIDTH-1:0];

  // Single‐clock dual‐port: write and read can happen in same cycle
  always_ff @(posedge clk) begin
    if (wen)    ram[addr_a] <= dia;
    if (ren)    dob        <= ram[addr_b];
  end

endmodule











module mac_learning#(
    parameter int BRAM_START_INDEX = 0,
    parameter int INIT_COUNT = 0,
    parameter bit [26:0] COUNT_THRES = 124999999,
    parameter TIMER_SIZE = 30 // bits allocated to timeout timer
  )(
    input clk,
    input rst,
    input en,
    input [47:0] src_mac,
    input [47:0] dst_mac,
    input [2:0] src_port,
    output reg done,
    output reg [2:0] dst_port,
    output reg [1:0] tag_port,
    output reg busy
  );

  localparam int HASH_WIDTH   = 32;
  localparam bit [HASH_WIDTH-1:0]
             FNV_PRIME  = 32'h01000193,
             FNV_OFFSET = 32'h811c9dc5;

  logic [35:0] info_in;
  wire  [35:0] info_out;

	
  logic [HASH_WIDTH-1:0] src_hash, dst_hash;

  // implementing sweeping with two parallel FSM controlled by the sweep_mode, that is determined by the mac_learning en
  logic sweep_mode, bram_wen, bram_ren, sweep_wen, sweep_ren, learning_wen, learning_ren;
  logic [31:0] bram_addra, sweep_addr, learning_addra, bram_addrb, learning_addrb;
  logic [35:0] sweep_din = 0, learning_din, bram_din;

  assign bram_addra = sweep_mode ? sweep_addr   : learning_addra;
  assign bram_addrb = sweep_mode ? sweep_addr   : learning_addrb;
  assign bram_din  = sweep_mode ? sweep_din    : learning_din;
  assign bram_wen  = sweep_mode ? sweep_wen    : learning_wen;
  assign bram_ren  = sweep_mode ? sweep_ren    : learning_ren;
  
  logic [26:0] one_hz_counter;
  logic [31:0] five_minute_counter;

  logic en_d;

  logic [47:0] src_mac_reg;
  logic [47:0] dst_mac_reg;
  logic [2:0]  src_port_reg;
  
  
  always_ff @(posedge clk) begin
	en_d <= en;
	if (en_d) begin
		src_mac_reg <= src_mac;
		dst_mac_reg <= dst_mac;
		src_port_reg <= src_port;
	end
  end
	
  logic [HASH_WIDTH-1:0] new_src_hash, new_dst_hash;


  dual_port_bram #( .HASH_WIDTH(32), .BRAM_WIDTH(13), .DATA_WIDTH(36) ) hash_ram (
                   .clk (clk),
                   .wen (bram_wen),
                   .ren  (bram_ren),
                   .addra (bram_addra),
                   .addrb (bram_addrb),
                   .dia (bram_din),
                   .dob (info_out)
                 );


  logic [31:0] hash_p0_src, hash_p1_src;
  logic [31:0] hash_p0_dst, hash_p1_dst;
  logic done_hashing;
  logic begin_hashing;
  logic [2:0] count_hash;
  
	
  
	always_ff @(posedge clk) begin
	  if (begin_hashing && !done_hashing ) begin
		 hash_p0_src <= ((FNV_OFFSET ^ src_mac_reg[5*8 +:8])
								* FNV_PRIME ^ src_mac_reg[4*8 +:8])
							  * FNV_PRIME & 32'hFFFFFFFF;
		 hash_p0_dst <= ((FNV_OFFSET ^ dst_mac_reg[5*8 +:8])
								* FNV_PRIME ^ dst_mac_reg[4*8 +:8])
							  * FNV_PRIME & 32'hFFFFFFFF;
		 hash_p1_src <= ((hash_p0_src ^ src_mac_reg[3*8 +:8])
                   * FNV_PRIME ^ src_mac_reg[2*8 +:8])
                  * FNV_PRIME & 32'hFFFFFFFF;
       hash_p1_dst <= ((hash_p0_dst ^ dst_mac_reg[3*8 +:8])
                   * FNV_PRIME ^ dst_mac_reg[2*8 +:8])
                  * FNV_PRIME & 32'hFFFFFFFF;
		 new_src_hash  <= ((hash_p1_src ^ src_mac_reg[1*8 +:8])
                     * FNV_PRIME ^ src_mac_reg[0*8 +:8])
                    * FNV_PRIME & 32'hFFFFFFFF;
       new_dst_hash  <= ((hash_p1_dst ^ dst_mac_reg[1*8 +:8])
                     * FNV_PRIME ^ dst_mac_reg[0*8 +:8])
                    * FNV_PRIME & 32'hFFFFFFFF;
		 if (count_hash < 2)
			count_hash <= count_hash + 1;
		 else
			done_hashing <= 1;
	  end else begin
		 done_hashing <= 0;
		 count_hash <= 0;
	  end
	end
    
  
  enum logic [1:0] {IDLE_, LOOKUP, FORWARD, LEARN} learning_state_t;
  enum logic [1:0] {IDLE, READ, CHECK, CLEAR} sweep_state_t;
  
  logic [35:0] sweep_data;
  assign busy = ( (learning_state_t != IDLE_) || (en_d) );

  always_ff @(posedge clk)
  begin
    if (rst)
    begin
      sweep_state_t <= IDLE;
      sweep_addr <= BRAM_START_INDEX;
      sweep_din <= 0;
    end
    else if (sweep_mode)
    begin
      case (sweep_state_t)
        IDLE:
        begin
          sweep_state_t <= READ;
        end

        READ:
        begin
          sweep_state_t <= CHECK;
        end

        CHECK:
        begin
          sweep_data <= info_out;
          /*
			 assert( info_out[35:4] < five_minute_counter ) else
          begin
            $display("MAC_LEARNING: Does not detect time violation!");
          end
			 */
          if ( info_out[35:4] < five_minute_counter )
          begin
            sweep_state_t <= CLEAR;
          end
          else
          begin
            sweep_addr <= sweep_addr + 1;
            sweep_state_t <= READ;
          end
        end

        CLEAR:
        begin
          sweep_addr <= sweep_addr + 1;
          sweep_state_t <= READ;
        end
      endcase
    end
  end


  always_comb
  begin
    sweep_ren = (sweep_state_t == READ);
    sweep_wen = ((sweep_state_t == CHECK) && (info_out[35:4] < five_minute_counter)); // CHANGE BACK
    learning_ren = (learning_state_t == LOOKUP);
    learning_wen = (learning_state_t == LEARN);
	 learning_addrb = new_dst_hash;
	 learning_addra = new_src_hash;
  end



  always_ff @(posedge clk)
  begin
  
    if (rst)
    begin
		tag_port <= 0;
      learning_state_t <= IDLE_;
      dst_port <= 3'b110; // default value : INVALID
      done <= 0;
      sweep_mode <= 1;
    end
    else
    begin
		
	 	if (learning_state_t != IDLE_) begin
			  $display("MAC_LEARNING: At time %0t: en_d = %b, state = %0d, sweep_mode = %0d, bram_wen = %0d, bram_ren = %0d, bram_addr_read = %0h, bram_addr_write = %0h, learning_ren = %0d, learning_wen = %0d", $time, en_d, learning_state_t, 
				sweep_mode, bram_wen, bram_ren, bram_addra, bram_addrb, learning_ren, learning_wen);
			  $display("MAC_LEARNING: new_dst_hash = %0h new_src_hash = %0h", new_dst_hash, new_src_hash, );
		end
	 
      case (learning_state_t)
        IDLE_:
        begin
          done  <= 0;
          sweep_mode <= 1;
          if (en_d)
          begin
			   tag_port <= src_port[1:0];   
            learning_state_t <= LOOKUP;
            sweep_mode <= 0;
          end
        end
        LOOKUP:
        begin
		    begin_hashing <= 1;
			 if (done_hashing)
				learning_state_t <= FORWARD;
        end
        FORWARD:
        begin
          assert (info_out[0] == 1'bx || info_out[0] == 1'bz) else
				$error("MAC_LEARNING: info_out is not found in memory at time %0t", $time);

          if (info_out[0]) // if valid
            dst_port <= info_out[3:1];
          else
            dst_port <= 3'b100; 
          learning_din   <= {five_minute_counter, src_port_reg, 1'b1};
          learning_state_t <= LEARN;
			 done <= 1;
			 $display("MAC_LEARNING: Time = %0d, tag_port = %0b, done = %0b, dst_port = %0b",$time, tag_port, done, dst_port);
        end
        LEARN:
        begin
		    $display("MAC_LEARNING: Time = %0d, tag_port = %0b, done = %0b, dst_port = %0b",$time, tag_port, done, dst_port);
          learning_state_t <= IDLE_;
          dst_port <= 3'b110; // default value : INVALID
          done <= 0;
        end
      endcase
    end
  end

  // 1hz counter combined with a over dimensioned five minutes counter
  always_ff @(posedge clk)
  begin
    if (rst)
    begin
      one_hz_counter <= 0;
      five_minute_counter <= INIT_COUNT;
    end
    else if (one_hz_counter == COUNT_THRES)
    begin
      five_minute_counter <= five_minute_counter + 1;
      one_hz_counter <= 0;
    end
    else
    begin
		one_hz_counter <= one_hz_counter + 27'd1;
    end
  end

endmodule
