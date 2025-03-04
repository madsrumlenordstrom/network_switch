`timescale 1ns / 1ps

module fcs_check_parallel (
    input logic clk,
    input logic reset,
    input logic start_of_frame, // Arrival of first bit in frame
    input logic end_of_frame,   // Arrival of first bit in FCS
    input logic [7:0] data_in,  // Bytes transmitted
    output logic fcs_error      // Indicates an error
);

    logic [31:0] fcs_reg;
    logic [1:0] complement_counter;
    logic [7:0] data;

    enum int unsigned {idle, complement_start, process_middle, complement_end} state, next_state;

    always_comb begin
        next_state = idle;
        data = data_in;
        fcs_error = 1;
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
                    fcs_error = 0;
                end else begin
                    next_state = idle;
                end
            end
        endcase
    end

    always_ff@(posedge clk or posedge reset) begin
        if(reset) begin
            state <= idle;
        end else begin
            state <= next_state;
            if (start_of_frame || state != idle && next_state != idle) begin
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
            end else begin
                fcs_reg <= 0;
            end

            if (start_of_frame || end_of_frame) begin
                complement_counter <= 0;
            end else if (complement_counter < 3) begin
                complement_counter <= complement_counter + 1;
            end
        end
    end
endmodule
