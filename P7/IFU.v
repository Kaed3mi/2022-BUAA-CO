`timescale 1ns / 1ps

`define PCMIN 32'h0000_3000
`define PCMAX 32'h0000_6ffc

`include "const.v"
module IFU(
	input req,
	output EXC_AdEL,
	input eret,
	input [31:0] EPC,

    input clk,
    input rst,
    input branch,
    input jump,
    input stall,
    input [31:0] offset,
    input [31:0] jump_addr,
    output [31:0] pc
    );

	assign pc = (eret) ? EPC : npc;
	reg [31:0] npc;

  	always @(posedge clk) begin
    	if (rst) npc <= 32'h3000;
      	else begin
			if(req)				npc <= 32'h4180;
			else if(eret)		npc <= EPC+4;
        	else if(stall)  	npc <= npc;
        	else if(branch) 	npc <= npc + offset;
        	else if(jump)   	npc <= jump_addr;
        	else            	npc <= npc + 4;
        end
  	end

	assign EXC_AdEL = (|pc[1:0]) | (pc>`PCMAX) | (pc<`PCMIN);


endmodule