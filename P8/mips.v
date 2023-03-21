`timescale 1ns / 1ps

`include "CPU.v"
`include "digital_tube.v"

module mips (
    // clock and reset
    input wire clk_in,
    input wire sys_rstn,
    // dip switch
    input wire [7:0] dip_switch0,
    input wire [7:0] dip_switch1,
    input wire [7:0] dip_switch2,
    input wire [7:0] dip_switch3,
    input wire [7:0] dip_switch4,
    input wire [7:0] dip_switch5,
    input wire [7:0] dip_switch6,
    input wire [7:0] dip_switch7,
    // key
    input wire [7:0] user_key,
    // led
    output wire [31:0] led_light,
    // digital tube
    output wire [7:0] digital_tube2,
    output wire digital_tube_sel2,
    output wire [7:0] digital_tube1,
    output wire [3:0] digital_tube_sel1,
    output wire [7:0] digital_tube0,
    output wire [3:0] digital_tube_sel0,
    // uart
    input wire uart_rxd,
    output wire uart_txd,

    // p7
    input wire interrupt,
    output wire [31:0] macroscopic_pc,
    output wire [3:0] m_data_byteen,

    output wire [31:0] m_int_addr,
    output wire [3 :0] m_int_byteen,

    output wire [31:0] m_inst_addr,
    output wire w_grf_we,
    output wire [4:0] w_grf_addr,
    output wire [31:0] w_grf_wdata,
    output wire [31:0] w_inst_addr
);

    // Exception

    wire [5:2] HWInt_TB = {3'b0, interrupt};


    wire [31:0] m_data_addr, m_data_wdata, m_data_rdata;
    CPU cpu(
        .clk(clk_in),
        .reset(~sys_rstn),
        .macroscopic_pc(macroscopic_pc),  // 瀹忚 PC
        .HWInt_TB(HWInt_TB),

        .m_data_addr(m_data_addr),
		.m_data_wdata(m_data_wdata),
		.m_data_byteen(m_data_byteen),
        .m_data_rdata(m_data_rdata),

		.m_int_addr(m_int_addr),
		.m_int_byteen(m_int_byteen),


		.w_grf_we(w_grf_we),
		.w_grf_addr(w_grf_addr),
		.w_grf_wdata(w_grf_wdata),

		.w_inst_addr(w_inst_addr)
    );

    /* ------ Calculator ------ */
    wire [31:0] DIP0 = ~({dip_switch3, dip_switch2, dip_switch1, dip_switch0});
    wire [31:0] DIP1 = ~({dip_switch7, dip_switch6, dip_switch5, dip_switch4});

    assign m_data_rdata = (m_data_addr==32'h7f60) ? DIP0 :
                          (m_data_addr==32'h7f64) ? DIP1 :
                          0;
    //two dip_switch
    wire uart_en = 0;
    /* ------ Digital Tube ------ */
    reg [31:0] digital_reg;
    always @(posedge clk_in) begin
        if(~sys_rstn)begin
        end
        else begin
            if((&m_data_byteen)&&m_data_addr==32'h7f50)begin
                digital_reg <= m_data_wdata;
            end
        end
    end
    wire [31:0] digital_data;
    wire digital_en;
    wire alu_sign = digital_reg[31];
    
    assign digital_tube_sel2 = 1'b1;
    assign digital_tube2 = uart_en  ? 8'b1110_0000 :// 'b'
                           alu_sign ? 8'b1111_1110 :// '-'
                                      8'b1111_1111; // all off
    wire [15:0] byte_disp = 0, 
                baud_disp = 0;
    assign digital_data = uart_en ? {byte_disp, baud_disp} : digital_reg;
    
    assign digital_en = uart_en;

    digital_tube d0 (
        .clk(clk_in),
        .rstn(sys_rstn),
        .en(digital_en),
        .data(digital_data[15:0]),
        .sel(digital_tube_sel0),
        .seg(digital_tube0)
    );

    digital_tube d1 (
        .clk(clk_in),
        .rstn(sys_rstn),
        .en(digital_en),
        .data(digital_data[31:16]),
        .sel(digital_tube_sel1),
        .seg(digital_tube1)
    );
endmodule
