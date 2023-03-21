`timescale 1ns / 1ps

module GRF(
    input clk,
    input rst,
	  input WE,
    input [4:0] aAddr,
    input [4:0] bAddr,
	  input [4:0] wAddr,
    input [31:0] WD,
    input [31:0] PC,
    output [31:0] a,
    output [31:0] b
    );
	reg [31:0] grf[0:31];
  integer i;
  always @(posedge clk) begin
    if (rst)
        for(i=0;i<=31;i=i+1)
            grf[i] <= 0;
    else if(WE) begin
			if(wAddr!=0) begin
        grf[wAddr] <= WD;
        $display("@%h: $%d <= %h", PC, wAddr, WD);
      end
    end
  end
	assign a = grf[aAddr];
	assign b = grf[bAddr];

endmodule
