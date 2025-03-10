`timescale 1ns / 1ps

module binary_to_gray #(parameter DATA_WIDTH = 8) (
    input logic [DATA_WIDTH-1:0] binary,
    output logic [DATA_WIDTH-1:0] gray
);
    always_comb begin
        gray[DATA_WIDTH-1] = binary[DATA_WIDTH-1];
        for (int i = DATA_WIDTH-2; i >= 0; i--) begin
            gray[i] = binary[i+1] ^ binary[i];
        end
    end
endmodule
