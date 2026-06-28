# Checklist de entregables — E2 (Parte 2: Extensión RVC)

> **Total:** 4 pts. Evaluación puntual de cada ítem.

---

## Código de las 10 instrucciones comprimidas

- [x] **c.addi** — Implementado en `decompressor.v` (quadrant 01, funct3=000)
- [x] **c.add** — Implementado en `decompressor.v` (quadrant 10, funct3=100, instr[12]=1)
- [x] **c.sub** — Implementado en `decompressor.v` (quadrant 01, funct3=100, {i[12],i[6:5]}=000)
- [x] **c.and** — Implementado en `decompressor.v` (quadrant 01, funct3=100, {i[12],i[6:5]}=011)
- [x] **c.or** — Implementado en `decompressor.v` (quadrant 01, funct3=100, {i[12],i[6:5]}=010)
- [x] **c.xor** — Implementado en `decompressor.v` (quadrant 01, funct3=100, {i[12],i[6:5]}=001)
- [x] **c.slli** — Implementado en `decompressor.v` (quadrant 10, funct3=000)
- [x] **c.srli** — Implementado en `decompressor.v` (quadrant 01, funct3=100, i[11:10]=00)
- [x] **c.srai** — Implementado en `decompressor.v` (quadrant 01, funct3=100, i[11:10]=01)
- [x] **c.lui** — Implementado en `decompressor.v` (quadrant 01, funct3=011)

## Test de prueba de las instrucciones

- [x] **Testbench específico** — `tb/tb_test_10_instrucciones.v` (PASS verificado)
- [x] **Programa .mem asociado** — `mem/test_10_instrucciones.mem` (mezcla RV32I + RVC)

---

## Informe — Implementación de instrucciones (2.0 pts)

### Explicar cómo funciona cada nueva instrucción (1.5 pts)

| Intrucción | Explicada en `cambios_realizados.md`? |
|---|---|
| c.addi | ✅ Líneas 43–48: formato CI, inmediato sign-extendido, rd fuente y destino |
| c.add | ✅ Líneas 50–55: formato CR, registros completos de 5 bits |
| c.sub | ✅ Líneas 57–62: formato CA, funct7=0100000, registros x8–x15 |
| c.xor | ✅ Líneas 57–62: formato CA, funct3=100 |
| c.or | ✅ Líneas 57–62: formato CA, funct3=110 |
| c.and | ✅ Líneas 57–62: formato CA, funct3=111 |
| c.slli | ✅ Líneas 71–74: formato CI, shamt en bits [6:2] |
| c.srli | ✅ Líneas 77–83: formato CB, funct7=0000000 |
| c.srai | ✅ Líneas 77–83: formato CB, funct7=0100000 |
| c.lui | ✅ Líneas 88–92: formato CI, nzimm mapeado a bits [17:12] |

- [x] Formato RVC (quadrant, funct3, campos de registros) descrito
- [x] Mapeo de registros de 3 bits (x8–x15) documentado
- [x] Código Verilog de cada expansión en el informe

### Cambios extras en el datapath para adaptación (0.5 pts)

- [x] `imem.v`: Cambio de palabra de 32 bits a halfwords de 16 bits (líneas 101–117)
- [x] `if_stage.v`: Instanciación del decompressor, PC avanza +2 o +4 (líneas 127–148)
- [x] `pipeline.v`: Nuevo wire `PCPlus4F` y conexión (líneas 150–176)
- [x] `regfile.v`: Zeroeo inicial de registros (líneas 178–192)
- [x] Explicación de que el hazard unit **no** requirió cambios (líneas 194–199)

---

## Resultados (2.0 pts)

### Programa ISA test mixto 32 + 16 bits (0.5 pts)

- [x] Archivo: `mem/test_10_instrucciones.mem`
- [x] Contiene instrucciones RV32I y las 10 RVC intercaladas
- [x] Secuencia: inicializa registros con RV32I, opera con RVC

### Waveform de todas las instrucciones explicadas (1.5 pts)

- [x] Waveform generado: `waveform/tb_test_10_instrucciones.vcd`
- [x] Señales capturadas:
  - `PCF` — muestra avances de +2 y +4
  - `InstrF` — instrucción ya expandida a 32 bits
  - `InstrD` — instrucción en decode (1 ciclo después)
  - `IsCompressedF` — flag que identifica RVC vs RV32I
  - `ALUResultE` — resultado de cada operación

### Mostrar con resultados que el programa funciona correctamente

- [x] `tb_test_10_instrucciones.v` verifica 8 registros con valores esperados
- [x] Simulación produce **PASS** (verificado con iverilog)
- [x] Valores correctos:

| Registro | Esperado | Obtenido | Estado |
|---|---|---|---|
| x8 | 13 | 13 | ✅ |
| x9 | 16 | 16 | ✅ |
| x10 | 5 | 5 | ✅ |
| x11 | 7 | 7 | ✅ |
| x12 | 4 | 4 | ✅ |
| x13 | 10 | 10 | ✅ |
| x14 | 2 | 2 | ✅ |
| x15 | 8192 | 8192 | ✅ |

---

## Resumen de cumplimiento

| Ítem | Puntaje | Estado |
|---|---|---|
| Código de 10 instrucciones RVC | — | ✅ Completo |
| Testbench de prueba | — | ✅ `tb_test_10_instrucciones` PASS |
| Informe: Implementación | 2.0 / 2.0 | ✅ 10 instr explicadas con código |
| Informe: Cambios datapath | 0.5 / 0.5 | ✅ imem, if_stage, pipeline, regfile |
| Resultados: Programa ISA test | 0.5 / 0.5 | ✅ test_10_instrucciones.mem |
| Resultados: Waveform explicado | 1.5 / 1.5 | ✅ VCD con señales clave |
| Resultados: Funcionamiento correcto | — | ✅ PASS en simulación |
| **Total** | **4.0 / 4.0** | **✅ Completado** |

## Observaciones adicionales

- El bug de `c.jal`/`c.j` (decompressor J-type) **no afecta** estos entregables porque
  ninguna de las 10 instrucciones del E2 incluye saltos comprimidos.
- `c.lw`, `c.sw`, `c.jr`, `c.jalr`, `c.lwsp`, `c.swsp` están implementados en el
  decompressor pero **no son evaluados** en esta entrega (son funcionalidad extra).
