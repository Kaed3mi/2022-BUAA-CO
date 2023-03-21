`timescale 1ns / 1ps

`include "IFU.v"
`include "IM.v"
`include "GRF.v"
`include "ALU.v"
`include "PIPREG.v"
`include "SU.v"
`include "MDU.v"
`include "CP0.v"
`include "BE.v"
`include "DASM.v"

module CPU(
	input clk,
    input reset,
    output [31:0] macroscopic_pc, // 宏观 PC
    input [5:2] HWInt_TB,

    output [31:0] m_data_addr, // DM_write_addr
    output [31:0] m_data_wdata,
    output [3:0] m_data_byteen,
    input [31:0] m_data_rdata,

    output [31:0] m_int_addr,     // 中断发生器待写入地址
    output [3 :0] m_int_byteen,   // 中断发生器字节使能信�   output [31:0] m_inst_addr,

    output w_grf_we,
    output [4:0] w_grf_addr,
    output [31:0] w_grf_wdata,

    output [31:0] w_inst_addr
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
	
	assign macroscopic_pc = PC_M;
    assign m_data_addr = ALMDout_M; // DM_addr from ALU

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


   assign DM_out_M = (m_data_addr>=32'h7f60&&m_data_addr<=32'h7f6b) ? m_data_rdata :
                     (m_rdata_byteen==4'b1111) ? BEOut_M                           : 
                     (m_rdata_byteen==4'b0011) ? half_signed_ext(BEOut_M[15:0])    : 
                     (m_rdata_byteen==4'b1100) ? half_signed_ext(BEOut_M[31:16])   : 
                     (m_rdata_byteen==4'b0001) ? byte_signed_ext(BEOut_M[7:0])     :  
                     (m_rdata_byteen==4'b0010) ? byte_signed_ext(BEOut_M[15:8])    : 
                     (m_rdata_byteen==4'b0100) ? byte_signed_ext(BEOut_M[23:16])   : 
                     (m_rdata_byteen==4'b1000) ? byte_signed_ext(BEOut_M[31:24])   : 
                                                     0; //DM_write_data


    assign m_inst_addr = PC_M;
    assign w_grf_we = RegWrite_W;
    assign w_grf_addr = RF_write_addr_W;
    assign w_grf_wdata = RF_write_data_W;
    assign w_inst_addr = PC_W;

    assign instr_F = (ExcAdEL_F) ? 0 : i_inst_rdata;
    

    assign RF_write_data_E = (RF_data_sel_E==`RFWD_PC8) ? PC_E + 8  : 
                              0;

    assign RF_write_data_M = (RF_data_sel_M==`RFWD_ALU) ? ALMDout_M :
                             (RF_data_sel_M==`RFWD_PC8) ? PC_M + 8  : 
                              0; //select data from

    assign RF_write_data_W = (RF_data_sel_W==`RFWD_ALU) ? ALMDout_W :
                             (RF_data_sel_W==`RFWD_MEM) ? DM_out_W  : 
                             (RF_data_sel_W==`RFWD_PC8) ? PC_W + 8  :
                             (RF_data_sel_W==`RFWD_CP0) ? CP0Out_W  :
                              0; //select data from

    SU su(
	    .instr_D(instr_D),
        .instr_E(instr_E),
        .instr_M(instr_M),
        .busy(busy),
        .stall(stall)
    );
    
    wire req;
    wire [4:0] ExcCode_F, ExcCode_D, ExcCode_E, ExcCode_M;
    wire [4:0] ExcPrev_D, ExcPrev_E, ExcPrev_M;

    //(CPUStatus==0 && PC_F >= 32'h4180) ? `EXC_AdEL :
    assign ExcCode_F =  ExcAdEL_F ? `EXC_AdEL :
                        0; 

    assign ExcCode_D =  ExcPrev_D ? ExcPrev_D :
                        syscall_D ? `EXC_Sysc :
                        EXCRI_D   ? `EXC_RI   :
                        0;

    assign ExcCode_E =  ExcPrev_E ? ExcPrev_E :
                        ALU_Ov_E  ? `EXC_Ov   :
                        0;

    assign ExcCode_M =  ExcPrev_M ? ExcPrev_M :
                        ExcAdEL_M ? `EXC_AdEL :
                        ExcAdES_M ? `EXC_AdES :
                        0;


    wire [31:0] jump_addr, i_inst_rdata;
    wire [31:0] EPC;
    IFU ifu(
        .req(req),
        .EXC_AdEL(ExcAdEL_F),
        .eret(eret_D),
        .EPC(EPC),

        
        .clk(clk),
        .rst(reset),
        .stall(stall),
        .branch(branch),
        .offset(offset),
        .jump(jump),
        .jump_addr(jump_addr),
        .pc(PC_F),
        .instr(i_inst_rdata)
    );

    // ext for offset
    assign offset = (instr_D[15]==0) ? {14'h0000,instr_D[15:0],2'b0} : 
                                       {14'h3fff,instr_D[15:0],2'b0} ;


    assign BD_F = (jump|branch);
    //      Instruction Fetch
    IF2ID if2id(
        .req(req),
        .ExcCode_in(ExcCode_F),
        .ExcCode_out(ExcPrev_D),
        .BD_in(BD_F),
        .BD_out(BD_D),

        .clk(clk),
        .stall(stall),
        .reset(reset),// | (~stall & clear_delay)
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
        .jump_addr(jump_addr),
        // exception
        .EXCRI(EXCRI_D),
        .eret(eret_D),
        .syscall(syscall_D)
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
    //      Execute
    ID2EX id2ex(
        .req(req),
        .ExcCode_in(ExcCode_D),
        .ExcCode_out(ExcPrev_E),
        .BD_in(BD_D),
        .BD_out(BD_E),

        .clk(clk),
        .stall(stall),
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
        .ALUOv_Dectect(ALUOv_Dectect),
        .ALUDMOv_Dectect(ALUDMOv_Dectect),
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
        .ALUOv_Dectect(ALUOv_Dectect),
        .ALUDMOv_Dectect(ALUDMOv_Dectect),
        .ALU_Ov(ALU_Ov_E),
        .ALU_DMOv(ALU_DMOv_E),

        .a(ALMD_A),
        .b(ALMD_B),
        .op(ALUControl_E),
        .out(ALUResult_E)
    );

    wire [31:0] MDUout_E;


    MDU mdu(
        .req(req),

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


    //      Memory
    EX2MEM ex2mem(
        .req(req),
        .ExcCode_in(ExcCode_E),
        .ExcCode_out(ExcPrev_M),
        .BD_in(BD_E),
        .BD_out(BD_M),
        .ExcDMOv_in(ALU_DMOv_E),
        .ExcDMOv_out(ExcDMOv_M),
            

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
    
    wire [2:0] RF_data_sel_M;
    wire [4:0] CP0WA_M;
    wire [3:0] CPUByteEn;
    CU cu_M(
        .instr(instr_M),
        .DM_write_addr(ALMDout_M),
        .rt(rt_M),
        .MemWrite(MemWrite_M),
        .RF_data_sel(RF_data_sel_M),
        .RF_write_addr(RF_write_addr_M),
        .DM_data_byteen(CPUByteEn),
        .DM_rdata_byteen(m_rdata_byteen),
        .bgezal_en_in(bgezal_M),
        .load(load_M),
        .store(store_M),
        .lw(lw_M),
        .lh(lh_M),
        .lb(lb_M),
        .sw(sw_M),
        .sh(sh_M),
        .sb(sb_M),
        .eret(eret_M),
        .mtc0(mtc0_M),
        .syscall(syscall_M),
        .CP0WE(CP0WE_M),
        .CP0WA(CP0WA_M)
    );

    wire [31:0] DM_write_data_M = 
                            (rt_M==0) ? 0 :
                            (rt_M==RF_write_addr_W) ? RF_write_data_W :
                             rt_data_M;

    //BE
    wire [31:0] BEOut_M;
    wire [1:0] HWInt_BE;
    wire [3:0] m_data_byteen_;

    
    BE be(
        .clk(clk),
        .reset(reset),
        .VAdd(m_data_addr),
        .CPUByteEn(CPUByteEn),
        .WD(DM_write_data_M),
        .m_data_byteen(m_data_byteen),

        .m_inst_addr(PC_M),
        .DMByteEn(m_data_byteen_),
        .BEOut(BEOut_M),
        .HWInt_BE(HWInt_BE)
    );

    assign m_data_byteen = (ExcAdES_M) ? 0 : 
                           (req) ? 0 : m_data_byteen_;

    //Exception
    //                     (CPUStatus==0&&m_data_addr>=32'h4180)|
    wire ExcAdEL_M = (load_M==0) ? 0 : 
                     ExcDMOv_M|//地址溢出
                     (lw_M && m_data_addr[1:0]!=0) |//对齐
                     (lh_M && m_data_addr[0]  !=0) |//对齐
                     (m_data_addr>=32'h3000 && m_data_addr<=32'h7eff)|//该部分为指令空间和空
                     (lh_M && m_data_addr>=32'h7f00 && m_data_addr<=32'h7f1f)|//必须字访�                   
                     (lb_M && m_data_addr>=32'h7f00 && m_data_addr<=32'h7f1f)|//必须字访�                   
                     (m_data_addr>=32'h7f0c && m_data_addr<=32'h7f0f)|//TC1 empty reg
                     (m_data_addr>=32'h7f1c && m_data_addr<=32'h7f1f)|//TC2 empty reg
                     (m_data_addr>=32'h7f74);

    wire ExcAdES_M = (store_M==0) ? 0 : 
                     ExcDMOv_M|//地址溢出
                     (sw_M && m_data_addr[1:0]!=0) |//对齐
                     (sh_M && m_data_addr[0]  !=0) |//对齐
                     (sh_M && m_data_addr>=32'h7f00 && m_data_addr<=32'h7f1f)|//必须字访�                   
                     (sb_M && m_data_addr>=32'h7f00 && m_data_addr<=32'h7f1f)|//必须字访�                   
                     (m_data_addr>=32'h3000 && m_data_addr<=32'h7eff)|//该部分为指令空间和空
                     (m_data_addr>=32'h7f08 && m_data_addr<=32'h7f0b)|//不能存count
                     (m_data_addr>=32'h7f18 && m_data_addr<=32'h7f1b)|//不能存count
                     (m_data_addr>=32'h7f0c && m_data_addr<=32'h7f0f)|//TC1 empty reg
                     (m_data_addr>=32'h7f1c && m_data_addr<=32'h7f1f)|//TC2 empty reg
                     (m_data_addr>=32'h7f74);


    wire [31:0] CP0Out_M, CP0Out_W;
    wire [5:0] HWInt = {HWInt_TB, HWInt_BE};
    
    CP0 cp0(
        .clk(clk),
        .reset(reset),
        .WE(CP0WE_M),
        .CP0Add(CP0WA_M),
        .CP0In(DM_write_data_M),
        .CP0Out(CP0Out_M),
        .VPC(PC_M),
        .BDIn(BD_M),
        .ExcCodeIn(ExcCode_M),
        .HWInt(HWInt),
        .EXLClr(eret_M),
        .syscall(syscall_M),
        .EPCOut(EPC),
        .Req(req),
        .CPUStatus(CPUStatus)
    );

     assign m_int_addr = m_data_addr;
     assign m_int_byteen = CPUByteEn;


    //      Memory
    MEM2WB mem2wb(
        .req(req),
        .CP0Out_in(CP0Out_M),
        .CP0Out_out(CP0Out_W),

        .clk(clk),
        .reset(reset),
        .en(en),
        .DM_out_in(BEOut_M),
        .ALUout_in(ALMDout_M),
    
        .DM_out_out(DM_out_W),
        .ALUout_out(ALMDout_W),
    
        .instr_in(instr_M),
        .instr_out(instr_W),
		.pc_in(PC_M),
        .pc_out(PC_W),
        .bgezal_en_in(bgezal_M),
        .bgezal_en_out(bgezal_W)
        
    );
    //      Write Back

    wire [2:0] RF_data_sel_W;

    CU cu_W(
        .instr(instr_W),
        .RF_data_sel(RF_data_sel_W),
        .RF_write_addr(RF_write_addr_W),
        .RegWrite(RegWrite_W),
        .bgezal_en_in(bgezal_W)
    );
    //      Write Back


        //Debug


endmodule
