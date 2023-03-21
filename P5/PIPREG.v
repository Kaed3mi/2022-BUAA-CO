`timescale 1ns / 1ps

`include "const.v"
module IF2ID(
    input clk,
    input reset,
    input en,
    input [31:0] instr_F,
    output reg [31:0] instr_D,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);
  always @(posedge clk) begin
    if(reset) begin
        instr_D <= 0;
        pc_out <= 16'h3000;
    end
    else if(en) begin
        instr_D <= instr_F;
        pc_out <= pc_in;
    end
  end
endmodule

module ID2EX(
    input clk,
    input reset,
    input en,

    input [31:0] regRD1_in,
    input [31:0] regRD2_in,
    input [31:0] imm_in,

    output reg [31:0] regRD1_out,
    output reg [31:0] regRD2_out,
    output reg [31:0] imm_out,

    input [31:0] instr_in,
    output reg [31:0] instr_out,
    input [31:0] pc_in,
    output reg [31:0] pc_out,
    input bgezal_en_in,
    output reg bgezal_en_out
);
  always @(posedge clk) begin
    if(reset) begin
        regRD1_out <= 0;
        regRD2_out <= 0;
        imm_out <= 0;

        instr_out <= 0;
        pc_out <= 16'h3000;
        bgezal_en_out <= 0;
    end
    else if(en) begin
        regRD1_out <= regRD1_in;
        regRD2_out = regRD2_in;
        imm_out = imm_in;

        instr_out <= instr_in;
        pc_out <= pc_in;
        bgezal_en_out <= bgezal_en_in;
    end
  end

endmodule

module EX2MEM(
    input clk,
    input reset,
    input en,
    input [31:0] regRD2_in,
    input [31:0] ALUout_in,

    output reg [31:0] regRD2_out,
    output reg [31:0] ALUout_out,
  
    input [31:0] instr_in,
    output reg [31:0] instr_out,
    input [31:0] pc_in,
    output reg [31:0] pc_out,
    input bgezal_en_in,
    output reg bgezal_en_out
);
always @(posedge clk) begin
    if(reset) begin
        regRD2_out <= 0;
        ALUout_out <= 0;
        
        instr_out <= 0;
        pc_out <= 16'h3000;
        bgezal_en_out <= 0;
    end
    else if(en) begin
        regRD2_out = regRD2_in;
        ALUout_out <= ALUout_in;

        instr_out <= instr_in;
        pc_out <= pc_in;
        bgezal_en_out <= bgezal_en_in;
    end
end

endmodule

module MEM2WB(
    input clk,
    input reset,
    input en,
    input [4:0] regWR_in,
    input [31:0] DM_out_in,
    input [31:0] ALUout_in,
   
    output reg [4:0] regWR_out,
    output reg [31:0] DM_out_out,
    output reg [31:0] ALUout_out,
    
    input [31:0] instr_in,
    output reg [31:0] instr_out,
    input [31:0] pc_in,
    output reg [31:0] pc_out,
    input bgezal_en_in,
    output reg bgezal_en_out,
    input lhogez_en_in,
    output reg lhogez_en_out
);
always @(posedge clk) begin
    if(reset) begin
        regWR_out <= 0;
        DM_out_out <= 0;
        ALUout_out <= 0;
        
        instr_out <= 0;
        pc_out <= 16'h3000;
        bgezal_en_out <= 0;
        lhogez_en_out <= 0;
    end
    else if(en) begin
        regWR_out = regWR_in;
        DM_out_out = DM_out_in;
        ALUout_out <= ALUout_in;
        
        instr_out <= instr_in;
        pc_out <= pc_in;
        bgezal_en_out <= bgezal_en_in;
        lhogez_en_out <= lhogez_en_in;
    end
end
endmodule

