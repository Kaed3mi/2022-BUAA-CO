ori $a0,$a0,110
ori $a1,$a0,111
ori $a2,$a0,112
lui $a3,0xffff
lui $t0,1
add $a2,$a0,$a1
sub $a2,$a1,$a0
jal loop
add $t2,$s0,$a0
j end
sub $t2,$t2,$t2
loop:
sub $a0,$a0,$t2
jr $ra
end:
lui $a0,111
sub $a0,$a0,$a2
add $a2,$a2,$a0
ori $a0,$0,1
ori $a1,$a0,2
ori $a2,$a1,3
beq $a2,$a1,end
add $a0,$a0,$a0