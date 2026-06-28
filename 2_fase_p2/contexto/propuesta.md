Adjunto lo que una IA propuso para mejorar el decompressor.v



```verilog
// decompressor.v
// Convierte instrucciones RVC de 16 bits a su equivalente de 32 bits.
// La salida es una instrucción RISC-V estándar que el pipeline procesa normalmente.
//
// Detección: instr16[1:0] != 2'b11  →  instrucción comprimida (16 bits)
//            instr16[1:0] == 2'b11  →  instrucción estándar  (32 bits, no usar este módulo)
//
// Notación de registros comprimidos (rd', rs1', rs2'): 3 bits → registros x8–x15
//   reg_full = {2'b01, reg_compressed[2:0]}

module decompressor (
    input  wire [15:0] instr16,
    output reg  [31:0] instr32,
    output wire        is_compressed
);

    // Comprimida si bits [1:0] != 11
    assign is_compressed = (instr16[1:0] != 2'b11);

    // Registros "primed" (x8-x15): campos de 3 bits expandidos a 5
    wire [4:0] rd_p  = {2'b01, instr16[4:2]};  // rd'  (CL, CA, CS)
    wire [4:0] rs1_p = {2'b01, instr16[9:7]};  // rs1' (CL, CS, CA, CB)
    wire [4:0] rs2_p = {2'b01, instr16[4:2]};  // rs2' (CS, CA) — mismo campo que rd_p

    // Registros "full" (cualquier registro): campos de 5 bits directos
    wire [4:0] rd_f  = instr16[11:7];  // rd  completo (CI, CR, CSS, CJ)
    wire [4:0] rs2_f = instr16[6:2];   // rs2 completo (CR, CSS)

    always @(*) begin
        case (instr16[1:0])

            // ================================================================
            // QUADRANT 0  (op = 00)
            // ================================================================
            2'b00: begin
                case (instr16[15:13])

                    // c.lw rd', imm(rs1')  →  lw rd', offset(rs1')
                    // CL format: offset[6]=instr[5], offset[5:3]=instr[12:10], offset[2]=instr[6]
                    // offset = { 5'b0, instr[5], instr[12:10], instr[6], 2'b00 }  (7 bits, word-aligned)
                    3'b010: begin
                        instr32 = {5'b00000, instr16[5], instr16[12:10], instr16[6], 2'b00,
                                   rs1_p, 3'b010, rd_p, 7'b0000011};
                    end

                    // c.sw rs2', imm(rs1')  →  sw rs2', offset(rs1')
                    // Mismo offset que c.lw. S-type: imm[11:5] en [31:25], imm[4:0] en [11:7]
                    // imm[11:5] = { 5'b0, instr[5], instr[12] }
                    // imm[4:0]  = { instr[11:10], instr[6], 2'b00 }
                    3'b110: begin
                        instr32 = {5'b00000, instr16[5], instr16[12],
                                   rs2_p, rs1_p, 3'b010,
                                   instr16[11:10], instr16[6], 2'b00,
                                   7'b0100011};
                    end

                    default: instr32 = 32'h00000013; // NOP seguro (addi x0, x0, 0)
                endcase
            end

            // ================================================================
            // QUADRANT 1  (op = 01)
            // ================================================================
            2'b01: begin
                case (instr16[15:13])

                    // c.addi rd, nzimm  →  addi rd, rd, nzimm
                    // CI: imm = sign_extend({ instr[12], instr[6:2] })
                    3'b000: begin
                        instr32 = {{6{instr16[12]}}, instr16[12], instr16[6:2],
                                   rd_f, 3'b000, rd_f, 7'b0010011};
                    end

                    // c.jal offset  →  jal x1, offset  (RV32C only)
                    // CJ: offset[11]=i[12], offset[4]=i[11], offset[9:8]=i[10:9],
                    //     offset[10]=i[8],  offset[6]=i[7],  offset[7]=i[6],
                    //     offset[3:1]=i[5:3], offset[5]=i[2]
                    // J-type: { imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode }
                    3'b001: begin
                        instr32 = {instr16[12],
                                   instr16[8], instr16[10:9], instr16[6],
                                   instr16[7], instr16[2], instr16[11], instr16[5:3],
                                   instr16[12],            // imm[11] -> instr32[20] (FIX)
                                   {8{instr16[12]}},
                                   5'b00001, 7'b1101111};
                    end

                    // c.lui rd, nzimm  →  lui rd, nzimm
                    // CI: nzimm[17]=i[12], nzimm[16:12]=i[6:2]
                    // U-type: instr[31:12] = nzimm[31:12]
                    3'b011: begin
                        instr32 = {{14{instr16[12]}}, instr16[12], instr16[6:2],
                                   rd_f, 7'b0110111};
                    end

                    // c.srli / c.srai / c.andi  y  c.sub/c.xor/c.or/c.and
                    3'b100: begin
                        case (instr16[11:10])

                            // c.srli rd', shamt  →  srli rd', rd', shamt
                            // shamt[4:0] = instr[6:2]  (instr[12] debe ser 0 en RV32)
                            2'b00: begin
                                instr32 = {7'b0000000, instr16[6:2],
                                           rs1_p, 3'b101, rs1_p, 7'b0010011};
                            end

                            // c.srai rd', shamt  →  srai rd', rd', shamt
                            // funct7 = 0100000 para distinguir sra de srl
                            2'b01: begin
                                instr32 = {7'b0100000, instr16[6:2],
                                           rs1_p, 3'b101, rs1_p, 7'b0010011};
                            end

                            // c.andi rd', imm  →  andi rd', rd', imm
                            // imm = sign_extend({ instr[12], instr[6:2] })
                            2'b10: begin
                                instr32 = {{6{instr16[12]}}, instr16[12], instr16[6:2],
                                           rs1_p, 3'b111, rs1_p, 7'b0010011};
                            end

                            // CA format: c.sub / c.xor / c.or / c.and
                            // Discrimina con { instr[12], instr[6:5] }
                            2'b11: begin
                                case ({instr16[12], instr16[6:5]})
                                    // c.sub rd', rs2'  →  sub rd', rd', rs2'
                                    3'b000: instr32 = {7'b0100000, rs2_p,
                                                       rs1_p, 3'b000, rs1_p, 7'b0110011};
                                    // c.xor rd', rs2'  →  xor rd', rd', rs2'
                                    3'b001: instr32 = {7'b0000000, rs2_p,
                                                       rs1_p, 3'b100, rs1_p, 7'b0110011};
                                    // c.or  rd', rs2'  →  or  rd', rd', rs2'
                                    3'b010: instr32 = {7'b0000000, rs2_p,
                                                       rs1_p, 3'b110, rs1_p, 7'b0110011};
                                    // c.and rd', rs2'  →  and rd', rd', rs2'
                                    3'b011: instr32 = {7'b0000000, rs2_p,
                                                       rs1_p, 3'b111, rs1_p, 7'b0110011};
                                    default: instr32 = 32'h00000013;
                                endcase
                            end
                        endcase
                    end

                    // c.j offset  →  jal x0, offset
                    // Mismo encoding CJ que c.jal pero rd = x0
                    3'b101: begin
                        instr32 = {instr16[12],
                                   instr16[8], instr16[10:9], instr16[6],
                                   instr16[7], instr16[2], instr16[11], instr16[5:3],
                                   instr16[12],            // imm[11] -> instr32[20] (FIX)
                                   {8{instr16[12]}},
                                   5'b00000, 7'b1101111};
                    end

                    // c.beqz rs1', offset  →  beq rs1', x0, offset
                    // CB: offset[8]=i[12], offset[4:3]=i[11:10], offset[7:6]=i[6:5],
                    //     offset[2:1]=i[4:3], offset[5]=i[2]
                    // sign extendido desde bit 8 → imm[12:9] = {4{instr[12]}}
                    // B-type: { imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], op }
                    3'b110: begin
                        instr32 = {instr16[12],
                                   instr16[12], instr16[12], instr16[12],
                                   instr16[6], instr16[5], instr16[2],
                                   5'b00000, rs1_p, 3'b000,
                                   instr16[11:10], instr16[4:3], instr16[12],
                                   7'b1100011};
                    end

                    // c.bnez rs1', offset  →  bne rs1', x0, offset
                    // Igual que c.beqz pero funct3 = 001
                    3'b111: begin
                        instr32 = {instr16[12],
                                   instr16[12], instr16[12], instr16[12],
                                   instr16[6], instr16[5], instr16[2],
                                   5'b00000, rs1_p, 3'b001,
                                   instr16[11:10], instr16[4:3], instr16[12],
                                   7'b1100011};
                    end

                    default: instr32 = 32'h00000013;
                endcase
            end

            // ================================================================
            // QUADRANT 2  (op = 10)
            // ================================================================
            2'b10: begin
                case (instr16[15:13])

                    // c.slli rd, shamt  →  slli rd, rd, shamt
                    3'b000: begin
                        instr32 = {7'b0000000, instr16[6:2],
                                   rd_f, 3'b001, rd_f, 7'b0010011};
                    end

                    // c.lwsp rd, imm(x2)  →  lw rd, offset(x2)
                    // CI: offset[5]=i[12], offset[4:2]=i[6:4], offset[7:6]=i[3:2]
                    // offset = { 4'b0, instr[3:2], instr[12], instr[6:4], 2'b00 }  (12 bits I-type)
                    3'b010: begin
                        instr32 = {4'b0000, instr16[3:2], instr16[12], instr16[6:4], 2'b00,
                                   5'b00010, 3'b010, rd_f, 7'b0000011};
                    end

                    // c.jr / c.jalr / c.add
                    3'b100: begin
                        if (!instr16[12]) begin
                            if (instr16[6:2] == 5'b00000) begin
                                // c.jr rs1  →  jalr x0, rs1, 0
                                instr32 = {12'b0, rd_f, 3'b000, 5'b00000, 7'b1100111};
                            end else begin
                                // c.mv rd, rs2  →  add rd, x0, rs2  (no en lista, NOP seguro)
                                instr32 = {7'b0000000, rs2_f, 5'b00000,
                                           3'b000, rd_f, 7'b0110011};
                            end
                        end else begin
                            if (instr16[6:2] == 5'b00000) begin
                                // c.jalr rs1  →  jalr x1, rs1, 0
                                instr32 = {12'b0, rd_f, 3'b000, 5'b00001, 7'b1100111};
                            end else begin
                                // c.add rd, rs2  →  add rd, rd, rs2
                                instr32 = {7'b0000000, rs2_f, rd_f,
                                           3'b000, rd_f, 7'b0110011};
                            end
                        end
                    end

                    // c.swsp rs2, imm(x2)  →  sw rs2, offset(x2)
                    // CSS: offset[5:2]=i[12:9], offset[7:6]=i[8:7]
                    // offset = { 4'b0, instr[8:7], instr[12:9], 2'b00 }
                    // S-type: imm[11:5] en [31:25], imm[4:0] en [11:7]
                    // imm[11:5] = { 4'b0, instr[8:7], instr[12] }
                    // imm[4:0]  = { instr[11:9], 2'b00 }
                    3'b110: begin
                        instr32 = {4'b0000, instr16[8:7], instr16[12],
                                   rs2_f, 5'b00010, 3'b010,
                                   instr16[11:9], 2'b00,
                                   7'b0100011};
                    end

                    default: instr32 = 32'h00000013;
                endcase
            end

            // 2'b11 → no debería llegar aquí (instrucción de 32 bits)
            default: instr32 = 32'h00000013;
        endcase
    end

endmodule
```