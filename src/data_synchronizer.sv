`timescale 1ns / 1ps

module data_synchronizer #(parameter DATA_WIDTH = 8) (
    input logic [DATA_WIDTH-1:0] data_in,
    input logic clk_in,
    output logic [DATA_WIDTH-1:0] data_out,
    input logic clk_out
);
    // Input clock domain signals
    logic [DATA_WIDTH-1:0] gray_in;
    logic [DATA_WIDTH-1:0] gray_piped;

    // Output clock domain signals
    logic [DATA_WIDTH-1:0] gray_sync;
    logic [DATA_WIDTH-1:0] gray_out;
    
    binary_to_gray #(
      DATA_WIDTH
    ) binary_to_gray_i (
      .binary(data_in),
      .gray(gray_in)
    );

    gray_to_binary #(
        DATA_WIDTH
    ) gray_to_binary_i (
        .gray(gray_out),
        .binary(data_out)
    );
    
    always_ff @(posedge clk_in) begin
        gray_piped <= gray_in;
    end

    always_ff @(posedge clk_out) begin
        gray_sync <= gray_piped;
        gray_out <= gray_sync;
    end
endmodule
