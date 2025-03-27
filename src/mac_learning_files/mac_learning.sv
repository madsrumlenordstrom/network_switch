`timescale 1ns / 1ps


module dual_port_bram #(
    parameter int HASH_WIDTH = 32,
    parameter int BRAM_WIDTH = 10,
    parameter int DATA_WIDTH = 4
)(clk,wen,ren,addra,addrb,dia,dob);

    input clk,wen,ren;
    input [HASH_WIDTH-1:0] addra,addrb;
    input [DATA_WIDTH-1:0] dia;
    output [DATA_WIDTH-1:0] dob;
    
    localparam TABLE_SIZE = 2 ** BRAM_WIDTH;
    reg [DATA_WIDTH-1:0] ram [TABLE_SIZE-1:0] = '{default: '0};
    reg [DATA_WIDTH-1:0] dob;
    
    // internal debug wires for simulation only
    wire [BRAM_WIDTH-1:0] effective_indexa = addra % TABLE_SIZE;
    wire [BRAM_WIDTH-1:0] effective_indexb = addrb % TABLE_SIZE;
    
    
    always @(posedge clk) begin
    if (wen)
        ram[effective_indexa] <= dia;
    end
    
    always @(posedge clk) begin
    if (ren)
        dob <= ram[effective_indexb];
    end
    
endmodule



module mac_learning#(
    parameter int BRAM_START_INDEX = 0,
    parameter int INIT_COUNT = 0,
    parameter int COUNT_THRES = 124999999,
    parameter int HASH_WIDTH = 32, 
    parameter TIMER_SIZE = 30, // bits allocated to timeout timer
    parameter bit [HASH_WIDTH-1:0] FNV_PRIME  = (HASH_WIDTH == 32) ? 32'h01000193         : 64'h00000100000001B3,
    parameter bit [HASH_WIDTH-1:0] FNV_OFFSET = (HASH_WIDTH == 32) ? 32'h811c9dc5         : 64'hCBF29CE484222325
)(
    input clk,
    input rst,
    input en,
    input [8*6-1:0] src_mac,
    input [8*6-1:0] dst_mac, 
    input [2:0] src_port,
    output reg done,
    output reg [2:0] dst_port
);

    logic [35:0] info_in;
    wire  [35:0] info_out;
    
    
    logic [HASH_WIDTH-1:0] src_hash, dst_hash; 
    
    // implementing sweeping with two parallel FSM controlled by the sweep_mode, that is determined by the mac_learning en
    logic sweep_mode, bram_wen, sweep_wen, sweep_ren, learning_wen, learning_ren;
    logic [31:0] bram_addra, sweep_addr, learning_addra, bram_addrb, learning_addrb;
    logic [35:0] sweep_din = 0, learning_din, bram_din; 
    
    assign bram_addra = sweep_mode ? sweep_addr   : learning_addra;
    assign bram_addrb = sweep_mode ? sweep_addr   : learning_addrb;
    assign bram_din  = sweep_mode ? sweep_din    : learning_din;
    assign bram_wen  = sweep_mode ? sweep_wen    : learning_wen;
    assign bram_ren  = sweep_mode ? sweep_ren    : learning_ren;

    
    logic [26:0] one_hz_counter;
    logic [31:0] five_minute_counter; 
    
    logic remove_flag = 1'b0;
    logic en_d;
    
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
    
    
    logic [31:0] hash_accum;
    
    always_comb begin
        hash_accum = FNV_OFFSET;
        for (int i = 5; i >= 0; i--) begin
            hash_accum = ((hash_accum ^ src_mac[i*8 +: 8]) * FNV_PRIME) & 32'hFFFFFFFF;
        end
        new_src_hash = hash_accum;
    
    
        hash_accum = FNV_OFFSET;
        for (int i = 5; i >= 0; i--) begin
            hash_accum = ((hash_accum ^ dst_mac[i*8 +: 8]) * FNV_PRIME) & 32'hFFFFFFFF;
        end
        new_dst_hash = hash_accum;
    end
    
   
    
    
    enum logic [1:0] {IDLE, READ, CHECK, CLEAR} sweep_state_t;
    logic [35:0] sweep_data;

    always_ff @(posedge clk) begin
      if (rst) begin
        sweep_state_t <= IDLE;
        sweep_addr <= BRAM_START_INDEX;
        sweep_din <= 0;
      end
      else if (sweep_mode) begin
        case (sweep_state_t)
          IDLE: begin
            sweep_state_t <= READ;
          end
    
          READ: begin
            sweep_state_t <= CHECK;
          end
    
          CHECK: begin
            sweep_data <= info_out;
            assert( info_out[35:4] < five_minute_counter ) else begin // CHANGE BACK
                $error("Does not detect time violation!");
            end
            if ( info_out[35:4] < five_minute_counter ) begin
              sweep_state_t <= CLEAR;
            end else begin
              sweep_addr <= sweep_addr + 1;
              sweep_state_t <= READ;
            end
          end
    
          CLEAR: begin
            sweep_addr <= sweep_addr + 1;
            sweep_state_t <= READ;
          end
        endcase
      end
    end

    always_comb begin
        sweep_ren = (sweep_state_t == READ);
        sweep_wen = ((sweep_state_t == CHECK) && (info_out[35:4] < five_minute_counter)); // CHANGE BACK
        learning_ren = (learning_state_t == LOOKUP);
        learning_wen = (learning_state_t == LEARN);
    end
    
    enum logic [1:0] {IDLE_, LOOKUP, FORWARD, LEARN} learning_state_t;
    
    
 
    
    always_ff @(posedge clk) begin
        if (rst) begin
            learning_state_t <= IDLE_;
            dst_port <= 3'b000;
            done <= 0;
            sweep_mode <= 0;
        end else begin
            case (learning_state_t) 
                IDLE_: begin
                        done <= 0;
                        sweep_mode <= 1;
                    if (en_d) begin
                        learning_state_t <= LOOKUP;
                        sweep_mode <= 0;
                    end
                    learning_addrb <= new_dst_hash;
                    learning_addra <= new_src_hash;
                end
                LOOKUP: begin
                    learning_state_t <= FORWARD;
                end
                FORWARD: begin
                    assert (info_out[0] == 1'bx || info_out[0] == 1'bz) begin
                        $error("info_out is not defined in state FORWARD");
                    end
                    
                    if (info_out[0]) // if valid
                        dst_port <= info_out[3:1];
                    else
                        dst_port <= 3'b000;
                    learning_din   <= {five_minute_counter, src_port, 1'b1};
                    learning_state_t <= LEARN;
                    
                end
                LEARN: begin
                    learning_state_t <= IDLE_;
                    done <= 1;
                end
            endcase
        end
    end
    
    // 1hz counter combined with a over dimensioned five minutes counter
    always_ff @(posedge clk) begin
      if (rst) begin
        one_hz_counter <= 0;
        five_minute_counter <= INIT_COUNT;
      end
      else if (one_hz_counter == COUNT_THRES) begin
        five_minute_counter <= five_minute_counter + 1;  
        one_hz_counter <= 0;
      end
      else begin
        one_hz_counter <= one_hz_counter + 1;
      end
    end
    
    always_ff @(posedge clk) en_d <= en;
    
    
endmodule