`timescale 1ns / 1ps

`include "PC.v"
`include "IM.v"
`include "GRF.v"
`include "ALU.v"
//`include "CU.v"
`include "DM.v"
`include "PIPREG.v"
`include "SU.v"

module mips(
	input clk,
    input reset
    );

    assign RF_write_data_E = (RF_data_sel_E==`RFWD_PC8) ? PC_E + 8    : 
                              0;

    assign RF_write_data_M = (RF_data_sel_M==`RFWD_ALU) ? ALUResult_M :
                             (RF_data_sel_M==`RFWD_PC8) ? PC_M + 8    : 
                              0; //select data from

    assign RF_write_data_W = (RF_data_sel_W==`RFWD_ALU) ? ALUResult_W :
                             (RF_data_sel_W==`RFWD_MEM) ? DM_out_W    : 
                             (RF_data_sel_W==`RFWD_PC8) ? PC_W + 8    :
                              0; //select data from

    SU su(
	    .instr_D(instr_D),
        .instr_E(instr_E),
        .instr_M(instr_M),
        .stall(stall)
    );

    wire en = 1;
    wire [31:0] offset;
    wire [31:0] PC_F, PC_D, PC_E, PC_M, PC_W;
    wire [31:0] instr_F, instr_D, instr_E, instr_M, instr_W;
    wire [4:0] rs_D, rs_E, rt_D, rt_E, rt_M, rd_D;
    wire [4:0] RF_write_addr_M, RF_write_addr_W;
    wire [31:0] RF_write_data_M, RF_write_data_W;

    PC pc(
        .clk(clk),
        .rst(reset),
        .stall(stall),
        .branch(branch),
        .offset(offset),
        .jump(jump),
        .jump_addr(jump_addr),
        .npc(PC_F)
    );

    // ext for offset
    assign offset = (instr_D[15]==0) ? {14'h0000,instr_D[15:0],2'b0} : 
                                       {14'h3fff,instr_D[15:0],2'b0} ;

    IM im(
        .addr(PC_F),
        .data(instr_F)
    );

    //      Instruction Fetch
    IF2ID if2id(
        .clk(clk),
        .reset(reset | (~stall & clear_delay)),
        .en(~stall),
        .instr_F(instr_F),
        .instr_D(instr_D),
        .pc_in(PC_F),
        .pc_out(PC_D)
    );
    //      Decode
    wire [31:0] rs_data_D, rt_data_D, IMM_D;
    wire IMM_EXT_TYPE; // 0->zero extend; 1->signed extend
    wire [1:0] RF_data_sel_D, GRFWAddrSelect;

    IMM_EXT imm_ext(
        .in(instr_D[15:0]),
        .type(IMM_EXT_TYPE),
        .out(IMM_D)
    );

    wire [31:0] RS_FWD_D =  (rs_D==0) ? 0 : 
                            (rs_D==RF_write_addr_E) ? RF_write_data_E : 
                            (rs_D==RF_write_addr_M) ? RF_write_data_M : 
                            (rs_D==RF_write_addr_W) ? RF_write_data_W : 
                            rs_data_D;

    wire [31:0] RT_FWD_D =  (rt_D==0) ? 0 : 
                            (rt_D==RF_write_addr_E) ? RF_write_data_E : 
                            (rt_D==RF_write_addr_M) ? RF_write_data_M : 
                            (rt_D==RF_write_addr_W) ? RF_write_data_W : 
                            rt_data_D;

    wire [31:0] jump_addr;
    
    CU cu_D(
        .instr(instr_D),
        
        .a(RS_FWD_D),
        .b(RT_FWD_D),

        .rs(rs_D),
        .rt(rt_D),
        .rd(rd_D),
        .IMM_EXT_TYPE(IMM_EXT_TYPE),
        .MemtoReg(MemtoReg_D),
        .MemWrite(MemWrite_D),
        .RF_data_sel(RF_data_sel_D),
        .RegWrite(RegWrite_D),

        .bgezal_en_out(bgezal_D),
        .bgezal_en_in(bgezal_D),
        .clear_delay(clear_delay),

        .branch(branch),
        .jump(jump),
        .jump_addr(jump_addr)
    );
    
    GRF grf(
        .clk(clk),
        .rst(reset),
	    .WE(RegWrite_W),
        .aAddr(rs_D),
        .bAddr(rt_D),
	    .wAddr(RF_write_addr_W),
        .WD(RF_write_data_W),
        .PC(PC_W),
        .a(rs_data_D),
        .b(rt_data_D)
    );


    //      Decode
    ID2EX id2ex(
        .clk(clk),
        .reset(reset | stall),
        .en(en),

        .regRD1_in(RS_FWD_D),// RS_FWD_D
        .regRD2_in(RT_FWD_D),// RT_FWD_D
        .imm_in(IMM_D),

        .regRD1_out(rs_data_E),
        .regRD2_out(rt_data_E),
        .imm_out(IMM_E),

        .instr_in(instr_D),
        .instr_out(instr_E),

        .pc_in(PC_D),
        .pc_out(PC_E),
        .bgezal_en_in(bgezal_D),
        .bgezal_en_out(bgezal_E)
    );
    //      Execute
    wire [31:0] rs_data_E, rt_data_E, IMM_E, ALUResult_E, ALUControl_E;

    wire [31:0] ALU_A, ALU_B;
    wire [2:0] ALUSrcA, ALUSrcB;

    wire [31:0] RS_FWD_E =  (rs_E==0) ? 0 : 
                            (rs_E==RF_write_addr_M) ? RF_write_data_M : 
                            (rs_E==RF_write_addr_W) ? RF_write_data_W : 
                            rs_data_E;

    wire [31:0] RT_FWD_E =  (rt_E==0) ? 0 : 
                            (rt_E==RF_write_addr_M) ? RF_write_data_M : 
                            (rt_E==RF_write_addr_W) ? RF_write_data_W : 
                            rt_data_E;


    assign ALU_A = (ALUSrcA==0) ? RS_FWD_E : 0;
    assign ALU_B = (ALUSrcB==0) ? RT_FWD_E : IMM_E;
	wire [4:0] RF_write_addr_E;
    wire [1:0] RF_data_sel_E;
    CU cu_E(
        .instr(instr_E),
        .rs(rs_E),
        .rt(rt_E),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUControl(ALUControl_E),
        .RF_data_sel(RF_data_sel_E),
        .RF_write_addr(RF_write_addr_E),
        .bgezal_en_in(bgezal_E)
    );

    ALU alu(
        .a(ALU_A),
        .b(ALU_B),
        .op(ALUControl_E),
        .out(ALUResult_E)
    );

    //      Execute
    EX2MEM ex2mem(
        .clk(clk),
        .reset(reset),
        .en(en),
        .regRD2_in(RT_FWD_E),
        .ALUout_in(ALUResult_E),

        .regRD2_out(rt_data_M),
        .ALUout_out(ALUResult_M),

        .instr_in(instr_E),
        .instr_out(instr_M),
		.pc_in(PC_E),
        .pc_out(PC_M),
        .bgezal_en_in(bgezal_E),
        .bgezal_en_out(bgezal_M)
    );
    //      Memory
    wire [31:0] ALUResult_M, rt_data_M, DM_out_M;
    wire [1:0] RF_data_sel_M;


    CU cu_M(
        .instr(instr_M),
        .rt(rt_M),
        .MemWrite(MemWrite_M),
        .RF_data_sel(RF_data_sel_M),
        .RF_write_addr(RF_write_addr_M),
        .bgezal_en_in(bgezal_M),
        .lhogez(lhogez_M)
    );


    wire [31:0] MEM_write_data_M = 
                            (rt_M==0) ? 0 :
                            (rt_M==RF_write_addr_W) ? RF_write_data_W :
                            rt_data_M;

    DM dm(
        .clk(clk),
        .rst(reset),
	    .WE(MemWrite_M),
        .addr(ALUResult_M),
        .WD(MEM_write_data_M),
        .PC(PC_M),
        .RD(DM_out_M),
        .lhogez(lhogez_M),
        .lhogez_en_out(lhogez_en_M)
    );
    //      Memory
    MEM2WB mem2wb(
        .clk(clk),
        .reset(reset),
        .en(en),
        .DM_out_in(DM_out_M),
        .ALUout_in(ALUResult_M),
    
        .DM_out_out(DM_out_W),
        .ALUout_out(ALUResult_W),
    
        .instr_in(instr_M),
        .instr_out(instr_W),
		.pc_in(PC_M),
        .pc_out(PC_W),
        .bgezal_en_in(bgezal_M),
        .bgezal_en_out(bgezal_W),
        .lhogez_en_in(lhogez_en_M),
        .lhogez_en_out(lhogez_en_W)
    );
    //      Write Back
    wire [31:0] DM_out_W, ALUResult_W;
    wire [1:0] RF_data_sel_W;

    CU cu_W(
        .instr(instr_W),
        .RF_data_sel(RF_data_sel_W),
        .RF_write_addr(RF_write_addr_W),
        .RegWrite(RegWrite_W),
        .bgezal_en_in(bgezal_W),
        .lhogez_en_in(lhogez_en_W),
        .W_check(1'b1)
    );

    //      Write Back


endmodule