module fifo_write #(
    parameter BIT_SIZE = 10,
    parameter FIFO_SIZE = 10
)
(
    output reg [BIT_SIZE-1:0] waddr,
    output reg wen,
    output reg [BIT_SIZE:0] fifo_occu_in,
    output reg full,
    output reg [BIT_SIZE-1+1:0] wptr = 0,
    
    input wclk,
    input reset,
    input write_enable,
    input [BIT_SIZE-1+1:0] rptr
);


logic [BIT_SIZE:0] occupance = 0;
wire full_fifo = (rptr[BIT_SIZE] != wptr[BIT_SIZE]) && (rptr[BIT_SIZE-1:0] == wptr[BIT_SIZE-1:0]);

always_comb begin
    waddr = wptr [BIT_SIZE-1:0];
end

always @(posedge wclk) begin
    if (reset) begin
        wptr <= 0;
        wen <= 0;
    end else begin
        if (!full_fifo && write_enable) begin
            wptr <= wptr + 1;
            wen <= 1;
        end else 
            wen <= 0;
        full <= full_fifo;
    end
end

always @(posedge wclk) begin
    fifo_occu_in <= wptr - rptr;
end



endmodule