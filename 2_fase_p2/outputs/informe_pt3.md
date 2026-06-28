# Informe de Encodings — Instrucciones Implementadas (Partes 1 y 2)

## 1. Instrucciones RV32I Base (Parte 1)

### 1.1 R-type (opcode = `0110011`)

| Instrucción | funct7 | rs2 | rs1 | funct3 | rd | opcode |
|------------|--------|-----|-----|--------|----|--------|
| ADD | `0000000` | `xxxxx` | `xxxxx` | `000` | `xxxxx` | `0110011` |
| SUB | `0100000` | `xxxxx` | `xxxxx` | `000` | `xxxxx` | `0110011` |
| SLL | `0000000` | `xxxxx` | `xxxxx` | `001` | `xxxxx` | `0110011` |
| SLT | `0000000` | `xxxxx` | `xxxxx` | `010` | `xxxxx` | `0110011` |
| XOR | `0000000` | `xxxxx` | `xxxxx` | `100` | `xxxxx` | `0110011` |
| SRL | `0000000` | `xxxxx` | `xxxxx` | `101` | `xxxxx` | `0110011` |
| SRA | `0100000` | `xxxxx` | `xxxxx` | `101` | `xxxxx` | `0110011` |
| OR | `0000000` | `xxxxx` | `xxxxx` | `110` | `xxxxx` | `0110011` |
| AND | `0000000` | `xxxxx` | `xxxxx` | `111` | `xxxxx` | `0110011` |

### 1.2 I-type (opcode = `0010011`)

| Instrucción | imm[11:0] | rs1 | funct3 | rd | opcode |
|------------|-----------|-----|--------|----|--------|
| ADDI | `xxxxxxxxxxxx` | `xxxxx` | `000` | `xxxxx` | `0010011` |
| SLTI | `xxxxxxxxxxxx` | `xxxxx` | `010` | `xxxxx` | `0010011` |
| XORI | `xxxxxxxxxxxx` | `xxxxx` | `100` | `xxxxx` | `0010011` |
| ORI | `xxxxxxxxxxxx` | `xxxxx` | `110` | `xxxxx` | `0010011` |
| ANDI | `xxxxxxxxxxxx` | `xxxxx` | `111` | `xxxxx` | `0010011` |
| SLLI | `0000000xxxxx` | `xxxxx` | `001` | `xxxxx` | `0010011` |
| SRLI | `0000000xxxxx` | `xxxxx` | `101` | `xxxxx` | `0010011` |
| SRAI | `0100000xxxxx` | `xxxxx` | `101` | `xxxxx` | `0010011` |

### 1.3 Load (opcode = `0000011`)

| Instrucción | imm[11:0] | rs1 | funct3 | rd | opcode |
|------------|-----------|-----|--------|----|--------|
| LW | `xxxxxxxxxxxx` | `xxxxx` | `010` | `xxxxx` | `0000011` |

### 1.4 Store S-type (opcode = `0100011`)

| Instrucción | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
|------------|-----------|-----|-----|--------|----------|--------|
| SW | `xxxxxxx` | `xxxxx` | `xxxxx` | `010` | `xxxxx` | `0100011` |

### 1.5 Branch B-type (opcode = `1100011`)

| Instrucción | imm[12,10:5] | rs2 | rs1 | funct3 | imm[4:1,11] | opcode |
|------------|-------------|-----|-----|--------|-------------|--------|
| **BEQ** | `xxxxxxx` | `xxxxx` | `xxxxx` | `000` | `xxxxx` | `1100011` |
| **BNE** | `xxxxxxx` | `xxxxx` | `xxxxx` | `001` | `xxxxx` | `1100011` |
| **BLT** | `xxxxxxx` | `xxxxx` | `xxxxx` | `100` | `xxxxx` | `1100011` |
| **BGE** | `xxxxxxx` | `xxxxx` | `xxxxx` | `101` | `xxxxx` | `1100011` |

### 1.6 Jal J-type (opcode = `1101111`)

| Instrucción | imm[20,10:1,11,19:12] | rd | opcode |
|------------|----------------------|----|--------|
| JAL | `xxxxxxxxxxxxxxxxxxxx` | `xxxxx` | `1101111` |

### 1.7 Jalr I-type (opcode = `1100111`)

| Instrucción | imm[11:0] | rs1 | funct3 | rd | opcode |
|------------|-----------|-----|--------|----|--------|
| JALR | `000000000000` | `xxxxx` | `000` | `xxxxx` | `1100111` |

### 1.8 LUI U-type (opcode = `0110111`)

| Instrucción | imm[31:12] | rd | opcode |
|------------|-----------|----|--------|
| LUI | `xxxxxxxxxxxxxxxxxxxx` | `xxxxx` | `0110111` |

---

## 2. Instrucciones RVC (Parte 2)

### 2.1 Instrucciones de 16 bits — Formato general

Todas las instrucciones RVC se identifican por `inst[1:0] ≠ 2'b11`.

### 2.2 Cuadrante Q0 (`inst[1:0] = 2'b00`) — Loads/Stores a registros comprimidos (x8–x15)

#### C.LW (funct3 = `010`)

| 15-13 | 12 | 11-10 | 9-7 | 6 | 5 | 4-2 | 1-0 |
|-------|----|-------|-----|----|---|-----|-----|
| `010` | offset[5] | offset[3:2] | rs1' | offset[6] | offset[4:4] | rd' | `00` |

- **Expande a:** `lw rd', offset(rs1')`
- **Campos:** rd' = `{01, inst[4:2]}`, rs1' = `{01, inst[9:7]}`

#### C.SW (funct3 = `110`)

| 15-13 | 12 | 11-10 | 9-7 | 6 | 5 | 4-2 | 1-0 |
|-------|----|-------|-----|----|---|-----|-----|
| `110` | offset[5] | offset[3:2] | rs1' | offset[6] | offset[4:4] | rs2' | `00` |

- **Expande a:** `sw rs2', offset(rs1')`

### 2.3 Cuadrante Q1 (`inst[1:0] = 2'b01`) — ALU / Saltos / Branches

#### C.ADDI (funct3 = `000`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `000` | imm[5] | rd | imm[4:0] | `01` |

- **Expande a:** `addi rd, rd, sign_ext(imm[5:0])`

#### C.JAL (funct3 = `001`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `001` | imm[4] | imm[3] / imm[9:8] / imm[10] / imm[6] / imm[7] / imm[2] / imm[1] / imm[5] | `01` |

- **Formato imm:** `imm[11|4|9:8|10|6|7|3:1|5|5:0|0]` (? - en realidad es un encoding disperso)
- **Expande a:** `jal x1, offset`
- **Encoding del offset:** `{inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3], {8{inst[12]}}}`

#### C.LUI (funct3 = `011`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `011` | imm[17] | rd | imm[16:12] | `01` |

- **Expande a:** `lui rd, {imm[17:12], 12'b0}`
- **Nota:** Si rd = x2, corresponde a C.ADDI16SP (no implementado con semántica correcta)

#### C.SRLI (funct3 = `100`, funct2 = `00`)

| 15-13 | 12 | 11-10 | 9-7 | 6-2 | 1-0 |
|-------|----|-------|-----|-----|-----|
| `100` | `0` | `00` | rs1' | shamt[4:0] | `01` |

- **Expande a:** `srli rs1', rs1', shamt`

#### C.SRAI (funct3 = `100`, funct2 = `01`)

| 15-13 | 12 | 11-10 | 9-7 | 6-2 | 1-0 |
|-------|----|-------|-----|-----|-----|
| `100` | `1` | `01` | rs1' | shamt[4:0] | `01` |

- **Expande a:** `srai rs1', rs1', shamt`

#### C.ANDI (funct3 = `100`, funct2 = `10`)

| 15-13 | 12 | 11-10 | 9-7 | 6-2 | 1-0 |
|-------|----|-------|-----|-----|-----|
| `100` | imm[5] | `10` | rs1' | imm[4:0] | `01` |

- **Expande a:** `andi rs1', rs1', sign_ext(imm[5:0])`

#### C.SUB / C.XOR / C.OR / C.AND (funct3 = `100`, funct2 = `11`)

| 15-13 | 12 | 11-10 | 9-7 | 6-5 | 4-2 | 1-0 |
|-------|----|-------|-----|-----|-----|-----|
| `100` | `0` | `11` | rs1' | funct | rs2' | `01` |

| funct (`inst[6:5]`) | Instrucción | Expansión |
|---------------------|-------------|-----------|
| `00` | C.SUB | `sub rs1', rs1', rs2'` |
| `01` | C.XOR | `xor rs1', rs1', rs2'` |
| `10` | C.OR | `or rs1', rs1', rs2'` |
| `11` | C.AND | `and rs1', rs1', rs2'` |

#### C.J (funct3 = `101`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `101` | imm[4] | imm[3] / imm[9:8] / imm[10] / imm[6] / imm[7] / imm[2] / imm[1] / imm[5] | `01` |

- **Expande a:** `jal x0, offset`

#### C.BEQZ (funct3 = `110`)

| 15-13 | 12 | 11-10 | 9-7 | 6-5 | 4-3 | 2 | 1-0 |
|-------|----|-------|-----|-----|-----|----|-----|
| `110` | imm[5] | imm[2:1] | rs1' | imm[4:3] | imm[7:6] | imm[8] | `01` |

- **Expande a:** `beq rs1', x0, offset`

#### C.BNEZ (funct3 = `111`)

| 15-13 | 12 | 11-10 | 9-7 | 6-5 | 4-3 | 2 | 1-0 |
|-------|----|-------|-----|-----|-----|----|-----|
| `111` | imm[5] | imm[2:1] | rs1' | imm[4:3] | imm[7:6] | imm[8] | `01` |

- **Expande a:** `bne rs1', x0, offset`

### 2.4 Cuadrante Q2 (`inst[1:0] = 2'b10`) — Stack-pointer relativas / Misc

#### C.SLLI (funct3 = `000`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `000` | `0` | rd | shamt[4:0] | `10` |

- **Expande a:** `slli rd, rd, shamt`

#### C.LWSP (funct3 = `010`)

| 15-13 | 12 | 11-7 | 6-4 | 3-2 | 1-0 |
|-------|----|------|-----|-----|-----|
| `010` | offset[4] | rd | offset[5] | offset[7:6] | `10` |

- **Expande a:** `lw rd, offset(x2)`
- **Offset:** `{offset[7:4], 2'b00}`

#### C.JR (funct3 = `100`, bit12 = `0`, rs2 = `0`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `100` | `0` | rs1 | `00000` | `10` |

- **Expande a:** `jalr x0, rs1, 0`

#### C.MV (funct3 = `100`, bit12 = `0`, rs2 ≠ `0`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `100` | `0` | rd | rs2 | `10` |

- **Expande a:** `add rd, x0, rs2`

#### C.JALR (funct3 = `100`, bit12 = `1`, rs2 = `0`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `100` | `1` | rs1 | `00000` | `10` |

- **Expande a:** `jalr x1, rs1, 0`

#### C.ADD (funct3 = `100`, bit12 = `1`, rs2 ≠ `0`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `100` | `1` | rd | rs2 | `10` |

- **Expande a:** `add rd, rd, rs2`

#### C.SWSP (funct3 = `110`)

| 15-13 | 12 | 11-7 | 6-2 | 1-0 |
|-------|----|------|-----|-----|
| `110` | offset[2] | rs2 | offset[5:3] | `10` |

- **Expande a:** `sw rs2, offset(x2)`
- **Offset:** `{offset[5:2], 2'b00}`

---

## 3. Resumen del Pipeline implementado

| Etapa | Módulo | Función |
|-------|--------|---------|
| **IF** | `if_stage.v` | Fetch de 32 bits desde `imem.v`, decompresión RVC, PC +2/+4 |
| **IF/ID** | Pipeline register | Registro pipeline entre IF e ID |
| **ID** | `id_stage.v` | Lectura de `regfile.v`, extensión de inmediatos (`extend.v`), envío a `controller_pipe.v` |
| **ID/EX** | Pipeline register | Registro pipeline entre ID y EX |
| **EX** | `ex_stage.v` | ALU (`alu.v`), sumador de branches (`adder.v`), detección de condición de branch, lógica de salto |
| **EX/MEM** | Pipeline register | Registro pipeline entre EX y MEM |
| **MEM** | `mem_stage.v` | Acceso a `dmem.v` (lectura/escritura de datos) |
| **MEM/WB** | Pipeline register | Registro pipeline entre MEM y WB |
| **WB** | `wb_stage.v` | Selección del resultado a escribir en el banco de registros |

### Control y Hazard

| Módulo | Propósito |
|--------|-----------|
| `maindec.v` | Decodificador principal (señales de control por opcode) |
| `aludec.v` | Decodificador de la ALU (ALUControl según funct3/funct7) |
| `controller_pipe.v` | Conexión entre maindec y aludec |
| `hazard_unit.v` | Forwarding (adelantamiento), stalls (carga-uso) y flushes (saltos/branches) |
