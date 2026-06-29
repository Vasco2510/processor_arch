# **Apéndice B: Extensión de Instrucciones Comprimidas RISC-V (RVC \- 16 bits)**

Este documento contiene la especificación de formatos y el catálogo de instrucciones comprimidas de 16 bits (RVC) de acuerdo con el estándar de arquitectura de computadores RISC-V.

## **Figura B.2: Formatos de Instrucción Comprimidos (16-bit RISC-V)**

A diferencia de las instrucciones estándar de 32 bits, los formatos comprimidos tienen longitudes y distribuciones de campos muy variadas para maximizar la densidad de código. A continuación se detallan los formatos según la distribución de sus 16 bits (del bit 15 al 0):

| Formato | 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **CR-Type** | funct4 | rd / rs1 | rs2 | op |  |  |  |  |  |  |  |  |  |  |  |  |
| **CI-Type** | funct3 | imm\[5\] | rd / rs1 | imm\[4:0\] | op |  |  |  |  |  |  |  |  |  |  |  |
| **CSS-Type** | funct3 | imm\[5:0\] | rs2 | op |  |  |  |  |  |  |  |  |  |  |  |  |
| **CIW-Type** | funct3 | imm\[7:0\] | rd' | op |  |  |  |  |  |  |  |  |  |  |  |  |
| **CL-Type** | funct3 | imm | rs1' | imm | rd' | op |  |  |  |  |  |  |  |  |  |  |
| **CS-Type** | funct3 | imm | rs1' | imm | rs2' | op |  |  |  |  |  |  |  |  |  |  |
| **CA-Type** | funct6 | rd' / rs1' | funct2 | rs2' | op |  |  |  |  |  |  |  |  |  |  |  |
| **CB-Type** | funct3 | offset | rs1' | offset | op |  |  |  |  |  |  |  |  |  |  |  |
| **CJ-Type** | funct3 | jump target | op |  |  |  |  |  |  |  |  |  |  |  |  |  |

### **Notas sobre los registros abreviados:**

* Los campos denominados con comilla (rd', rs1', rs2') corresponden a un subconjunto de 3 bits de direccionamiento de registros.  
* Estos mapas se traducen directamente a los registros físicos **x8 a x15** (los registros más comunes de uso temporal y guardados: s0-s1, a0-a5).

## **Tabla B.6: Instrucciones Comprimidas RVC (16 bits)**

La siguiente tabla describe la decodificación de las instrucciones comprimidas de 16 bits basadas en el cuadrante de codificación (op), los bits de función y su equivalencia exacta en la arquitectura estándar de 32 bits (RV32I / RV32F).

| op | instr\[15:10\] | funct2 | Type | RVC Instruction | 32-Bit Equivalent |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **00** | 000--- | — | CIW | c.addi4spn rd', imm | addi rd', sp, ZeroExt(imm) |
| **00** | 001--- | — | CL | c.fld fd', imm(rs1') | fld fd', (ZeroExt(imm))(rs1') |
| **00** | 010--- | — | CL | c.lw rd', imm(rs1') | lw rd', (ZeroExt(imm))(rs1') |
| **00** | 011--- | — | CL | c.flw fd', imm(rs1') | flw fd', (ZeroExt(imm))(rs1') |
| **00** | 101--- | — | CS | c.fsd fs2', imm(rs1') | fsd fs2', (ZeroExt(imm))(rs1') |
| **00** | 110--- | — | CS | c.sw rs2', imm(rs1') | sw rs2', (ZeroExt(imm))(rs1') |
| **00** | 111--- | — | CS | c.fsw fs2', imm(rs1') | fsw fs2', (ZeroExt(imm))(rs1') |
| **01** | 000000 | — | CI | c.nop *(rs1=0, imm=0)* | nop |
| **01** | 000--- | — | CI | c.addi rd, imm | addi rd, rd, SignExt(imm) |
| **01** | 001--- | — | CJ | c.jal offset | jal ra, SignExt(offset) |
| **01** | 010--- | — | CI | c.li rd, imm | addi rd, x0, SignExt(imm) |
| **01** | 011--- | — | CI | c.lui rd, imm *(rd \!= 2\)* | lui rd, SignExt(imm) |
| **01** | 011--- | — | CI | c.addi16sp sp, imm *(rd \= 2\)* | addi sp, sp, SignExt(imm) |
| **01** | 100-00 | — | CB | c.srli rd', shamt | srli rd', rd', shamt |
| **01** | 100-01 | — | CB | c.srai rd', shamt | srai rd', rd', shamt |
| **01** | 100-10 | — | CB | c.andi rd', imm | andi rd', rd', SignExt(imm) |
| **01** | 100011 | 00 | CA | c.sub rd', rs2' | sub rd', rd', rs2' |
| **01** | 100011 | 01 | CA | c.xor rd', rs2' | xor rd', rd', rs2' |
| **01** | 100011 | 10 | CA | c.or rd', rs2' | or rd', rd', rs2' |
| **01** | 100011 | 11 | CA | c.and rd', rs2' | and rd', rd', rs2' |
| **01** | 101--- | — | CJ | c.j offset | jal x0, SignExt(offset) |
| **01** | 110--- | — | CB | c.beqz rs1', offset | beq rs1', x0, SignExt(offset) |
| **01** | 111--- | — | CB | c.bnez rs1', offset | bne rs1', x0, SignExt(offset) |
| **10** | 000--- | — | CI | c.slli rd, shamt | slli rd, rd, shamt |
| **10** | 001--- | — | CI | c.fldsp fd, imm | fld fd, (ZeroExt(imm))(sp) |
| **10** | 010--- | — | CI | c.lwsp rd, imm | lw rd, (ZeroExt(imm))(sp) |
| **10** | 011--- | — | CI | c.flwsp fd, imm | flw fd, (ZeroExt(imm))(sp) |
| **10** | 1000-- | — | CR | c.jr rs1 *(rs1 \!= 0\)* | jalr x0, 0(rs1) |
| **10** | 1000-- | — | CR | c.mv rd, rs2 *(rs2 \!= 0\)* | add rd, x0, rs2 |
| **10** | 1001-- | — | CR | c.ebreak *(rs1=0, rs2=0)* | ebreak |
| **10** | 1001-- | — | CR | c.jalr rs1 *(rs1 \!= 0\)* | jalr ra, 0(rs1) |
| **10** | 1001-- | — | CR | c.add rd, rs2 *(rs2 \!= 0\)* | add rd, rd, rs2 |
| **10** | 101--- | — | CSS | c.fsdsp fs2, imm | fsd fs2, (ZeroExt(imm))(sp) |
| **10** | 110--- | — | CSS | c.swsp rs2, imm | sw rs2, (ZeroExt(imm))(sp) |
| **10** | 111--- | — | CSS | c.fswsp fs2, imm | fsw fs2, (ZeroExt(imm))(sp) |

### **Leyenda de operaciones de inmediato:**

* **SignExt(imm)**: Extensión de signo del inmediato (preserva el bit más significativo en la extensión de bits).  
* **ZeroExt(imm)**: Extensión de ceros del inmediato (rellena con bits en 0).