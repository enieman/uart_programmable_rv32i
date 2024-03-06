\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   // #################################################################
   // #                                                               #
   // #  Custom RISC-V CPU Implementation                             #
   // #                                                               #
   // #################################################################
   
\TLV cpu_custom(|_cpu, #_IMEM_NUM_ADDR_BITS, #_DMEM_NUM_ADDR_BITS, $_reset, $_imem_rd_en, $_imem_rd_addr, $_imem_rd_data, $_dmem_rd_en, $_dmem_wr_en, $_dmem_addr, $_dmem_wr_byte_en, $_dmem_rd_data, $_dmem_wr_data)
   |_cpu
      @0 // Instruction Fetch, PC Select
         $reset = $_reset;
         $pc[31:0] =
            $reset             ? 32'h0000_0000 :
            >>1$reset          ? 32'h0000_0000 :
            >>3$valid_tgt_pc   ? >>3$tgt_pc :
            >>3$valid_load     ? >>3$inc_pc :
                                 >>1$inc_pc;
         $_imem_rd_en = ! ($reset);
         $_imem_rd_addr[m5_calc((#_IMEM_NUM_ADDR_BITS)-1):0] = $pc[m5_calc((#_IMEM_NUM_ADDR_BITS)+1):2];
         
      @1 // Instruction Decode, PC Increment
         $instr[31:0] = $_imem_rd_data[31:0];
         $inc_pc[31:0] = $pc + 32'h4;
         
         // Instruction Fields
         $opcode[6:0] = $instr[6:0];
         $funct3[2:0] = $instr[14:12];
         $funct7[6:0] = $instr[31:25];
         $rd[4:0] = $instr[11:7];
         $rs1[4:0] = $instr[19:15];
         $rs2[4:0] = $instr[24:20];
         $imm[31:0] =
            $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:7]} :
            $is_b_instr ? {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} :
            $is_u_instr ? {$instr[31:12], {12{1'b0}}} :
            $is_j_instr ? {{12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:25], $instr[24:21], 1'b0} :
            //default to I-type format for simplicity
                          {{21{$instr[31]}}, $instr[30:20]};
         
         // Instruction Set
         $is_lui   = $opcode == 7'b0110111;
         $is_auipc = $opcode == 7'b0010111;
         $is_jal   = $opcode == 7'b1101111;
         $is_jalr  = {$funct3, $opcode} == 10'b000_1100111;
         $is_beq   = {$funct3, $opcode} == 10'b000_1100011;
         $is_bne   = {$funct3, $opcode} == 10'b001_1100011;
         $is_blt   = {$funct3, $opcode} == 10'b100_1100011;
         $is_bge   = {$funct3, $opcode} == 10'b101_1100011;
         $is_bltu  = {$funct3, $opcode} == 10'b110_1100011;
         $is_bgeu  = {$funct3, $opcode} == 10'b111_1100011;
         $is_lb    = {$funct3, $opcode} == 10'b000_0000011;
         $is_lh    = {$funct3, $opcode} == 10'b001_0000011;
         $is_lw    = {$funct3, $opcode} == 10'b010_0000011;
         $is_lbu   = {$funct3, $opcode} == 10'b100_0000011;
         $is_lhu   = {$funct3, $opcode} == 10'b101_0000011;
         $is_sb    = {$funct3, $opcode} == 10'b000_0100011;
         $is_sh    = {$funct3, $opcode} == 10'b001_0100011;
         $is_sw    = {$funct3, $opcode} == 10'b010_0100011;
         $is_addi  = {$funct3, $opcode} == 10'b000_0010011;
         $is_slti  = {$funct3, $opcode} == 10'b010_0010011;
         $is_sltiu = {$funct3, $opcode} == 10'b011_0010011;
         $is_xori  = {$funct3, $opcode} == 10'b100_0010011;
         $is_ori   = {$funct3, $opcode} == 10'b110_0010011;
         $is_andi  = {$funct3, $opcode} == 10'b111_0010011;
         $is_slli  = {$funct7, $funct3, $opcode} == 17'b0000000_001_0010011;
         $is_srli  = {$funct7, $funct3, $opcode} == 17'b0000000_101_0010011;
         $is_srai  = {$funct7, $funct3, $opcode} == 17'b0100000_101_0010011;
         $is_add   = {$funct7, $funct3, $opcode} == 17'b0000000_000_0110011;
         $is_sub   = {$funct7, $funct3, $opcode} == 17'b0100000_000_0110011;
         $is_sll   = {$funct7, $funct3, $opcode} == 17'b0000000_001_0110011;
         $is_slt   = {$funct7, $funct3, $opcode} == 17'b0000000_010_0110011;
         $is_sltu  = {$funct7, $funct3, $opcode} == 17'b0000000_011_0110011;
         $is_xor   = {$funct7, $funct3, $opcode} == 17'b0000000_100_0110011;
         $is_srl   = {$funct7, $funct3, $opcode} == 17'b0000000_101_0110011;
         $is_sra   = {$funct7, $funct3, $opcode} == 17'b0100000_101_0110011;
         $is_or    = {$funct7, $funct3, $opcode} == 17'b0000000_110_0110011;
         $is_and   = {$funct7, $funct3, $opcode} == 17'b0000000_111_0110011;
         
         // Instruction Categories
         $is_load    = $is_lb | $is_lh | $is_lw | $is_lbu | $is_lhu;
         $is_store   = $is_sb | $is_sh | $is_sw;
         $is_jump    = $is_jal  | $is_jalr;
         $is_add_op  = $is_add  | $is_addi | $is_auipc | $is_jump | $is_load | $is_store;
         $is_and_op  = $is_and  | $is_andi;
         $is_or_op   = $is_or   | $is_ori;
         $is_sll_op  = $is_sll  | $is_slli;
         $is_slt_op  = $is_slt  | $is_slti  | $is_blt  | $is_bge;
         $is_sltu_op = $is_sltu | $is_sltiu | $is_bltu | $is_bgeu;
         $is_sra_op  = $is_sra  | $is_srai;
         $is_srl_op  = $is_srl  | $is_srli;
         $is_xor_op  = $is_xor  | $is_xori;
         
         // Instruction Types
         $is_r_instr = $is_add | $is_sub | $is_sll | $is_slt | $is_sltu | $is_xor | $is_srl | $is_sra | $is_or | $is_and;
         $is_i_instr = $is_jalr | $is_load | $is_addi | $is_slti | $is_sltiu | $is_xori | $is_ori | $is_andi | $is_slli | $is_srli | $is_srai;
         $is_s_instr = $is_store;
         $is_b_instr = $is_beq | $is_bne | $is_blt | $is_bge | $is_bltu | $is_bgeu;
         $is_u_instr = $is_lui | $is_auipc;
         $is_j_instr = $is_jal;
         
         // Validity
         $rd_valid    = !$reset & ($is_r_instr | $is_i_instr | $is_u_instr | $is_j_instr);
         $rs1_valid   = !$reset & ($is_r_instr | $is_i_instr | $is_s_instr | $is_b_instr);
         $rs2_valid   = !$reset & ($is_r_instr | $is_s_instr | $is_b_instr);
         
      @2 // Operand Selection
         $rf_rd_en1 = $rs1_valid;
         $rf_rd_en2 = $rs2_valid;
         $rf_rd_index1[4:0] = $rs1;
         $rf_rd_index2[4:0] = $rs2;
         
         $src1_value[31:0] = (>>1$rf_wr_en && (>>1$rf_wr_index == $rf_rd_index1)) ? >>1$rf_wr_data : $rf_rd_data1;
         $src2_value[31:0] = (>>1$rf_wr_en && (>>1$rf_wr_index == $rf_rd_index2)) ? >>1$rf_wr_data : $rf_rd_data2;
         
         $alu_op1[31:0] =
            $is_auipc | $is_jump ? $pc :
                                   $src1_value;
         $alu_op2[31:0] =
            $is_r_instr || $is_b_instr ? $src2_value :
            $is_jump                   ? 32'h0000_0004 :
                                         $imm;
         
         $tgt_pc_op1[31:0] = $is_jalr ? $src1_value : $pc;
         $tgt_pc_op2[31:0] = $imm;
         
      @3 // Execute, Register Write
         $valid = !$reset && !(>>1$valid_taken_br || >>2$valid_taken_br || >>1$valid_load || >>2$valid_load || >>1$valid_jump || >>2$valid_jump);
         $valid_load  = $is_load  && $valid;
         $valid_store = $is_store && $valid;
         $valid_jump  = $is_jump  && $valid;
         $valid_taken_br =
            !$valid  ? 1'b0 :
            $is_beq  ? $alu_op1 == $alu_op2 :
            $is_bne  ? $alu_op1 != $alu_op2 :
            $is_bltu ? $result[0] :
            $is_bgeu ? !$result[0] :
            $is_blt  ? $result[0] :
            $is_bge  ? !$result[0] :
                       1'b0;
         $valid_tgt_pc = $valid_taken_br | $valid_jump;
         
         // Target PC Adder
         $tgt_pc[31:0] = $tgt_pc_op1 + $tgt_pc_op2;
         
         // ALU
         $sra_result[63:0] = { {32{$alu_op1[31]}}, $alu_op1} >> $alu_op2[4:0];
         $sltu_result[31:0] = $alu_op1 < $alu_op2 ? 32'h0000_0001 : 32'h0000_0000;
         $result[31:0] =
            $is_add_op  ? $alu_op1 + $alu_op2 :
            $is_and_op  ? $alu_op1 & $alu_op2 :
            $is_lui     ? {$alu_op2[31:12], 12'h000} :
            $is_or_op   ? $alu_op1 | $alu_op2 :
            $is_sll_op  ? $alu_op1 << $alu_op2[4:0] :
            $is_slt_op  ? (($alu_op1[31] == $alu_op2[31]) ? $sltu_result : ($alu_op1[31] == 1'b1 ? 32'h0000_0001 : 32'h0000_0000)) :
            $is_sltu_op ? $sltu_result :
            $is_sra_op  ? $sra_result[31:0] :
            $is_srl_op  ? $alu_op1 >> $alu_op2[4:0] :
            $is_sub     ? $alu_op1 - $alu_op2 :
            $is_xor_op  ? $alu_op1 ^ $alu_op2 :
                          32'hxxxx_xxxx;
         
         // Register Write
         $rf_wr_en = ($valid && $rd_valid && ($rd != 5'h00) && !$valid_load) || >>2$valid_load;
         $rf_wr_index[4:0] = $valid ? $rd : >>2$rd;
         $rf_wr_data[31:0] = $valid ? $result : >>2$ld_data;
         
      @4 // Data Memory Write
         $_dmem_rd_en = $valid_load;
         $_dmem_wr_en = $valid_store;
         $_dmem_addr[m5_calc((#_DMEM_NUM_ADDR_BITS)-1):0] = $result[m5_calc((#_DMEM_NUM_ADDR_BITS)+1):2];
         $_dmem_wr_byte_en[3:0] = 4'b1111; // Just implement LW/SW for now
         $_dmem_wr_data[31:0] = $src2_value;
         
      @5 // Data Memory Read
         $ld_data[31:0] = $_dmem_rd_data[31:0];
