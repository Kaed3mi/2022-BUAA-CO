`timescale 1ns / 1ps

module IM(
    input [13:2] addr,
    output [31:0] data
    );

    reg [31:0] instr [0:4095];

    initial begin
            $readmemh("code.txt", instr);
    end

    assign data = instr[addr-3072];

endmodule
