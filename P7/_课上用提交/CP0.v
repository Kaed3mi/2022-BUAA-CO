`timescale 1ns / 1ps

`define IM SR[15:10]    // Interrupt Mask
`define EXL SR[1]       // Exception Level
`define IE SR[0]        // Interrupt Enable
`define BD Cause[31]    // Branch Delay
`define IP Cause[15:10] // Interrupt Pending
`define ExcCode Cause[6:2]

module CP0(
    input clk,
    input reset,
    input WE,
    input [4:0] CP0Add,     // CP0 reg addr
    input [31:0] CP0In,     // CP0 reg write data
    output [31:0] CP0Out,   // CP0 reg out data
    input [31:0] VPC,       // victim PC
    input BDIn,             // Branch Delay Instrction
    input [4:0] ExcCodeIn,
    input [5:0] HWInt,
    input EXLClr,
    input syscall,
    output [31:0] EPCOut,
    output Req,
    output CPUStatus
);
//----------------------
    reg [31:0] SR;
    reg [31:0] Cause;       //异常编码，记录当前发生的是什么异常。
    reg [31:0] EPC;      //记录异常处理结束后需要返回的 PC。
//----------------------
    //debug
    wire [5:0] IM = SR[15:10];
    wire EXL = SR[1];       // Exception Level
    wire IE = SR[0];        // Interrupt Enable
    wire BD = Cause[31];    // Branch Delay
    wire [5:0] IP = Cause[15:10]; // Interrupt Pending
    wire [4:0] ExcCode = Cause[6:2];
//----------------------
    assign CPUStatus = `EXL;

    wire IntReq = (|(HWInt & `IM)) & ~`EXL & `IE;
    wire ExcReq = (|ExcCodeIn) & ~`EXL;
    assign Req  = IntReq | ExcReq | syscall;


    wire [31:0] EPC_ =  (Req) ? (BDIn ? VPC-4 : VPC) : EPC;

    assign EPCOut = EPC;

    assign CP0Out = (CP0Add==12) ? SR       :
                    (CP0Add==13) ? Cause    :
                    (CP0Add==14) ? EPCOut   :
                    0;

    always @(posedge clk) begin
        if(reset)begin
            SR <= 0;
            Cause <= 0;
            EPC <= 0;
        end else begin
            if(EXLClr) begin 
                `EXL <= 0;
            end else if(Req)begin
                `ExcCode <= IntReq ? 0 : ExcCodeIn;
                `IP <= HWInt;
                `EXL <= 1;
                EPC <= EPC_;
                `BD <= BDIn;
            end else if(WE)begin
                case(CP0Add)
                    12: SR <= CP0In;
                    14: EPC <= (syscall) ? VPC+4 : CP0In;
                endcase
            end
            
        end
    end



endmodule