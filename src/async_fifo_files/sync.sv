`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2025 03:46:32 PM
// Design Name: 
// Module Name: sync
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sync #(
    parameter ADDR_WIDTH = 6
)(
    input reset,
    input clk_dst,
    input clk_src,
    input [ADDR_WIDTH:0] ptr_in,
    output[ADDR_WIDTH:0] ptr_out
    );
    
    logic [ADDR_WIDTH-1:0] reg_clk_dst;
    logic [ADDR_WIDTH-1:0] reg_clk_pre_dst;
    logic [ADDR_WIDTH-1:0] reg_clk_src;
    
    logic [ADDR_WIDTH-1:0] binary_to_graycode;
    logic [ADDR_WIDTH-1:0] graycode_to_binary;
    
    
    assign binary_to_graycode[ADDR_WIDTH-1] = ptr_in[ADDR_WIDTH-1]; // MSB
    genvar i;
    generate
        for(i = ADDR_WIDTH-2; i >= 0; i--) begin : gen_var_i
           assign binary_to_graycode[i] = ptr_in[i+1] ^ ptr_in[i];
        end
    endgenerate
    
    assign graycode_to_binary[ADDR_WIDTH-1] = reg_clk_dst[ADDR_WIDTH-1]; // MSB
    genvar j;
    generate
        for (j = ADDR_WIDTH-2; j >= 0; j--) begin : gen_var_j
           assign graycode_to_binary[j] = graycode_to_binary[j+1] ^ reg_clk_dst[j];
        end
    endgenerate
    
    
    always_ff @(posedge clk_dst) begin
        if (reset) begin
            reg_clk_pre_dst <= 0;
            reg_clk_dst <= 0;
        end else begin
            reg_clk_pre_dst <= reg_clk_src;
            reg_clk_dst <= reg_clk_pre_dst;
        end
    end
    
    always_ff @(posedge clk_src) begin
        if (reset)
            reg_clk_src <= 0;
        else  
            reg_clk_src <= binary_to_graycode;
    end
    
    assign ptr_out = graycode_to_binary;
    
    
endmodule