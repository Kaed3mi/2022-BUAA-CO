`timescale 1ns / 1ps

`include "const.v"
module ALU(
    input [31:0] a,
    input [31:0] b,
    input [31:0] op,
    output [31:0] out
    );

    wire [31:0] sra_ans = $signed($signed(a) >>> b);
    wire [31:0] slt_ans = $signed(a) < $signed(b) ? 32'b1 : 32'b0;

  assign out =  (op == `ALU_add)  ? a + b    :
                (op == `ALU_sub)  ? a - b    :
                (op == `ALU_and)  ? a & b    : 
                (op == `ALU_or)   ? ras    :
                (op == `ALU_xor)  ? a ^ b    :
                (op == `ALU_nor)  ? ~(a | b) :
                (op == `ALU_sll)  ? a << b   :
                (op == `ALU_srl)  ? a >> b   :
                (op == `ALU_sra)  ? sra_ans  :
                (op == `ALU_slt)  ? slt_ans  :
                (op == `ALU_sltu) ? a < b    :
                (op == `ALU_lui)  ? b << 16  :
                0;
				
	wire [32:0] a_ext = {a[31],a}, b_ext = {b[31],b};
  	wire [32:0] temp = a_ext + b_ext;
  	wire overflow = (temp[32]^temp[31]);


  	reg [31:0] a_n;
  	integer i, num_of_1;
  	always @(*) begin
		for(i=31;i>=0;i=i-1)begin
			if(i>31-b) a_n[i] = ~a[i];
			else a_n[i] = a[i];
		end
		for(i=0;i<32;i=i+1)
			if(i==0) num_of_1 = b[0];
    		else if(b[i]) num_of_1 = num_of_1 + 1;
	end	
	wire [31:0] ras = $signed($signed(a_n) >>> num_of_1);
	
endmodule
