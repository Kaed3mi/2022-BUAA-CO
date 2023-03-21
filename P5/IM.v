`timescale 1ns / 1ps
`include "const.v"
module IM(
    input [31:0] addr,
    output [31:0] data
    );
    
    reg [31:0] instr [0:4095];

    initial begin
            $readmemh("code.txt", instr);
    end

    assign data = instr[(addr>>2)-3072];

endmodule

module IMM_EXT(
    input [15:0] in,
    input type,
    output [31:0] out
);

    assign out = (type==0) ? {16'h0000,in} :
                (in[15]==0)? {16'h0000,in} : {16'hffff,in};

endmodule
