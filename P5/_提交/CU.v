`timescale 1ns / 1ps

`include "const.v"
module CU(
    input [31:0] instr,
    input [31:0] a,
    input [31:0] b,

    output [4:0] rs,
    output [4:0] rt,
    output [4:0] rd,
    output [15:0] imm,
    output [25:0] addr,

    output load,
    output store,
    output r_cal,
    output i_cal,
    output branch_ins,

    output branch,
    output jump,
    output [31:0] jump_addr,
    output j_r,
    output clear_delay,

    output bgezal,
    input bgezal_en_in,
    output bgezal_en_out,
    
    output lhogez,
    input lhogez_en_in,
    input W_check,

    output IMM_EXT_TYPE,
    output MemtoReg,
    output MemWrite,
    output [31:0] ALUControl,
    output [2:0] ALUSrcA,
    output [2:0] ALUSrcB,
    output [1:0] RF_data_sel,
    output [4:0] RF_write_addr,
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

    assign lhogez = (opcode == 6'b110011);
    // Store
    wire sb    = (opcode == `OP_sb   );
    wire sh    = (opcode == `OP_sh   );
    wire sw    = (opcode == `OP_sw   );
    // R-R-cal
    wire add   = (opcode == `OP_rtype && func == `FUNC_add  );
    wire addu  = (opcode == `OP_rtype && func == `FUNC_addu );
    wire sub   = (opcode == `OP_rtype && func == `FUNC_sub  );
    wire subu  = (opcode == `OP_rtype && func == `FUNC_subu );
    wire mult  = (opcode == `OP_rtype && func == `FUNC_mult );
    wire multu = (opcode == `OP_rtype && func == `FUNC_multu);
    wire div   = (opcode == `OP_rtype && func == `FUNC_div  );
    wire divu  = (opcode == `OP_rtype && func == `FUNC_divu );
    wire slt   = (opcode == `OP_rtype && func == `FUNC_slt  );
    wire sltu  = (opcode == `OP_rtype && func == `FUNC_sltu );
    wire sll   = (opcode == `OP_rtype && func == `FUNC_sll  );
    wire srl   = (opcode == `OP_rtype && func == `FUNC_srl  );
    wire sra   = (opcode == `OP_rtype && func == `FUNC_sra  );
    wire sllv  = (opcode == `OP_rtype && func == `FUNC_sllv );
    wire srlv  = (opcode == `OP_rtype && func == `FUNC_srlv );
    wire srav  = (opcode == `OP_rtype && func == `FUNC_srav );
    wire And   = (opcode == `OP_rtype && func == `FUNC_and  );
    wire Or    = (opcode == `OP_rtype && func == `FUNC_or   );
    wire Xor   = (opcode == `OP_rtype && func == `FUNC_xor  );
    wire Nor   = (opcode == `OP_rtype && func == `FUNC_nor  );
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

    assign bgezal = (opcode == `OP_bgezal && rt == `RT_bgezal);
    // Jump
    wire j     = (opcode == `OP_j    );
    wire jal   = (opcode == `OP_jal  );
    wire jalr  = (opcode == `OP_rtype && func == `FUNC_jalr );
    wire jr    = (opcode == `OP_rtype && func == `FUNC_jr   );
    // Tranfer
    wire mfhi  = (opcode == `OP_rtype && func == `FUNC_mfhi );
    wire mflo  = (opcode == `OP_rtype && func == `FUNC_mflo );
    wire mthi  = (opcode == `OP_rtype && func == `FUNC_mthi );
    wire mtlo  = (opcode == `OP_rtype && func == `FUNC_mtlo );

    assign load   = lw | lh | lhu | lbu | lb | lhogez;
    assign store  = sw | sh | sb;

    assign r_cal  = add | sub | slt | sltu | sll | sllv |
                    srl | srlv | sra | srav | And | Or | 
                    Xor | Nor; //  ~(jr jalr mt mf md)

    assign i_cal = addi | addiu | andi | ori| xori | lui | slti | sltiu;
    assign branch_ins = beq | bne | blez | bgtz | bltz | bgez;
    assign j_r = jalr | jr;


    //D stage
    assign branch = beq  ? a==b :
                    bne  ? a!=b :
                    blez ? $signed(a)<=0 :
                    bgtz ? $signed(a)>0 :
                    bltz ? $signed(a)<0 :
                    bgez ? $signed(a)>=0 :
                    bgezal ? $signed(a)>=0 :
                    0;

    assign bgezal_en_out = bgezal && a>=0; //this signal should be piped

    assign jump = j | jal | jalr | jr;

    assign jump_addr = (j) ?    {4'b0,instr[25:0],2'b0} :
                       (jal) ?  {4'b0,instr[25:0],2'b0} :
                       (jr) ? a :
                       (jalr) ? a :
                       0;

    wire link = (jal | jalr | bgezal_en_in);

    wire [31:0] link_addr = (jal|bgezal_en_in)  ? 31 :
                            (jalr) ? rd :
                             0;

    assign clear_delay = 0;


    // E stage

    assign ALUSrcA = 0;
    assign ALUSrcB = i_cal | load | store;
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

    // M stage

    assign MemtoReg = load;
    assign MemWrite = store;


    // W stage
    assign RegWrite = load | r_cal | i_cal | link;


    assign RF_write_addr = (lhogez&&W_check) ? (lhogez_en_in) ? rt : 31 :
                           (link) ? link_addr :
                           (r_cal) ? rd : 
                           (i_cal|load) ? rt :
                            0;

    assign RF_data_sel = (jal|jalr|bgezal_en_in) ? `RFWD_PC8 :
                         (load)  ?    `RFWD_MEM : 
                                      `RFWD_ALU ;// 0->ALUResult; 1->MEMRD; 2->PC+4
   
    assign IMM_EXT_TYPE = (lui|ori|addi) ? 0 : 1;


endmodule
