`timescale 1ns / 1ps

`include "const.v"
`include "CU.v"
`include "ALU.v"
`include "PC.v"
`include "IM.v"
`include "GRF.v"
`include "DM.v"
`include "BJU.v"
`include "DASM.v"

module mips(
    input clk,
    input reset
    );
    wire [31:0] PC, instr, rs_data, rt_data, jump_addr;
    wire [4:0]  rs_addr, rt_addr, rd_addr, RF_write_addr;

    wire [31:0] ALUControl;
    wire [2:0] ALUSrcB;

    wire [31:0] imm = (IMM_EXT_TYPE==0) ?   {16'h0000,instr[15:0]} :
                      (instr[15])       ?   {16'hffff,instr[15:0]} : 
                                            {16'h0000,instr[15:0]} ,
                offset = (instr[15]==0) ?   {14'h0000,instr[15:0],2'b0} : 
                                            {14'h3fff,instr[15:0],2'b0} ;

    wire [1:0] RF_write_data_sel, mem_len_type;

    CU cu(
        .instr(instr),
        .rs(rs_addr),
        .rt(rt_addr),
        .rd(rd_addr),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .ALUSrcB(ALUSrcB),
        .RF_write_addr(RF_write_addr),
        .RegWrite(RegWrite),
        .IMM_EXT_TYPE(IMM_EXT_TYPE),
        .RF_write_data_sel(RF_write_data_sel),
        .mem_len_type(mem_len_type)
    );

    PC pc(
        .clk(clk),
        .rst(reset),
        .branch(branch),
        .jump(jump),
        .offset(offset),
        .jump_addr(jump_addr),
        .npc(PC)
    );

    BJU bju(
        .instr(instr),
        .a(rs_data),
        .b(rt_data),
        .branch(branch),
        .jump(jump),
        .jump_addr(jump_addr)
    );

    IM im(
        .addr(PC[13:2]),
        .data(instr)
    );

    wire [31:0] RF_write_data = (RF_write_data_sel==2) ? PC + 4     :
                                (RF_write_data_sel==1) ? MEMRD      :
                                                         ALU_Result ;
    
    GRF grf(
        .clk(clk),
        .rst(reset),
	    .WE(RegWrite),
        .aAddr(rs_addr),
        .bAddr(rt_addr),
	    .wAddr(RF_write_addr),
        .WD(RF_write_data),
        .PC(PC),
        .a(rs_data),
        .b(rt_data)
    );

    wire [31:0] ALU_A = rs_data,
                ALU_B = (ALUSrcB) ?     imm:  //{16'h0000,instr[15:0]}
                                    rt_data;

    wire [31:0] ALU_Result;

    ALU alu(
        .a(ALU_A),
        .b(ALU_B),
        .op(ALUControl),
        .out(ALU_Result)
    );
    
    wire [31:0] MEMRD;

    DM dm(
        .clk(clk),
        .rst(reset),
	    .WE(MemWrite),
        .addr(ALU_Result[13:0]),
        .WD(rt_data),
        .PC(PC),
        .RD(MEMRD),
        .mem_len_type(mem_len_type)
    );

    wire [255:0] asm;

    DASM dasm(
        .pc(PC),
        .instr(instr),
        .imm_as_dec(1'b1),
        .reg_name(1'b0),
        .asm(asm)
    );

endmodule