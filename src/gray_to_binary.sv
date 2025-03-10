`timescale 1ns / 1ps

module gray_to_binary #(parameter DATA_WIDTH = 8) (
    input logic [DATA_WIDTH-1:0] gray,
    output logic [DATA_WIDTH-1:0] binary
);
    always_comb begin
        binary[DATA_WIDTH-1] = gray[DATA_WIDTH-1];
        for (int i = DATA_WIDTH-2; i >= 0; i--) begin
            binary[i] = gray[i] ^ binary[i+1];
        end
    end
endmodule
