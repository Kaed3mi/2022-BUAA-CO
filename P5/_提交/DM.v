`timescale 1ns / 1ps

`include "const.v"
module DM(
    input clk,
    input rst,
	input WE,
	input lhogez,
	output lhogez_en_out,
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

    assign RD = (lhogez) ? (check>=8) ? sign_ext(half):PC + 4:
				mem[addr>>2];

	assign lhogez_en_out = (check>=8);



	wire [15:0] half = (addr[1:0]==0) ? mem[addr>>2][15:0]  :
										mem[addr>>2][31:15] ;

	wire [31:0] check = num_of_1(half);
	integer k;

	function [31:0] sign_ext;
	input [15:0] in;
		sign_ext = (in[15]) ? {16'hffff,in} : {16'h0000,in};
	endfunction

	function [31:0] num_of_1;
	input [15:0] in;
		for(k=0;k<=15;k=k+1)begin
			if(k==0) num_of_1 = in[0];
			else num_of_1 = num_of_1 + in[k];
		end
	endfunction

endmodule
