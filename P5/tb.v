`timescale 1ns / 1ps

`include "mips.v"
module tb;

	// Inputs
	reg clk;
	reg reset;

	// Instantiate the Unit Under Test (UUT)
	mips UUT (
		.clk(clk), 
		.reset(reset)
	);
	
	always #5 clk = ~clk;
	initial begin
		$dumpfile("wave.vcd");
		$dumpvars;


		clk = 0;
		reset = 1;
		#10
		reset = 0;


		#1000;
		$finish;
	end
	
endmodule
