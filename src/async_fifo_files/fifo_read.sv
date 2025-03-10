module fifo_read #(
    parameter ADDR_WIDTH = 5
)
(
    output reg [ADDR_WIDTH-1:0] raddr,
    output reg ren,
    output reg [ADDR_WIDTH-1:0] fifo_occu_out,
    output reg empty,
    output reg [ADDR_WIDTH:0] rptr = 0,
    
    input rclk,
    input reset,
    input read_enable,
    input [ADDR_WIDTH:0] wptr
);


logic [ADDR_WIDTH-1:0] occupance = 0;
wire empty_fifo = (rptr[ADDR_WIDTH] == wptr[ADDR_WIDTH]) && (rptr[ADDR_WIDTH-1:0] == wptr[ADDR_WIDTH-1:0]);

always_comb begin
    raddr = rptr [ADDR_WIDTH-1:0];
end

always @(posedge rclk) begin
    if (reset) begin
        rptr <= 0;
        ren <= 0;
    end else begin
        if (!empty_fifo && read_enable) begin
            rptr <= rptr + 1;
            ren <= 1;
        end else 
            ren <= 0;
        empty <= empty_fifo;
    end
end

always @(posedge rclk) begin
    fifo_occu_out <= wptr - rptr;
end



endmodule