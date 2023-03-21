`timescale 1ns / 1ps

`include "const.v"
`include "MulDivUnit.v"

module MDU(
	input req,

	input clk,
	input reset,
    input [31:0] rs_data,
    input [31:0] rt_data,
    input [3:0] MDU_type,
	output ALMD_sel,
    output MDUbusy,
    output [31:0] MDUout
);
    reg [31:0] hi, lo;

	wire start = (MDU_type==`MDU_mult) | (MDU_type==`MDU_multu) | 
				 (MDU_type==`MDU_div)  | (MDU_type==`MDU_divu)  ;
				 //mult | multu | div | divu

	wire busy = !in_ready;
	assign MDUbusy = start | busy;

	assign MDUout = (MDU_type==`MDU_mflo) ? lo :
		   			(MDU_type==`MDU_mfhi) ? hi :
		   							 	    0  ;
//////////////////////////////////////////////////////////////////////////////////

	wire [1:0] in_op = (MDU_type==`MDU_mult|MDU_type==`MDU_multu) ? 2'b01:
					   (MDU_type==`MDU_div|MDU_type==`MDU_divu)	  ? 2'b10:
					   0;
	wire in_sign = (MDU_type==`MDU_mult)|(MDU_type==`MDU_div);
	wire [31:0] out_res0, out_res1;

	wire out_ready = 1;
	MulDivUnit mdu(
    .clk(clk),
    .reset(reset),
    .in_src0(rs_data),
    .in_src1(rt_data),
    .in_op(in_op),
    .in_sign(in_sign),
    .in_ready(in_ready),
    .in_valid(start),
    .out_ready(out_ready),
    .out_valid(out_valid),
    .out_res0(out_res0),
    .out_res1(out_res1)
);

	always @(posedge clk) begin
		if(out_valid)begin
			lo <= out_res0;
			hi <= out_res1;
		end
	end
///////////////////////////////////////////////////////////////////////////////////

	assign ALMD_sel = ((MDU_type==`MDU_mflo)||(MDU_type==`MDU_mfhi)) ? 
											`ALMD_MDU :																   
											`ALMD_ALU ;


endmodule