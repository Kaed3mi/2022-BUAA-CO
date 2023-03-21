`timescale 1ns / 1ps

`include "const.v"
module IF2ID(
    input req,
    input [4:0] ExcCode_in,
    output reg [4:0] ExcCode_out,
    input BD_in,
    output reg BD_out,

    input clk,
    input stall,
    input reset,
    input en,
    input [31:0] instr_F,
    output reg [31:0] instr_D,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);
  always @(posedge clk) begin
    if(reset|req) begin
        ExcCode_out <= 0;
        BD_out <= 0;

        instr_D <= 0;
        pc_out  <= reset ? 32'h0000_3000 :
                     req ? 32'h0000_4180 : 0;
    end
    else if(en) begin
        ExcCode_out <= ExcCode_in;
        BD_out <= BD_in;

        instr_D <= instr_F;
        pc_out <= pc_in;
    end
  end
endmodule

module ID2EX(
    input req,
    input [4:0] ExcCode_in,
    output reg [4:0] ExcCode_out,
    input BD_in,
    output reg BD_out,

    input clk,
    input stall,
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
    if(reset|req|stall) begin
        ExcCode_out <= 0;
        BD_out <= stall ? BD_in : 0;
        
        regRD1_out <= 0;
        regRD2_out <= 0;
        imm_out <= 0;

        instr_out <= 0;
        
        
        pc_out <= (stall) ? pc_in : (req ? 32'h0000_4180 : 0);
        bgezal_en_out <= 0;
    end
    else if(en) begin
        ExcCode_out <= ExcCode_in;
        BD_out <= BD_in;

        regRD1_out <= regRD1_in;
        regRD2_out <= regRD2_in;
        imm_out <= imm_in;

        instr_out <= instr_in;
        pc_out <= pc_in;
        bgezal_en_out <= bgezal_en_in;
    end
  end

endmodule

module EX2MEM(
    input req,
    input [4:0] ExcCode_in,
    output reg [4:0] ExcCode_out,
    input BD_in,
    output reg BD_out,
    input ExcDMOv_in,
    output reg ExcDMOv_out,

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
    if(reset|req) begin
        ExcCode_out <= 0;
        BD_out <= 0;
        ExcDMOv_out <= 0;

        regRD2_out <= 0;
        ALUout_out <= 0;
        
        instr_out <= 0;
        pc_out <= req ? 32'h0000_4180 : 0;
        bgezal_en_out <= 0;
    end
    else if(en) begin
        ExcCode_out <= ExcCode_in;
        BD_out <= BD_in;
        ExcDMOv_out <= ExcDMOv_in;

        regRD2_out <= regRD2_in;
        ALUout_out <= ALUout_in;

        instr_out <= instr_in;
        pc_out <= pc_in;
        bgezal_en_out <= bgezal_en_in;
    end
end

endmodule

module MEM2WB(
    input req,
    input [31:0] CP0Out_in,
    output reg [31:0] CP0Out_out,

    input clk,
    input reset,
    input en,
    input [31:0] DM_out_in,
    input [31:0] ALUout_in,
   
    output reg [31:0] DM_out_out,
    output reg [31:0] ALUout_out,
    
    input [31:0] instr_in,
    output reg [31:0] instr_out,
    input [31:0] pc_in,
    output reg [31:0] pc_out,
    input bgezal_en_in,
    output reg bgezal_en_out
);
always @(posedge clk) begin
    if(reset|req) begin
        CP0Out_out <= 0;

        DM_out_out <= 0;
        ALUout_out <= 0;
        
        instr_out <= 0;
        pc_out <= req ? 32'h0000_4180 : 0;
        bgezal_en_out <= 0;
    end
    else if(en) begin
        CP0Out_out <= CP0Out_in;

        DM_out_out <= DM_out_in;
        ALUout_out <= ALUout_in;
        
        instr_out <= instr_in;
        pc_out <= pc_in;
        bgezal_en_out <= bgezal_en_in;
    end
end
endmodule

