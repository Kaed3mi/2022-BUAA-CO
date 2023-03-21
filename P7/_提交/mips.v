`timescale 1ns / 1ps

`include "CPU.v"


module mips(
    input clk,
    input reset,
    input interrupt,
    output [31:0] macroscopic_pc,

    input [31:0] i_inst_rdata, // instr got from extern IM
    input [31:0] m_data_rdata, // DM data got from extern DM
    output [31:0] i_inst_addr, // PC
    output [31:0] m_data_addr, // DM_write_addr
    output [31:0] m_data_wdata,
    output [3:0] m_data_byteen,

    output [31:0] m_int_addr,
    output [3 :0] m_int_byteen,

    output [31:0] m_inst_addr,
    output w_grf_we,
    output [4:0] w_grf_addr,
    output [31:0] w_grf_wdata,
    output [31:0] w_inst_addr
);

    // Exception

    wire [5:2] HWInt_TB = {3'b0, interrupt};

    CPU cpu(
        .clk(clk),
        .reset(reset),
        .macroscopic_pc(macroscopic_pc),  // 宏观 PC
        .HWInt_TB(HWInt_TB),


        .i_inst_addr(i_inst_addr),
		.i_inst_rdata(i_inst_rdata),

		.m_data_addr(m_data_addr),
		.m_data_rdata(m_data_rdata),
		.m_data_wdata(m_data_wdata),
		.m_data_byteen(m_data_byteen),

		.m_int_addr(m_int_addr),
		.m_int_byteen(m_int_byteen),

		.m_inst_addr(m_inst_addr),

		.w_grf_we(w_grf_we),
		.w_grf_addr(w_grf_addr),
		.w_grf_wdata(w_grf_wdata),

		.w_inst_addr(w_inst_addr)
    );


endmodule
