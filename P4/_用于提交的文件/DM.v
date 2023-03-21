`timescale 1ns / 1ps

module DM(
    input clk,
    input rst,
	input WE,
    input [13:0] addr,
    input [31:0] WD,
    input [31:0] PC,
    input [1:0] mem_len_type,
    output reg [31:0] RD
    );
    reg [31:0] mem [0:3071];
    integer i;

	wire [31:0] full = mem[addr>>2];
	wire [7:0] WD_0 = WD[7:0], WD_1 = WD[15:7], WD_2 = WD[23:16], WD_3 = WD[31:24];
	wire [7:0] RD_0 = full[7:0], RD_1 = full[15:7], RD_2 = full[23:16], RD_3 = full[31:24];

  	always @(posedge clk) begin
    	if(rst)
        	for(i=0;i<=3071;i=i+1)
            	mem[i] <= 0;
    	else if(WE) begin
        case(mem_len_type)// 0->word; 1->half word; 2->byte
			0:begin
				mem[addr>>2] <= WD;
				$display("@%h: *%h <= %h", PC, {18'b0,addr}, WD);
			end
			1:begin 
				case (addr[1:0])
					0: begin 
						mem[addr>>2] <= {mem[addr>>2][31:16],WD_1,WD_0};
						$display("@%h: *%h <= %h", PC, {18'b0,addr}, {mem[addr>>2][31:16],WD_1,WD_0});
					end
					2: begin 
						mem[addr>>2] <= {WD_3,WD_2,mem[addr>>2][31:16]};
						$display("@%h: *%h <= %h", PC, {18'b0,addr}, {WD_3,WD_2,mem[addr>>2][31:16]});
					end
				endcase
			end
			2:begin
				case (addr[1:0])
					0: begin 
						mem[addr>>2] <= {mem[addr>>2][31:8],WD_0}; 
						$display("@%h: *%h <= %h", PC, {18'b0,addr}, {mem[addr>>2][31:8],WD_0});
						end
					1: begin 
						mem[addr>>2] <= {mem[addr>>2][31:16],WD_1,mem[addr>>2][7:0]}; 
						$display("@%h: *%h <= %h", PC, {18'b0,addr}, {mem[addr>>2][31:16],WD_1,mem[addr>>2][7:0]});
						end
					2: begin 
						mem[addr>>2] <= {mem[addr>>2][31:24],WD_2,mem[addr>>2][15:0]}; 
						$display("@%h: *%h <= %h", PC, {18'b0,addr}, {mem[addr>>2][31:24],WD_2,mem[addr>>2][15:0]});
						end
					3: begin 
						mem[addr>>2] <= {WD_3,mem[addr>>2][23:0]}; 
						$display("@%h: *%h <= %h", PC, {18'b0,addr}, {WD_3,mem[addr>>2][23:0]});
						end
				endcase
			end
		endcase
    	end
  	end

	function [31:0] half_signed_ext;
		input [15:0] in;
		half_signed_ext = (in[15]) ? {16'hffff,in} :
								{16'h0000,in} ;
	endfunction

	function [31:0] byte_signed_ext;
		input [7:0] in;
		byte_signed_ext = (in[7]) ? {24'hffffff,in} :
								    {24'h000000,in} ;
	endfunction

	always @(*) begin
		case(mem_len_type)
		0:begin
			RD = full;
		end
		1:begin
			case(addr[1:0]) 
				0: RD = half_signed_ext(full[15:0]);
				2: RD = half_signed_ext(full[31:16]);
			endcase
		end
		2:begin
			case(addr[1:0]) 
				0: RD = byte_signed_ext(full[7:0]);
				1: RD = byte_signed_ext(full[15:8]);
				2: RD = byte_signed_ext(full[23:16]);
				3: RD = byte_signed_ext(full[31:24]);
			endcase
		end
	endcase
	end


endmodule
        // mem[addr>>2] <= WD;
        // $display("@%h: *%h <= %h", PC, {18'b0,addr,2'b0}, WD);