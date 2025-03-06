module fifo_read #(
    parameter BIT_SIZE = 10,
    parameter FIFO_SIZE = 10
)
(
    output reg [BIT_SIZE-1:0] raddr,
    output reg ren,
    output reg [BIT_SIZE:0] fifo_occu_out,
    output reg empty,
    output reg [BIT_SIZE-1+1:0] rptr = 0,
    
    input rclk,
    input reset,
    input read_enable,
    input [BIT_SIZE-1+1:0] wptr
);


logic [BIT_SIZE:0] occupance = 0;
wire empty_fifo = (rptr[BIT_SIZE] == wptr[BIT_SIZE]) && (rptr[BIT_SIZE-1:0] == wptr[BIT_SIZE-1:0]);

always_comb begin
    raddr = rptr [BIT_SIZE-1:0];
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