`timescale 1ns/1ps
`include "mips.v"
module mips_txt;

	reg clk;
	reg reset;
	reg interrupt;

	wire [31:0] macroscopic_pc;


	wire [31:0] m_int_addr;
	wire [3 :0] m_int_byteen;


	wire		w_grf_we;
	wire [4 :0] w_grf_addr;
	wire [31:0] w_grf_wdata;

	wire [31:0] w_inst_addr;


	mips uut(
		.clk_in(),
    	.sys_rstn,
    	// dip switch
    	.dip_switch0,
    	.dip_switch1,
    	.dip_switch2,
    	.dip_switch3,
    	.dip_switch4,
    	.dip_switch5,
    	.dip_switch6,
    	.dip_switch7,
    	// key
    	.user_key,
    	// led
    	.led_light,
    	// digital tube
    	.digital_tube2,
    	.digital_tube_sel2,
    	digital_tube1,
    	[3:0] digital_tube_sel1,
    	digital_tube0,
    	[3:0] digital_tube_sel0,

		.interrupt(interrupt),
		.macroscopic_pc(macroscopic_pc),


		.m_int_addr(m_int_addr),
		.m_int_byteen(m_int_byteen),


		.w_grf_we(w_grf_we),
		.w_grf_addr(w_grf_addr),
		.w_grf_wdata(w_grf_wdata),

		.w_inst_addr(w_inst_addr)
	);

	initial begin
        $dumpfile("wave.vcd");
        $dumpvars;

        clk = 0;
        reset = 1;
        #20 reset = 0;

        #200;
        $finish;
	end



	// ----------- For Registers -----------

	always @(posedge clk) begin
		if (~reset) begin
			if (w_grf_we && (w_grf_addr != 0)) begin
				$display("%d@%h: $%d <= %h", $time, w_inst_addr, w_grf_addr, w_grf_wdata);
				//$display("@%h: $%d <= %h", w_inst_addr, w_grf_addr, w_grf_wdata);
			end
		end
	end

	// ----------- For Interrupt -----------

	wire [31:0] fixed_macroscopic_pc;

	assign fixed_macroscopic_pc = macroscopic_pc & 32'hfffffffc;

	parameter target_pc = 32'h0000_9999;

	integer count;

	initial begin
		count = 0;
	end

	always @(negedge clk) begin
		if (reset) begin
			interrupt = 0;
		end
		else begin
			if (interrupt) begin
				if (|m_int_byteen && (m_int_addr & 32'hfffffffc) == 32'h7f20) begin
					interrupt = 0;
				end
			end
			else if (fixed_macroscopic_pc == target_pc) begin
				if (count == 0) begin
					count = 1;
					interrupt = 1;
				end
			end
		end
	end

	always #2 clk <= ~clk;

endmodule