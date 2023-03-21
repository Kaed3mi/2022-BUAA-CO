`timescale 1ns / 1ps
`include "const.v"
module CU(
    input [31:0] instr,

    output [4:0] rs,
    output [4:0] rt,
    output [4:0] rd,
    output [15:0] imm,
    output [25:0] addr,

    output load,
    output store,
    output r_cal,
    output i_cal,
    output branch,
    output jump,
    output j_r,
    
    output IMM_EXT_TYPE,
    output MemtoReg,
    output MemWrite,
    output [31:0] ALUControl,
    output [2:0] ALUSrcA,     
    output [2:0] ALUSrcB,
    output [1:0] RF_write_data_sel,
    output [4:0] RF_write_addr,
    output [1:0] mem_len_type, 
    output RegWrite
    );
    wire [5:0] opcode = instr[31:26],
               func = instr[5:0];
    assign rs = instr[25:21],
           rt = instr[20:16],
           rd = instr[15:11],
           imm = instr[15:0],
           addr = instr[25:0];
    // Load
    wire lb    = (opcode == `OP_lb   );
    wire lbu   = (opcode == `OP_lbu  );
    wire lh    = (opcode == `OP_lh   );
    wire lhu   = (opcode == `OP_lhu  );
    wire lw    = (opcode == `OP_lw   );
    // Store
    wire sb    = (opcode == `OP_sb   );
    wire sh    = (opcode == `OP_sh   );
    wire sw    = (opcode == `OP_sw   );
    // R-R-cal
    wire add   = (r_cal && func == `FUNC_add  );
    wire addu  = (r_cal && func == `FUNC_addu );
    wire sub   = (r_cal && func == `FUNC_sub  );
    wire subu  = (r_cal && func == `FUNC_subu );
    wire mult  = (r_cal && func == `FUNC_mult );
    wire multu = (r_cal && func == `FUNC_multu);
    wire div   = (r_cal && func == `FUNC_div  );
    wire divu  = (r_cal && func == `FUNC_divu );
    wire slt   = (r_cal && func == `FUNC_slt  );
    wire sltu  = (r_cal && func == `FUNC_sltu );
    wire sll   = (r_cal && func == `FUNC_sll  );
    wire srl   = (r_cal && func == `FUNC_srl  );
    wire sra   = (r_cal && func == `FUNC_sra  );
    wire sllv  = (r_cal && func == `FUNC_sllv );
    wire srlv  = (r_cal && func == `FUNC_srlv );
    wire srav  = (r_cal && func == `FUNC_srav );
    wire And   = (r_cal && func == `FUNC_and  );
    wire Or    = (r_cal && func == `FUNC_or   );
    wire Xor   = (r_cal && func == `FUNC_xor  );
    wire Nor   = (r_cal && func == `FUNC_nor  );
    // R-I-cal
    wire addi  = (opcode == `OP_addi );
    wire addiu = (opcode == `OP_addiu);
    wire andi  = (opcode == `OP_andi );
    wire ori   = (opcode == `OP_ori  );
    wire xori  = (opcode == `OP_xori );
    wire lui   = (opcode == `OP_lui  );
    wire slti  = (opcode == `OP_slti );
    wire sltiu = (opcode == `OP_sltiu);
    // Branch
    wire beq   = (opcode == `OP_beq  );
    wire bne   = (opcode == `OP_bne  );
    wire blez  = (opcode == `OP_blez );
    wire bgtz  = (opcode == `OP_bgtz );
    wire bltz  = (opcode == `OP_bltz && rt == `RT_bltz);
    wire bgez  = (opcode == `OP_bgez && rt == `RT_bgez);
    // Jump
    wire j     = (opcode == `OP_j    );
    wire jal   = (opcode == `OP_jal  );
    wire jalr  = (r_cal && func == `FUNC_jalr );
    wire jr    = (r_cal && func == `FUNC_jr   );

    assign ALUControl = (sub | subu)   ? `ALU_sub  :
                        (And | andi)   ? `ALU_and  :
                        (Or | ori)     ? `ALU_or   :
                        (Xor | xori)   ? `ALU_xor  :
                        (Nor)          ? `ALU_nor  :
                        (sll | sllv)   ? `ALU_sll  :
                        (srl | srlv)   ? `ALU_srl  :
                        (sra | srav)   ? `ALU_sra  :
                        (slt | slti)   ? `ALU_slt  :
                        (sltu | sltiu) ? `ALU_sltu :
                        (lui)          ? `ALU_lui  :
                                         `ALU_add;
    
    assign load   = lw | lh | lhu | lbu | lb;
    assign store  = sw | sh | sb;
    assign r_cal = (opcode==`OP_rtype);
    assign i_cal = addi | addiu | andi | ori| xori | lui | slti | sltiu;
    assign j_r = jalr | jr;

    assign MemtoReg = load;
    assign MemWrite = store;
    assign RegWrite = load | r_cal | i_cal | jal | jalr;

    assign RF_write_data_sel = (jal|jalr) ? 2 :
                               (load)     ? 1 : 
                                            0 ; 
    // 0->ALUResult; 1->MEMRD; 2->PC+4      

    assign ALUSrcB = i_cal | load | store;
    assign IMM_EXT_TYPE = (lui | ori) ? 0 : 1;

    assign RF_write_addr = (r_cal|jalr) ? rd : 
                           (jal) ? 31 :
                           (i_cal|load) ? rt :
                           0;

    assign mem_len_type = (lw | sw) ? 0 :
                          (lh | sh) ? 1 :
                          (lb | sb) ? 2 :
                          0;
    // 0->word; 1->half word; 2->byte
endmodule