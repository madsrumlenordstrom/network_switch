module fifo_write #(
    parameter ADDR_WIDTH = 5
)
(
    output reg [ADDR_WIDTH-1:0] waddr,
    output reg wen,
    output reg [ADDR_WIDTH-1:0] fifo_occu_in,
    output reg full,
    output reg [ADDR_WIDTH:0] wptr,
    
    input wclk,
    input reset,
    input write_enable,
    input [ADDR_WIDTH:0] rptr
);


logic [ADDR_WIDTH-1:0] occupance = 0;
wire full_fifo = (rptr[ADDR_WIDTH] != wptr[ADDR_WIDTH]) && (rptr[ADDR_WIDTH-1:0] == wptr[ADDR_WIDTH-1:0]);

always_comb begin
    waddr = wptr[ADDR_WIDTH-1:0];
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