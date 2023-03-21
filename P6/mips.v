`timescale 1ns / 1ps

`include "PC.v"
`include "IM.v"
`include "GRF.v"
`include "ALU.v"
`include "DM.v"
`include "PIPREG.v"
`include "SU.v"
`include "MDU.v"
`include "DASM.v"

module mips(
	input clk,
    input reset,
    input [31:0] i_inst_rdata, // instr got from extern IM
    input [31:0] m_data_rdata, // DM data got from extern DM
    output [31:0] i_inst_addr, // PC
    output [31:0] m_data_addr, // DM_write_addr
    output [31:0] m_data_wdata,
    output [3:0] m_data_byteen,
    output [31:0] m_inst_addr,
    output w_grf_we,
    output [4:0] w_grf_addr,
    output [31:0] w_grf_wdata,
    output [31:0] w_inst_addr,
    output [32*8-1:0] asm_W
    );
	wire en = 1;
    wire [31:0] offset;
    wire [31:0] PC_F, PC_D, PC_E, PC_M, PC_W;
    wire [31:0] instr_F, instr_D, instr_E, instr_M, instr_W;
    wire [4:0] rs_D, rs_E, rt_D, rt_E, rt_M, rd_D;
    wire [4:0] RF_write_addr_M, RF_write_addr_W;
    wire [31:0] RF_write_data_M, RF_write_data_W;
	wire [31:0] ALMDout_M, rt_data_M, DM_out_M;
	wire [31:0] DM_out_W, ALMDout_W;
	wire [3:0] m_rdata_byteen;
	
	
    assign i_inst_addr = PC_F; // PC
    assign m_data_addr = (jap_M==0) ? ALMDout_M : ALMDout_M + 4; // DM_addr from ALU

    assign m_data_wdata = (m_data_byteen==4'b1111) ? DM_write_data_M        : 
                          (m_data_byteen==4'b0011) ? DM_write_data_M        : 
                          (m_data_byteen==4'b1100) ? DM_write_data_M << 16  : 
                          (m_data_byteen==4'b0001) ? DM_write_data_M        : 
                          (m_data_byteen==4'b0010) ? DM_write_data_M << 8   : 
                          (m_data_byteen==4'b0100) ? DM_write_data_M << 16  : 
                          (m_data_byteen==4'b1000) ? DM_write_data_M << 24  : 
                                                     0; //DM_write_data

    function [31:0] half_signed_ext;
    input [15:0] in;
        half_signed_ext = (in[15]) ? {16'hffff,in}:{16'h0000,in};
    endfunction

    function [31:0] byte_signed_ext;
    input [7:0] in;
        byte_signed_ext = (in[7]) ? {24'hffffff,in}:{24'h000000,in};
    endfunction

   assign DM_out_M = (m_rdata_byteen==4'b1111) ? m_data_rdata                           : 
                     (m_rdata_byteen==4'b0011) ? half_signed_ext(m_data_rdata[15:0])    : 
                     (m_rdata_byteen==4'b1100) ? half_signed_ext(m_data_rdata[31:16])   : 
                     (m_rdata_byteen==4'b0001) ? byte_signed_ext(m_data_rdata[7:0])     :  
                     (m_rdata_byteen==4'b0010) ? byte_signed_ext(m_data_rdata[15:8])    : 
                     (m_rdata_byteen==4'b0100) ? byte_signed_ext(m_data_rdata[23:16])   : 
                     (m_rdata_byteen==4'b1000) ? byte_signed_ext(m_data_rdata[31:24])   : 
                                                     0; //DM_write_data




    //assign m_data_byteen = 0;
    assign m_inst_addr = PC_M;
    assign w_grf_we = RegWrite_W;
    assign w_grf_addr = RF_write_addr_W;
    assign w_grf_wdata = RF_write_data_W;
    assign w_inst_addr = PC_W;

    assign instr_F = i_inst_rdata;
    
    

    assign RF_write_data_E = (RF_data_sel_E==`RFWD_PC8) ? PC_E + 8    : 
                              0;

    assign RF_write_data_M = (RF_data_sel_M==`RFWD_ALU) ? ALMDout_M :
                             (RF_data_sel_M==`RFWD_PC8) ? PC_M + 8    : 
                              0; //select data from

    assign RF_write_data_W = (RF_data_sel_W==`RFWD_ALU) ? ALMDout_W :
                             (RF_data_sel_W==`RFWD_MEM) ? DM_out_W    : 
                             (RF_data_sel_W==`RFWD_PC8) ? PC_W + 8    :
                              0; //select data from

    SU su(
	    .instr_D(instr_D),
        .instr_E(instr_E),
        .instr_M(instr_M),
        .busy(busy),
        .stall(stall)
    );
    
    wire [31:0] jump_addr;
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
    wire [2:0] RF_data_sel_D;

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

    
    // BJU bju(
    //     .instr(instr_D),
    //     .a(RS_FWD_D),
    //     .b(RT_FWD_D),
    //     .branch(branch),
    //     .jump(jump),
    //     .jump_addr(jump_addr)
    // );
    

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
	
    wire [31:0] rs_data_E, rt_data_E, IMM_E, ALUResult_E, ALUControl_E;
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


    wire [2:0] ALUSrcA, ALUSrcB;

    wire [31:0] RS_FWD_E =  (rs_E==0) ? 0 : 
                            (rs_E==RF_write_addr_M) ? RF_write_data_M : 
                            (rs_E==RF_write_addr_W) ? RF_write_data_W : 
                            rs_data_E;

    wire [31:0] RT_FWD_E =  (rt_E==0) ? 0 : 
                            (rt_E==RF_write_addr_M) ? RF_write_data_M : 
                            (rt_E==RF_write_addr_W) ? RF_write_data_W : 
                             rt_data_E;


    wire [31:0] ALMD_A = (ALUSrcA==`ALUSrc_rt) ? RT_FWD_E : RS_FWD_E;

    wire [31:0] ALMD_B = (ALUSrcB==`ALUSrc_shamt)  ?  {27'b0, instr_E[10:6]} :
                         (ALUSrcB==`ALUSrc_rs_4_0) ?  {27'b0, RS_FWD_E[4:0]} :
                         (ALUSrcB==`ALUSrc_imm)    ?   IMM_E    : 
                         (ALUSrcB==`ALUSrc_rt)     ?   RT_FWD_E :
                         0;

	wire [4:0] RF_write_addr_E;
    wire [2:0] RF_data_sel_E;
    wire [3:0] MDU_type;
    CU cu_E(
        .instr(instr_E),
        .rs(rs_E),
        .rt(rt_E),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUControl(ALUControl_E),
        .MDU_type(MDU_type),
        .RF_data_sel(RF_data_sel_E),
        .RF_write_addr(RF_write_addr_E),
        .bgezal_en_in(bgezal_E)
    );

    ALU alu(
        .a(ALMD_A),
        .b(ALMD_B),
        .op(ALUControl_E),
        .out(ALUResult_E)
    );

    wire [31:0] MDUout_E;


    MDU mdu(
        .clk(clk),
        .reset(reset),
        .rs_data(RS_FWD_E),
        .rt_data(RT_FWD_E),
        .MDU_type(MDU_type),
        .ALMD_sel(ALMD_sel),
        .MDUbusy(busy),
        .MDUout(MDUout_E)
    );

    wire[31:0] ALMDout_E = (ALMD_sel==`ALMD_ALU) ? ALUResult_E : MDUout_E;



    //      Execute
    EX2MEM ex2mem(
        .clk(clk),
        .reset(reset),
        .en(en),
        .regRD2_in(RT_FWD_E),
        .ALUout_in(ALMDout_E),

        .regRD2_out(rt_data_M),
        .ALUout_out(ALMDout_M),

        .instr_in(instr_E),
        .instr_out(instr_M),
		.pc_in(PC_E),
        .pc_out(PC_M),
        .bgezal_en_in(bgezal_E),
        .bgezal_en_out(bgezal_M)
    );
    //      Memory

    wire [2:0] RF_data_sel_M;


    CU cu_M(
        .instr(instr_M),
        .DM_write_addr(ALMDout_M),
        .rt(rt_M),
        .MemWrite(MemWrite_M),
        .RF_data_sel(RF_data_sel_M),
        .RF_write_addr(RF_write_addr_M),
        .DM_data_byteen(m_data_byteen),
        .DM_rdata_byteen(m_rdata_byteen),
        .bgezal_en_in(bgezal_M),
        .jap(jap_M)
    );

    wire [31:0] DM_write_data_M = 
                            (jap_M) ? PC_M + 8   :
                            (rt_M==0) ? 0 :
                            (rt_M==RF_write_addr_W) ? RF_write_data_W :
                             rt_data_M;


    wire lwmx_en_M = $signed(rt_data_M) < $signed(DM_out_M);
    //      Memory
    MEM2WB mem2wb(
        .clk(clk),
        .reset(reset),
        .en(en),
        .DM_out_in(DM_out_M),
        .ALUout_in(ALMDout_M),
    
        .DM_out_out(DM_out_W),
        .ALUout_out(ALMDout_W),
    
        .instr_in(instr_M),
        .instr_out(instr_W),
		.pc_in(PC_M),
        .pc_out(PC_W),
        .bgezal_en_in(bgezal_M),
        .bgezal_en_out(bgezal_W),
        .lwmx_en_in(lwmx_en_M),
        .lwmx_en_out(lwmx_en_W)
    );
    //      Write Back
    wire [2:0] RF_data_sel_W;
    wire [4:0] RF_write_addr_W_;
    wire [4:0] lwmx_addr;

    assign lwmx_addr = (lwmx_en_W) ? 5 : 4;

    assign RF_write_addr_W = (lwmx_W) ? lwmx_addr : 
                              RF_write_addr_W_;

    CU cu_W(
        .instr(instr_W),
        .RF_data_sel(RF_data_sel_W),
        .RF_write_addr(RF_write_addr_W_),
        .RegWrite(RegWrite_W),
        .bgezal_en_in(bgezal_W),
        .lwmx(lwmx_W)
    );
    //      Write Back

    // always@(posedge clk)begin
	//     if(PC_E == 32'h3604)
	// 	    $display("%d@%h: *%h <= %h",$time,instr_E, rt_data_E, PC_E);
	// end

        //Debug
    wire [32*8-1:0] asm_F, asm_D, asm_E, asm_M;
    DASM dasm_F(
        .pc(PC_F),
        .instr(instr_F),
        .imm_as_dec(1'b1),
        .reg_name(1'b0),
        .asm(asm_F)
    );
    DASM dasm_D(
        .pc(PC_D),
        .instr(instr_D),
        .imm_as_dec(1'b1),
        .reg_name(1'b0),
        .asm(asm_D)
    );
    DASM dasm_E(
        .pc(PC_E),
        .instr(instr_E),
        .imm_as_dec(1'b1),
        .reg_name(1'b0),
        .asm(asm_E)
    );
    DASM dasm_M(
        .pc(PC_M),
        .instr(instr_M),
        .imm_as_dec(1'b1),
        .reg_name(1'b0),
        .asm(asm_M)
    );
    DASM dasm_W(
        .pc(PC_W),
        .instr(instr_W),
        .imm_as_dec(1'b1),
        .reg_name(1'b0),
        .asm(asm_W)
    );

endmodule
