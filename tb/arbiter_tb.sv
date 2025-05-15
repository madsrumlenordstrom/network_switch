`timescale 1ns / 1ps

// ############################################################################
//  Module: arbiter_tb
//  Description: This module implements a simple testbench for the arbiter module.
// ############################################################################

module arbiter_tb;
  localparam integer WIDTH = 3;
  logic [WIDTH-1:0] request;
  logic [WIDTH-1:0] grant;
  logic clk, rst;

  // ############################################################################
  //  Arbiter instance
  // ############################################################################
  arbiter u_arbiter (
    .clk_i(clk),
    .rst_i(rst),
    .request_i(request),
    .grant_o(grant)
  );

  // Clock generator
  always #5 clk = ~clk;

  // Monitor requests and grants
  initial $monitor("Time:%0d  \tRequest: %b\tGrant: %b\t", $time, request, grant);

  // ############################################################################
  //  Test sequence
  // ############################################################################
  initial begin
    $display("######## Test started ########");
    clk = 0;
    rst = 1;
    request  = '0;
    #20 rst = 0;

    // Dump signals to VCD
    $dumpfile("dump.vcd");
    $dumpvars(0, crossbar_tb);

    $display("Inputs on rising edge of clock");
    @(posedge clk) request = 'b111;

    @(posedge clk) request = 'b110;
    @(posedge clk) request = 'b111;

    @(posedge clk) request = 'b101;

    @(posedge clk) request = 'b011;

    @(posedge clk) request = 0;
    $display("Set to 0, and input at various times");

    #1 request = 'b110;
    #1 request = 'b010;
    #1 request = 'b011;
    #1 request = 'b011;
    #1 request = 'b001;
    #4 request = 'b100;
    #2 request = 'b001;
    #100 $display("######## Test complete ########");
    $finish;

  end

  always begin // Assert maximum one grant
    assert ($countones(grant) <= 1) else
    $display("Error: More than one grant signal is high, Grant: %b", grant);
  end

endmodule
