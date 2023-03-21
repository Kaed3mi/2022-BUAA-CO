`timescale 1ns / 1ps

`include "const.v"
module PC(
    input clk,
    input rst,
    input branch,
    input jump,
    input [31:0] offset,
    input [31:0] jump_addr,
    output reg [31:0] npc
    );

  always @(posedge clk) begin
    case (rst)
        1:npc <= 12288;
        0:begin
            if(branch)      npc <= npc + 4 + offset;
            else if(jump)   npc <= jump_addr;
            else            npc <= npc + 4;
        end
    endcase
  end

endmodule