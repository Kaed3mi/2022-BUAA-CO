`timescale 1ns / 1ps

`include "const.v"
module ALU(
    input ALUOv_Dectect,
    input ALUDMOv_Dectect,

    output ALU_Ov,
    output ALU_DMOv,

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

    wire [32:0] extA = {a[31], a}, extB = {b[31], b};
    wire [32:0] extAdd = extA + extB, extSub = extA - extB;

    assign ALU_Ov = ALUOv_Dectect &&
                    ((extAdd[32]!=extAdd[31]) && (op == `ALU_add) || 
                     (extSub[32]!=extSub[31]) && (op == `ALU_sub));
                    
    assign ALU_DMOv = ALUDMOv_Dectect && (
                    (extAdd[32]!=extAdd[31]) && (op == `ALU_add));

endmodule
