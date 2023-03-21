`timescale 1ns / 1ps
`include "const.v"
module BJU(
    input [31:0] instr,
    input [31:0] a,
    input [31:0] b,
    output branch,
    output jump,
    output [31:0] jump_addr,
    output link,
    output [4:0] link_addr
    );
    
    wire [5:0] opcode = instr[31:26],
               func = instr[5:0];
    wire [4:0] rs = instr[25:21],
               rt = instr[20:16],
               rd = instr[15:11];
    wire [16:0] imm = instr[15:0];
    //B
    wire beq   = (opcode == `OP_beq  );
    wire bne   = (opcode == `OP_bne  );
    wire blez  = (opcode == `OP_blez );
    wire bgtz  = (opcode == `OP_bgtz );
    wire bltz  = (opcode == `OP_bltz && rt == `RT_bltz);
    wire bgez  = (opcode == `OP_bgez && rt == `RT_bgez);
    //J
    wire j     = (opcode == `OP_j    );
    wire jal   = (opcode == `OP_jal  );
    wire jalr  = (opcode == `OP_rtype && func == `FUNC_jalr );
    wire jr    = (opcode == `OP_rtype && func == `FUNC_jr   );

    assign branch = beq  ? a==b :
                    bne  ? a!=b :
                    blez ? a<=b :
                    bgtz ? a>b :
                    bltz ? a<b :
                    bgez ? a>=b :
                    0;

    assign jump = j | jal | jalr | jr;

    assign jump_addr = (j) ?    {4'b0,instr[25:0],2'b0} :
                       (jal) ?  {4'b0,instr[25:0],2'b0} :
                       (jr) ? a :
                       (jalr) ? a :
                       0;

    assign link = (jal | jalr);
    
    assign link_addr = (jal)  ? 31 :
                       (jalr) ? rd :
                       0;

endmodule
