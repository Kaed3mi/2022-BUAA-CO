.macro show_cnt
lw _aluout,  0x7F08($0) #读取现在的计数数
andi _cntop, _button, 4 #0为正序，1为倒序
bne _cntop, $0, down
nop
sub _aluout, _srcA, _aluout
sw _aluout, 0x7f50($0) #展示
j timer_start
nop
down:
sw _aluout, 0x7f50($0) #展示
j timer_start
nop
.end_macro

.macro check
lb _tmp, 0x7F68($0) #user_key
bne _tmp, _button, main		#restart
nop
lw _tmp, 0x7f60($0) 	#srcA
bne _tmp, _srcA, main 		#重新读取初始值
nop
.end_macro


.eqv _button, $2
.eqv _cal $3
.eqv _aluop $4
.eqv _aluout $5
.eqv _init_value, $6
.eqv _tmp, $7
.eqv _cntop $16
.eqv _srcA, $t0
.eqv _srcB, $t1
main:
lb _button, 0x7F68($0)
andi _cal, _button, 1		#是否进入计算器模式
bne _cal, $0, timer
nop


#计算器模式
calculator:
lb _button, 0x7F68($0)
lw _srcA, 0x7f60($0)
lw _srcB, 0x7f64($0)
check
andi _aluop, _button, 4
bne _aluop, $0, Add
nop
andi _aluop, _button, 8
bne _aluop, $0, Sub
nop
andi _aluop, _button, 16
bne _aluop, $0, Mult
nop
andi _aluop, _button, 32
bne _aluop, $0, Div
nop
andi _aluop, _button, 64
bne _aluop, $0, And
nop
andi _aluop, _button, 128
bne _aluop, $0, Or
nop



#计时器模式
timer:
lb _button, 0x7F68($0)

sw $0,  0x7F00($0)		#停止计数
lw _srcA, 0x7f60($0) 	#从输入读取初始值
sw _srcA, 0x7F04($0)	#设置初始值
ori _tmp, $0, 1
sw _tmp,  0x7F00($0)	#开始计数
j timer_start
nop

timer_start:
#退出判断
check

show_cnt


#计算器功能:
Or:
or _aluout, _srcA, _srcB
sw _aluout, 0x7f50($0)
j calculator
nop
And:
and _aluout, _srcA, _srcB
sw _aluout, 0x7f50($0)
j calculator
nop
Div:
div _srcA, _srcB
mflo _aluout
sw _aluout, 0x7f50($0)
j calculator
nop
Mult:
mult _srcA, _srcB
mflo _aluout
sw _aluout, 0x7f50($0)
j calculator
nop
Sub:
sub _aluout, _srcA, _srcB
sw _aluout, 0x7f50($0)
j calculator
nop
Add:
add _aluout, _srcA, _srcB
sw _aluout, 0x7f50($0)
j calculator
nop
