# Guía de Simulación — Waly: c.lwsp y c.swsp

## Archivos creados

| Archivo | Descripción |
|---|---|
| `mem/test_waly_lwsp_swsp.mem` | Programa de prueba |
| `tb/tb_waly_lwsp_swsp.v` | Testbench con señales del plan |
| `waveform/tb_waly_lwsp_swsp.vcd` | VCD generado al simular |

---

## Programa que ejecuta el test

```
addi  x2,  x0, 32    → x2 = 32   (stack pointer base)
addi  x9,  x0,  7    → x9 = 7    (valor a almacenar)
c.swsp x9,  0(x2)    → mem[32] = 7
c.lwsp x10, 0(x2)    → x10 = mem[32] = 7
beq   x0,  x0,  0    → loop (fin)
```

**Resultados esperados:** `x2=32`, `x9=7`, `x10=7`

---

## Comandos para simular (desde la raíz del proyecto)

```bash
iverilog -o waveform/sim_waly.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_waly_lwsp_swsp.v && vvp waveform/sim_waly.out
```

La consola debe imprimir:
```
=== TEST WALY: c.lwsp y c.swsp ===
--- Resultados finales ---
x2  = 32  (esperado: 32)
x9  = 7   (esperado:  7)
x10 = 7   (esperado:  7)
PASS
```

Para abrir el waveform:
```bash
gtkwave waveform/tb_waly_lwsp_swsp.vcd
```

---

## Señales a analizar en GTKWave

Carga el archivo VCD y agrega estas señales en orden:

### Grupo 1 — Instrucción en Fetch
| Señal | Qué esperar |
|---|---|
| `PCF` | Avanza: 0→4→8→A→C→10 (las 2 RVC suman +2 cada una) |
| `IsCompressedF` | 0 en addi, 0 en addi, **1 en c.swsp**, **1 en c.lwsp** |
| `InstrF` | Las dos RVC se muestran ya expandidas a 32 bits |

### Grupo 2 — Decode: verificar que rs1 = x2
| Señal | Qué esperar |
|---|---|
| `Rs1D` | Debe ser `2` (x2) durante c.swsp y c.lwsp |
| `ImmExtD` | Debe ser `0` (offset = 0 en este test) |

> **Punto clave del plan:** `InstrD[19:15]` = `00010` (x2) confirma que el
> decompressor inyecta x2 como rs1 aunque la instrucción solo tenga 16 bits.

### Grupo 3 — Execute: dirección efectiva
| Señal | Qué esperar |
|---|---|
| `ALUResultE` | Debe ser `32` (= x2 + 0) durante ambas instrucciones |

### Grupo 4 — Memory: escritura y lectura
| Señal | Qué esperar |
|---|---|
| `ALUResultM` | `32` — dirección de memoria accedida |
| `MemWriteM` | `1` durante c.swsp, `0` durante c.lwsp |
| `WriteDataM` | `7` durante c.swsp (dato que se escribe) |
| `ReadDataM` | `7` durante c.lwsp (dato que se lee) |

### Grupo 5 — Writeback
| Señal | Qué esperar |
|---|---|
| `ResultSrcW` | `01` durante c.lwsp → resultado viene de memoria |
| `rf[10]` | Cambia de `0` a `7` al completar c.lwsp |

---

## ¿Qué demuestra cada señal?

**`IsCompressedF = 1`** → el decompressor detectó correctamente una instrucción de 16 bits.

**`InstrD[19:15] = 00010` (x2)** → aunque c.lwsp y c.swsp no incluyen un campo rs1 de 5 bits,
el decompressor hardcodea x2 como registro base. Esto es lo central de la validación de Waly.

**`ALUResultE = 32`** → la ALU calcula `rs1 + imm = 32 + 0 = 32` correctamente.

**`MemWriteM = 1` solo en c.swsp** → la señal de escritura se activa únicamente cuando
corresponde, sin interferir con c.lwsp.

**`ReadDataM = 7` en c.lwsp** → la memoria devuelve el valor que c.swsp guardó,
confirmando que la cadena store→load funciona de extremo a extremo.
