`timescale 1ns / 1ps

`define TC1Addr_begin   32'h0000_7f00
`define TC1Addr_end     32'h0000_7f0b
`define TC2Addr_begin   32'h0000_7f10
`define TC2Addr_end     32'h0000_7f1b

`include "timer.v"

module BE(
    input clk,
    input reset,
    input [31:0] VAdd,
    input [3 :0] CPUByteEn,
    input [31:0] WD,
    input [31:0] DMout,
    output [31:0] DMAdd,
    output [31:0] TC1Add,
    output [31:0] TC2Add,

    output [3:0] DMByteEn,
    output TC1WE,
    output TC2WE,
    output [31:0] BEOut,
    output [1:0] HWInt_BE
);
    assign DMAdd = (|DMByteEn) ? VAdd : 0;
    assign TC1Add = (VAdd >= `TC1Addr_begin && VAdd <= `TC1Addr_end) ? {VAdd[31:2],2'b0} : 0;
    assign TC2Add = (VAdd >= `TC2Addr_begin && VAdd <= `TC2Addr_end) ? {VAdd[31:2],2'b0} : 0;


    assign HWInt_BE = {IRQ2, IRQ1};

    assign DMByteEn = (VAdd < 32'h3000) ? CPUByteEn : 0;
    assign TC1WE = (&CPUByteEn && VAdd >= `TC1Addr_begin && VAdd <= `TC1Addr_end);
    assign TC2WE = (&CPUByteEn && VAdd >= `TC2Addr_begin && VAdd <= `TC2Addr_end);

    wire [31:0] TC1Out, TC2Out;

    assign BEOut = (VAdd < 32'h3000)                                ? DMout :
                   (VAdd >= `TC1Addr_begin && VAdd <= `TC1Addr_end) ? TC1Out:
                   (VAdd >= `TC2Addr_begin && VAdd <= `TC2Addr_end) ? TC2Out:
                   0;

    TC TC1(
        .clk(clk),
        .reset(reset),
        .Addr(VAdd[31:2]),
        .WE(TC1WE),
        .Din(WD),
        .Dout(TC1Out),
        .IRQ(IRQ1)
    );


    TC TC2(
        .clk(clk),
        .reset(reset),
        .Addr(VAdd[31:2]),
        .WE(TC2WE),
        .Din(WD),
        .Dout(TC2Out),
        .IRQ(IRQ2)
    );


endmodule