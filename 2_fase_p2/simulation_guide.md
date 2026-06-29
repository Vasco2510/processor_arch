# Simulation Guide — Testbenches

13 testbenches en `tb/`. Cada uno carga su propio `.mem` y verifica resultados específicos.

---

## 1. `tb_test_instrucciones` — 24 instrucciones RV32I (Cuadro 1)

- **Mem**: `mem/test_instrucciones.mem`
- **Duración**: 3000 ns
- **Verifica**: ADDI, ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLLI, SRLI, SRAI, ANDI, ORI, XORI, LUI, SW, LW, BEQ, BNE, JAL, JALR
- **PASS/FAIL**: No — solo dump de registros x1–x25. Revisar valores manualmente.
- **Señales dump**: PCF, InstrF, InstrD, ALUResultE

## 2. `tb_test_forwarding` — Forwarding (datos)

- **Mem**: `mem/test_forwarding.mem`
- **Duración**: 3000 ns
- **Verifica**: Forwarding entre EX, MEM, WB (ForwardAE, ForwardBE)
- **PASS/FAIL**: No — dump de x1,x2,x3,x4,x5,x6,x10 + señales ForwardAE/BE
- **Señales dump**: PCF, InstrD, ForwardAE, ForwardBE, ALUResultE

## 3. `tb_test_stalling` — Stalling (load-use)

- **Mem**: `mem/test_stalling.mem`
- **Duración**: 3000 ns
- **Verifica**: Stall por dependencia load-use (StallF, StallD, FlushE)
- **PASS/FAIL**: No — dump de x1,x2,x6,x7 + señales StallF/D
- **Señales dump**: PCF, InstrD, StallF, StallD, FlushE

## 4. `tb_test_flushing` — Flushing (branches)

- **Mem**: `mem/test_flushing.mem`
- **Duración**: 3000 ns
- **Verifica**: Flush en branch tomado (FlushD, FlushE, PCSrcE)
- **PASS/FAIL**: No — dump de x1,x2,x3,x4,x5,x6,x30,x31
- **Señales dump**: PCF, InstrD, FlushD, FlushE, PCSrcE

---

## 5. `tb_test_10_instrucciones` — 10 instrucciones RVC básicas

- **Mem**: `mem/test_10_instrucciones.mem`
- **Duración**: 1500 ns
- **RVC cubiertas**: c.addi, c.add, c.sub, c.and, c.or, c.xor, c.slli, c.srli, c.srai, c.lui
- **Esperado**: x8=13, x9=16, x10=5, x11=7, x12=4, x13=10, x14=2, x15=8192
- **PASS/FAIL**: Sí
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF, ALUResultE

## 6. `tb_programa_rvc1` — Programa RVC puro

- **Mem**: `mem/programa_rvc1.mem`
- **Duración**: 500 ns
- **Verifica**: Programa completo solo con instrucciones comprimidas de 16 bits
- **Esperado**: x1=19, x2=6
- **PASS/FAIL**: Sí
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF

## 7. `tb_programa_rvc2` — Programa mixto RVC + RV32I

- **Mem**: `mem/programa_rvc2.mem`
- **Duración**: 500 ns
- **Verifica**: Combinación de instrucciones de 16 y 32 bits en un mismo programa
- **Esperado**: x1=20, x2=10, x3=15
- **PASS/FAIL**: Sí
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF

## 8. `tb_test_isa_rvc` — Algoritmo mixto RV32I + RVC

- **Mem**: `mem/test_isa_rvc.mem`
- **Duración**: 1500 ns
- **Verifica**: Mezcla de instrucciones RV32I y RVC con forwarding y uso de registros altos
- **Esperado**: x8=0x10C0, x9=7, x10=10, x11=10, x12=7, x2=16
- **PASS/FAIL**: Sí
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF, ALUResultE, regs x8–x12

## 9. `tb_test_branch_rvc` — C.BEQZ / C.BNEZ

- **Mem**: `mem/test_branch_rvc.mem`
- **Duración**: 1000 ns
- **Verifica**: Saltos condicionales comprimidos (branch if zero / not zero)
- **Esperado**: x8=1, x9=0, x10=0, x11=0, x12=1
- **PASS/FAIL**: Sí
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF, PCSrcE, branchCond, PCTargetE

## 10. `tb_test_jump_rvc` — C.J / C.JAL / C.JR / C.JALR

- **Mem**: `mem/test_jump_rvc.mem`
- **Duración**: 1000 ns
- **Verifica**: Saltos incondicionales comprimidos (jump, jump-and-link, jump-register)
- **Esperado**: x8=5, x9=10, x10=20
- **PASS/FAIL**: Sí
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF, PCSrcE, RdE, ALUResultE, PCTargetE, PCJalrE

## 11. `tb_test_ls_rvc` — C.LW / C.SW / C.LWSP / C.SWSP

- **Mem**: `mem/test_ls_rvc.mem`
- **Duración**: 1000 ns
- **Verifica**: Load/store comprimidos (acceso a memoria con registros x8–x15 y sp)
- **Esperado**: x8=16, x9=7, x10=7, x11=7, x2=16
- **PASS/FAIL**: Sí
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF, ALUResultE, regs x8–x11

## 12. `tb_test_clw_csw` — C.LW / C.SW focused (_p mapping)

- **Mem**: `mem/test_clw_csw.mem`
- **Duración**: 1000 ns
- **Verifica**: C.LW y C.SW (Quadrant 0) con mapeo `rd_p` / `rs1_p` (x8–x15): offsets 0, 8, 20; rd_p = x10, x11, x12, x13; rs1_p = x8
- **PASS/FAIL**: No — dump de x8–x13 para revisión manual
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF, ALUResultE, regs x8–x13

## 13. `tb_test_sp_rvc` — C.LWSP / C.SWSP (SP-relative)

- **Mem**: `mem/test_sp_rvc.mem`
- **Duración**: 1000 ns
- **Verifica**: C.LWSP y C.SWSP con inyección forzada de x2 (SP): offsets 0, 4, 8, 20; rd variando (x9–x13); rs2 fijo (x8)
- **PASS/FAIL**: No — dump de x2, x8–x13 para revisión manual
- **Señales dump**: PCF, InstrF, InstrD, IsCompressedF, ALUResultE, regs x2, x8–x13

---

## Cómo probar en Vivado

1. Crear proyecto nuevo en Vivado.
2. Agregar todos los archivos de `src/` (`*.v`) como **Design Sources**.
3. Agregar el testbench deseado de `tb/` como **Simulation Source**.
4. En la ventana de Simulation → Run Simulation → Run All.
   - Si el testbench usa `$stop` o `$finish`, la simulación terminará automáticamente.
   - Duración típica: 500–3000 ns (ver arriba).
5. Para ver señales en la forma de onda:
   - Agregar señales del `dut` (Design Under Test) al waveform viewer.
   - La jerarquía del pipeline es: `dut.pipe.<etapa>`.
   - Registros: `dut.pipe.ids.rf.rf[<n>]`.
6. Para ver `$display` en la consola de Vivado → ventana Tcl Console o Messages.

### Orden recomendado de pruebas

Para validación incremental, probar en este orden:

| Paso | Testbench | Qué valida |
|------|-----------|------------|
| 1 | `tb_test_instrucciones` | RV32I base funciona |
| 2 | `tb_test_forwarding` | Forwarding correcto |
| 3 | `tb_test_stalling` | Stalling correcto |
| 4 | `tb_test_flushing` | Flushing correcto |
| 5 | `tb_test_10_instrucciones` | 10 RVC básicas |
| 6 | `tb_test_clw_csw` | C.LW / C.SW (_p mapping) |
| 7 | `tb_test_sp_rvc` | C.LWSP / C.SWSP (SP-relative) |
| 8 | `tb_test_ls_rvc` | Load/Store RVC (completo) |
| 9 | `tb_test_branch_rvc` | Branch RVC |
| 10 | `tb_test_jump_rvc` | Jump RVC |
| 11 | `tb_test_isa_rvc` | Mezcla RV32I + RVC |
| 12 | `tb_programa_rvc1` | Programa RVC puro |
| 13 | `tb_programa_rvc2` | Programa mixto |
