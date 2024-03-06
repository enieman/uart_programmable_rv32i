reset:
   addi x1, x0, -5
   addi x2, x0, 5
   addi x3, x0, -1
   addi x4, x0, -5
bne_loop:
   addi x1, x1, 1
   addi x2, x2, -1
   bne  x2, x0, bne_loop
   bne  x1, x0, bne_loop
beq_loop:
   addi x3, x3, 1
   beq  x3, x0, beq_loop
blt_loop:
   addi x4, x4, 1
   blt  x4, x0, blt_loop
store:
   sw   x1,  0(x0) # x1 = 0
   sw   x2,  4(x0) # x2 = 0
   sw   x3,  8(x0) # x3 = 1
   sw   x4, 12(x0) # x4 = 0
