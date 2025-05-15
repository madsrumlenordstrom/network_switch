`timescale 1ns / 1ps

module mac_learning_tb;
    // Parameters 
    parameter COUNT_THRES = 2;
    parameter INIT_COUNT = 302; // Past threshold, will be deleted when sweeping reaches index
    parameter BRAM_START_INDEX = 1545;
    parameter TIMER_SIZE = 30; // bits allocated to timeout timer

    reg clk;
    reg rst;
    reg en;
    reg [47:0] src_mac;     
    reg [47:0] dst_mac;
    reg [2:0] src_port;
    wire done;
    wire busy;
    wire [2:0] dst_port;
    wire [2:0] tag_port;
    
    mac_learning #(
        .BRAM_START_INDEX(BRAM_START_INDEX),
        .INIT_COUNT(INIT_COUNT),
        .COUNT_THRES(COUNT_THRES),
        .TIMER_SIZE(TIMER_SIZE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .src_mac(src_mac),
        .dst_mac(dst_mac),
        .src_port(src_port),
        .done(done),
        .busy(busy),
        .dst_port(dst_port),
        .tag_port(tag_port)
    );
    
    always #5 clk = ~clk;
    
    int fd;
    string line;
    int line_num;
    
    initial begin
        clk = 0;
        rst = 1;
        en = 0;
        src_mac = 0;
        dst_mac = 0;
        src_port = 0;
        
        #20 rst = 0;
        
        #10;
        
        @(posedge clk);  
        
        fd = $fopen("./src/mac_learning_files/mac_learning_tb_vec.csv", "r");
        if (fd == 0) begin
            $fatal("Error: Could not open CSV file!");
        end
       
        void'($fgets(line, fd));
        
        line_num = 0;
        
        while ($fgets(line,fd)) begin
            #10 en = 1;
            $sscanf(line, "%d,%h,%h", src_port, dst_mac, src_mac);
            $display("Line %0d: src_port=%d, dst_mac=%h, src_mac=%h", line_num, src_port, dst_mac, src_mac);
            
            
            if ($sscanf(line, "%d,%h,%h", src_port, dst_mac, src_mac) != 3) begin
                $fatal("ERROR: Failed to parse line %0d: %s", line_num, line);
            end
            
            #10 en = 0;
            #100;
            @(posedge clk);    
            line_num++;   
        end
    #10;
    
   $fclose(fd);
   
   #100;
   $finish;
   
   end     
endmodule
