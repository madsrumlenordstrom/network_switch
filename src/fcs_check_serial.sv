`timescale 1ns / 1ps

module fcs_check_serial (
    input logic clk,
    input logic reset,
    input logic start_of_frame, // Arrival of first bit in frame
    input logic end_of_frame,   // Arrival of first bit in FCS
    input logic data_in,        // Bits transmittedj
    output logic fcs_error      // Indicates an error
);

    logic [31:0] fcs_reg;
    logic [31:0] complement_counter;
    logic fcs_done;
    logic data;

    always_comb begin
        if ((complement_counter < 31) || start_of_frame || end_of_frame) begin
            data = ~data_in;
        end else begin
            data = data_in;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            fcs_reg <= 0;
            complement_counter <= 0;
            fcs_done <= 0;
            fcs_error <= 1;
        end else begin
            if (start_of_frame || end_of_frame) begin
                complement_counter <= 0;
            end else if (complement_counter < 31) begin
                complement_counter <= complement_counter + 1;
            end

            if (end_of_frame) begin
                fcs_done <= 1;
            end

            fcs_reg[0] <= data ^ fcs_reg[31];
            fcs_reg[1] <= fcs_reg[0] ^ fcs_reg[31];
            fcs_reg[2] <= fcs_reg[1] ^ fcs_reg[31];
            fcs_reg[3] <= fcs_reg[2];
            fcs_reg[4] <= fcs_reg[3] ^ fcs_reg[31];
            fcs_reg[5] <= fcs_reg[4] ^ fcs_reg[31];
            fcs_reg[6] <= fcs_reg[5];
            fcs_reg[7] <= fcs_reg[6] ^ fcs_reg[31];
            fcs_reg[8] <= fcs_reg[7] ^ fcs_reg[31];
            fcs_reg[9] <= fcs_reg[8];
            fcs_reg[10] <= fcs_reg[9] ^ fcs_reg[31];
            fcs_reg[11] <= fcs_reg[10] ^ fcs_reg[31];
            fcs_reg[12] <= fcs_reg[11] ^ fcs_reg[31];
            fcs_reg[13] <= fcs_reg[12];
            fcs_reg[14] <= fcs_reg[13];
            fcs_reg[15] <= fcs_reg[14];
            fcs_reg[16] <= fcs_reg[15] ^ fcs_reg[31];
            fcs_reg[17] <= fcs_reg[16];
            fcs_reg[18] <= fcs_reg[17];
            fcs_reg[19] <= fcs_reg[18];
            fcs_reg[20] <= fcs_reg[19];
            fcs_reg[21] <= fcs_reg[20];
            fcs_reg[22] <= fcs_reg[21] ^ fcs_reg[31];
            fcs_reg[23] <= fcs_reg[22] ^ fcs_reg[31];
            fcs_reg[24] <= fcs_reg[23];
            fcs_reg[25] <= fcs_reg[24];
            fcs_reg[26] <= fcs_reg[25] ^ fcs_reg[31];
            fcs_reg[27] <= fcs_reg[26];
            fcs_reg[28] <= fcs_reg[27];
            fcs_reg[29] <= fcs_reg[28];
            fcs_reg[30] <= fcs_reg[29];
            fcs_reg[31] <= fcs_reg[30];

            if (fcs_reg == 32'b0 && fcs_done) begin
                fcs_error <= 1'b0;
            end
        end
    end
endmodule
