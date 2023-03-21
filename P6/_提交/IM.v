`timescale 1ns / 1ps
`include "const.v"

module IMM_EXT(
    input [15:0] in,
    input type,
    output [31:0] out
);

    assign out = (type==0) ? {16'h0000,in} :
                (in[15]==0)? {16'h0000,in} : {16'hffff,in};

endmodule
