.data
    str: .space 80
    num: .word 0
.text
    li $v0, 4		# read string
    la $a0, str		# load address
    li $a1, 80		# string length
    syscall
    li $v0, 5		# read int
    syscall
    move $t0, $v0	# save the length
    la $t1, str		# load address
    li $t2, 0		# initialize loop variable
    j Loop			# jump to label loop
Loop:
    beq $t2, $t0, End	# if loop variable == length, end
    lb $t3, 0($t1)	# load byte
    li $t4, 97		# 'a'
    blt $t3, $t4, End	# if byte < 'a', end
    li $t4, 122	# 'z'
    bgt $t3, $t4, End	# if byte > 'z', end
    addi $t2, $t2, 1	# increase loop variable
    addi $t1, $t1, 1	# increase address
    j Loop			# jump to label loop
End:
    beq $t2, $t0, Palindrome	# if loop variable == length, palindrome
    move $a0, $zero	# register a0 = 0
    li $v0, 1		# print int
    syscall
    li $v0, 10		# exit
    syscall
Palindrome:
    li $t0, 0		# initialize loop variable
    li $t1, 0		# initialize loop variable
    j Loop2			# jump to label loop2
Loop2:
    bge $t0, $t2, End2	# if loop variable >= length, end
    lb $t3, 0($s1)	# load byte
    lb $t4, 0($s2)	# load byte
    bne $t3, $t4, End2	# if byte != byte, end
    addi $t0, $t0, 1	# increase loop variable
    addi $t1, $t1, -1	# decrease loop variable
    addi $s1, $s1, 1	# increase address
    addi $s2, $s2, -1	# decrease address
    j Loop2			# jump to label loop2
End2:
    bge $t0, $t2, Palindrome2	# if loop variable >= length, palindrome
    move $a0, $zero	# register a0 = 0
    li $v0, 1		# print int
    syscall
    li $v0, 10		# exit
    syscall
Palindrome2:
    li $a0, 1		# register a0 = 1
    li $v0, 1		# print int
    syscall
    li $v0, 10		# exit
    syscall