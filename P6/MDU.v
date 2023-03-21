`timescale 1ns / 1ps

`include "const.v"

module MDU(
	input clk,
	input reset,
    input [31:0] rs_data,
    input [31:0] rt_data,
    input [3:0] MDU_type,
	output ALMD_sel,
    output MDUbusy,
    output [31:0] MDUout
);
	integer cycle = 0;
	reg busy;
    reg [31:0] hi, lo, hi_tmp, lo_tmp;

	wire start = (MDU_type==`MDU_mult) | (MDU_type==`MDU_multu) | 
				 (MDU_type==`MDU_div)  | (MDU_type==`MDU_divu)  ;
				 //mult | multu | div | divu

	assign MDUbusy = start | busy;

	assign MDUout = (MDU_type==`MDU_mflo) ? lo :
		   			(MDU_type==`MDU_mfhi) ? hi :
		   							 	    0  ;

  	always @(posedge clk) begin
		if(reset)begin
			hi <= 0;
			lo <= 0;
			busy <= 0;
			cycle <= 0;
		end

		else if(cycle==0) begin
			 
			case (MDU_type)
			`MDU_mthi : hi <= rs_data;
			`MDU_mtlo : lo <= rs_data;
			`MDU_mult : begin
				cycle <= 5;
				busy <= 1;
				{hi_tmp,lo_tmp} <= $signed(rs_data) * $signed(rt_data);
			end
			`MDU_multu: begin
				cycle <= 5;
				busy <= 1;
				{hi_tmp,lo_tmp} <= rs_data * rt_data;
			end
			`MDU_div  : begin
				cycle <= 10;
				busy <= 1;
				lo_tmp <= $signed(rs_data) / $signed(rt_data);
            	hi_tmp <= $signed(rs_data) % $signed(rt_data);
			end
			`MDU_divu : begin
				cycle <= 10;
				busy <= 1;
				lo_tmp <= rs_data / rt_data;
            	hi_tmp <= rs_data % rt_data;
			end
    		endcase

		end else if (cycle==1)begin
				busy <= 0;
				cycle <= 0;
				hi <= hi_tmp;
				lo <= lo_tmp;
		end else cycle = cycle - 1;
    	
  	end

	assign ALMD_sel = ((MDU_type==`MDU_mflo)||(MDU_type==`MDU_mfhi)) ? 
											`ALMD_MDU :																   
											`ALMD_ALU ;



endmodule