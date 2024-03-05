addi x3, x0, 0x44
addi x1, x0, 0x11
addi x2, x0, 0x11
addi x4, x0, 0x0
addi x5, x0, 0xC
loop1:
addi x1, x1, 0x11
slli x2, x2, 8
add  x2, x2, x1
blt  x1, x3, loop1
sw   x2, 0(x0)
loop2:
lw   x9, 0(x4)
add  x9, x9, x9
sw   x9, 4(x4)
add  x9, x0, x0
addi x4, x4, 4
blt  x4, x5, loop2

# Data[3:0]   = 0x12_23_34_40
# Data[7:4]   = 0x22_44_66_88
# Data[11:8]  = 0x44_88_CD_10
# Data[15:12] = 0x89_11_9A_20
