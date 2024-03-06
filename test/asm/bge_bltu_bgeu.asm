reset:
   addi x1, x0, -5
   addi x2, x0, -5
   addi x3, x0, -5
   addi x4, x0, 1
bge_loop:
   addi x1, x1, 1
   bge  x0, x1, bge_loop
bltu_loop:
   addi x2, x2, 1
   bltu x0, x2, bltu_loop
bgeu_loop:
   addi x3, x3, 1
   bgeu x3, x4, bgeu_loop
store:
   sw   x1,  0(x0) # x1 = 1
   sw   x2,  4(x0) # x2 = 0
   sw   x3,  8(x0) # x3 = 0
extra:
   add  x0, x0, x0
   add  x0, x0, x0
   add  x0, x0, x0
