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
                (op == `ALU_or)   ? a | b    :
                (op == `ALU_xor)  ? a ^ b    :
                (op == `ALU_nor)  ? ~(a | b) :
                (op == `ALU_sll)  ? a << b   :
                (op == `ALU_srl)  ? a >> b   :
                (op == `ALU_sra)  ? sra_ans  :
                (op == `ALU_slt)  ? slt_ans  :
                (op == `ALU_sltu) ? a < b    :
                (op == `ALU_lui)  ? b << 16  :
                0;
endmodule
