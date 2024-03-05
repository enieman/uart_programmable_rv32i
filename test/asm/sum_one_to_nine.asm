reset:
add x10, x0, x0             # Initialize r10 (a0) to 0.
# Function:
add x14, x10, x0            # Initialize sum register a4 with 0x0
addi x12, x10, 10           # Store count of 10 in register a2.
add x13, x10, x0            # Initialize intermediate sum register a3 with 0
loop:
add x14, x13, x14           # Incremental addition
addi x13, x13, 1            # Increment count register by 1
blt x13, x12, loop          # If a3 is less than a2, branch to label named <loop>
done:
add x10, x14, x0            # Store final result to register a0 so that it can be read by main program
sw x10, 4(x0)
add x0, x0, x0
add x0, x0, x0
add x0, x0, x0
add x0, x0, x0
add x0, x0, x0
add x0, x0, x0
add x0, x0, x0
