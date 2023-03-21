`timescale 1ns / 1ps

`include "const.v"
module DM(
    input clk,
    input rst,
	input WE,
    input [31:0] addr,
    input [31:0] WD,
    input [31:0] PC,
    output [31:0] RD
    );
	
    reg [31:0] mem [0:3071];
    integer i;
  	always @(posedge clk) begin
    	if(rst)
        	for(i=0;i<=3071;i=i+1)
            	mem[i] <= 0;
    	else if(WE) begin
        	mem[(addr>>2)] <= WD;
        	//$display("@%h: *%h <= %h", PC, addr, WD);
        	$display("%d@%h: *%h <= %h", $time, PC, addr, WD);
    	end
  	end

    assign RD = mem[addr>>2];


  
endmodule
