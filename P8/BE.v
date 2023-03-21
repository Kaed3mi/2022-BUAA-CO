`timescale 1ns / 1ps

`define TC1Addr_begin   32'h0000_7f00
`define TC1Addr_end     32'h0000_7f0b
`define TC2Addr_begin   32'h0000_7f10
`define TC2Addr_end     32'h0000_7f1b

`include "timer.v"

module BE(
    input clk,
    input reset,
    input [31:0] m_inst_addr,
    input [31:0] VAdd,
    input [3 :0] CPUByteEn,
    input [31:0] WD,
    output [31:0] DMAdd,
    output [31:0] TC1Add,
    output [31:0] TC2Add,

    input [3:0] m_data_byteen,
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

    integer i;
	reg [31:0] fixed_addr;
	reg [31:0] fixed_wdata;
	reg [31:0] data[0:4095];
    wire [31:0] DMout;
    // DM dm(
    //     .clka(~clk), // input clka
    //     .wea(m_data_byteen), // input [3 : 0] wea
    //     .addra(DMAdd[12:0]), // input [12 : 0] addra
    //     .dina(WD), // input [31 : 0] dina
    //     .douta(DMout) // output [31 : 0] douta
    // );
    	// ----------- For Data Memory -----------
    
	assign DMout = data[(DMAdd >> 2) % 5120];

	always @(*) begin
		fixed_wdata = data[(DMAdd >> 2) & 4095];
		fixed_addr = DMAdd & 32'hfffffffc;
		if (m_data_byteen[3]) fixed_wdata[31:24] = WD[31:24];
		if (m_data_byteen[2]) fixed_wdata[23:16] = WD[23:16];
		if (m_data_byteen[1]) fixed_wdata[15: 8] = WD[15: 8];
		if (m_data_byteen[0]) fixed_wdata[7 : 0] = WD[7 : 0];
	end

	always @(posedge clk) begin
		if (reset) for (i = 0; i < 4096; i = i + 1) data[i] <= 0;
		else if (|m_data_byteen && fixed_addr >> 2 < 4096) begin
			data[fixed_addr >> 2] <= fixed_wdata;
			$display("%d@%h: *%h <= %h", $time, m_inst_addr, fixed_addr, fixed_wdata);
		end
	end
    

endmodule