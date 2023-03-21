`timescale 1ns / 1ps

`include "const.v"
module PC(
    input clk,
    input rst,
    input branch,
    input jump,
    input stall,
    input [31:0] offset,
    input [31:0] jump_addr,
    output reg [31:0] npc
    );

  always @(posedge clk) begin
    if (rst) npc <= 32'h3000;
      else begin
            if(stall)       npc <= npc;
            else if(branch) npc <= npc + offset;
            else if(jump)   npc <= jump_addr;
            else            npc <= npc + 4;
        end
  end


endmodule