`timescale 1ns / 1ps
`include "const.v"
`include "CU.v"
module SU(
	input [31:0] instr_D,
    input [31:0] instr_E,
    input [31:0] instr_M,
    input busy,
    output stall
    );

    //wire load_D, store_D, r_cal_D, i_cal_D, branch_D, j_r_D;
    //D
    
    wire [4:0] rs_D, rt_D;
    CU SU_D(
        .instr(instr_D),
        .rs(rs_D),
        .rt(rt_D),
        .load(load_D),
        .store(store_D),
        .r_cal(r_cal_D),
        .i_cal(i_cal_D),
        .branch_ins(branch_D),
        .j_r(j_r_D),
        .md(md_D),
        .mt(mt_D),
        .mf(mf_D),
        .shift_s(shift_s_D),
        .mtc0(mtc0_D),
        .eret(eret_D)
    );
    wire [2:0] rs_Tuse = (branch_D | j_r_D) ? 0 :
                         ((r_cal_D | !shift_s_D)| load_D | store_D | i_cal_D | md_D | mt_D) ? 1 :
                         3,
               rt_Tuse = (branch_D) ? 0 :
                         (r_cal_D|md_D) ? 1 :
                         (store_D|mtc0_D) ? 2 :
                         3;
                         
    wire [4:0] RF_write_addr_E, RF_write_addr_M;
    wire [4:0]  rd_E, rd_M;
    //E
    CU SU_E(
        .instr(instr_E),
        .load(load_E),
        .r_cal(r_cal_E),
        .i_cal(i_cal_E),
        .branch_ins(branch_E),
        .j_r(j_r_E),
        .RF_write_addr(RF_write_addr_E),
        .mf(mf_E),
        .mfc0(mfc0_E),
        .mtc0(mtc0_E),
        .rd(rd_E)
    );
    wire [2:0] Tnew_E = (load_E|mfc0_E) ? 2 :
                        (r_cal_E | i_cal_E | mf_E) ? 1:
                        0;
    //M
    CU SU_M(
        .instr(instr_M),
        .load(load_M),
        .RF_write_addr(RF_write_addr_M),
        .mfc0(mfc0_M),
        .mtc0(mtc0_M),
        .rd(rd_M)
    );
    
    wire [2:0] Tnew_M = (load_M|mfc0_M) ? 1 : 0;

    wire rs_stall_e = (rs_Tuse < Tnew_E) && rs_D && (rs_D == RF_write_addr_E);
    wire rs_stall_m = (rs_Tuse < Tnew_M) && rs_D && (rs_D == RF_write_addr_M);
    wire rs_stall = rs_stall_e | rs_stall_m;

    wire rt_stall_e = (rt_Tuse < Tnew_E) && rt_D && (rt_D == RF_write_addr_E);
    wire rt_stall_m = (rt_Tuse < Tnew_M) && rt_D && (rt_D == RF_write_addr_M);
    wire rt_stall = rt_stall_e | rt_stall_m;

    wire MDU_stall = busy && (md_D | mt_D |mf_D);
    
    wire eret_stall = eret_D && ((mtc0_E && rd_E == 5'd14) 
                              || (mtc0_M && rd_M == 5'd14));

    assign stall = rs_stall | rt_stall | MDU_stall | eret_stall; // | (lwm_E|lwm_M)

endmodule
