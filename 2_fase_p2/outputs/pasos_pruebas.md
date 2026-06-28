# Pasos para simular en Vivado

## Requisito previo

Tener Vivado instalado (2019.1 o superior). No se necesita licencia especial —
los testbenches son funcionales y no usan IPs.

---

## 1. Crear proyecto en Vivado

1. Abrir **Vivado**
2. **File → Project → New**
3. Nombre del proyecto: ej. `riscv_pipeline_rvc`
4. **RTL Project** (marcar "Do not specify sources at this time")
5. **Add Sources** (después de crear):

   **Add Files** → seleccionar TODOS los archivos de `src/`:
   ```
   adder.v, alu.v, aludec.v, controller_pipe.v, decompressor.v,
   dmem.v, ex_stage.v, extend.v, flopr.v, hazard_unit.v,
   id_stage.v, if_stage.v, imem.v, maindec.v, mem_stage.v,
   mux2.v, mux3.v, pipeline.v, regfile.v, top_pipe.v, wb_stage.v
   ```
   - **Target language:** Verilog
   - **Simulator:** Vivado Simulator (XSim)

6. **Add Simulation Sources** → seleccionar UN testbench de `tb/` (ej. `tb_test_10_instrucciones.v`)

7. En **Add Constraints** → skipear (no tenemos .xdc)

8. **Finish**

---

## 2. Configurar la simulación

El proyecto usa archivos `.mem` para cargar programas en la memoria de instrucciones.
Cada testbench selecciona su `.mem` mediante el parámetro `INSTR_MEM_FILE`.

### ¿Qué son los archivos .mem?

Son archivos de texto hexadecimal que representan el contenido de la memoria de
instrucciones (`imem.v`). La memoria almacena en **halfwords de 16 bits**.

**Instrucciones de 32 bits (RV32I):**
Ocupan **2 líneas** en el .mem, en orden little-endian:
```
BBBB    ← halfword bajo (bits 15:0), dirección par
AAAA    ← halfword alto (bits 31:16), dirección par+2
```
Ej: `addi x8, x0, 10` = `0x00A00413` → se escribe como `0413` luego `00A0`.

**Instrucciones de 16 bits (RVC):**
Ocupan **1 línea**:
```
ABCD    ← instrucción completa de 16 bits
```
Ej: `c.addi x8, 3` = `0x040D` → se escribe como `040D`.

Se permiten comentarios con `//`.

### Archivos .mem disponibles

| Archivo | Descripción |
|---|---|
| `test_instrucciones.mem` | 24 instrucciones RV32I del Cuadro 1 |
| `test_forwarding.mem` | Test de forwarding |
| `test_flushing.mem` | Test de flushing (branches) |
| `test_stalling.mem` | Test de load-use stall |
| `test_10_instrucciones.mem` | **Las 10 instrucciones RVC del E2 mezcladas con RV32I** |
| `programa_rvc1.mem` | Programa RVC puro (solo 16 bits) |
| `programa_rvc2.mem` | Programa mixto RVC + RV32I |

---

## 3. Ejecutar simulación

1. En el panel **Flow Navigator** → **Simulation → Run Simulation → Run Behavioral Simulation**
2. Vivado compila y abre la ventana de waveform.
3. Para ver el resultado completo:
   - En la ventana **Tcl Console**, escribe: `run 1500 ns`
   - O usa el botón **Run All** y espera a que termine.
4. Revisa la **Tcl Console** para ver los mensajes `$display`:
   - `PASS` o `FAIL` (en los testbenches que lo tienen)
   - Valores de registros al final de la simulación

### Señales clave para agregar al waveform

Para visualizar el comportamiento, agrega estas señales (usa el testbench
`tb_test_10_instrucciones` como ejemplo):

| Ruta en Vivado | Señal | Qué muestra |
|---|---|---|
| `tb_test_10_instrucciones/dut/pipe/PCF` | PC actual | Avanza +2 (RVC) o +4 (RV32I) |
| `tb_test_10_instrucciones/dut/pipe/InstrF` | Instr en Fetch | Ya expandida por decompressor |
| `tb_test_10_instrucciones/dut/pipe/InstrD` | Instr en Decode | InstrF con 1 ciclo de retraso |
| `tb_test_10_instrucciones/dut/pipe/ifs/IsCompressedF` | Flag RVC | 1 = comprimida, 0 = 32 bits |
| `tb_test_10_instrucciones/dut/pipe/ALUResultE` | Resultado ALU | Resultado de cada operación |
| `tb_test_10_instrucciones/dut/pipe/ids/rf/rf[8..15]` | Registros x8–x15 | Valores finales |

**Para agregar:** en la ventana de waveform, botón derecho → **Add Wire** y pegar la ruta,
o buscar en el panel **Scope** navegando la jerarquía `dut → pipe → ifs / ids / exs`.

---

## 4. Testbenches disponibles

| Testbench | .mem asociado | PASS/FAIL? | Tiempo sim |
|---|---|---|---|
| `tb_test_instrucciones` | `test_instrucciones.mem` | No (solo prints) | 3000 ns |
| `tb_test_forwarding` | `test_forwarding.mem` | No (solo prints) | 3000 ns |
| `tb_test_flushing` | `test_flushing.mem` | No (solo prints) | 3000 ns |
| `tb_test_stalling` | `test_stalling.mem` | No (solo prints) | 3000 ns |
| **`tb_test_10_instrucciones`** | **`test_10_instrucciones.mem`** | **Sí (PASS/FAIL)** | **1500 ns** |
| `tb_programa_rvc1` | `programa_rvc1.mem` | Sí (PASS/FAIL) | 500 ns |
| `tb_programa_rvc2` | `programa_rvc2.mem` | Sí (PASS/FAIL) | 500 ns |

Para cambiar de testbench: **Add Sources → Add Simulation Sources** y
seleccionar otro archivo de `tb/`.

---

## 5. Interpretar resultados

### Caso: `tb_test_10_instrucciones`

Al correr 1500 ns, la Tcl Console debe mostrar:

```
===  10 instrucciones RVC ===
--- Resultados ---
x8  = 13  (esperado: 13)
x9  = 16  (esperado: 16)
x10 = 5  (esperado:  5)
x11 = 7  (esperado:  7)
x12 = 4  (esperado:  4)
x13 = 10  (esperado: 10)
x14 = 2  (esperado:  2)
x15 = 8192  (esperado: 8192)
PASS
```

Si ves `PASS`, todas las instrucciones RVC funcionan correctamente.
Si ves `FAIL` o valores `xxxxxxxx`, hay un problema (generalmente el
decompressor o la inicialización de registros).

### Valores esperados por instrucción

| RVC | Operación | Resultado |
|---|---|---|
| `c.addi x8, 3` | x8 = x8 + 3 | x8 = 13 |
| `c.add x9, x8` | x9 = x9 + x8 | x9 = 16 |
| `c.sub x10, x11` | x10 = x10 - x11 | x10 = 13 |
| `c.and x10, x11` | x10 = x10 & x11 | x10 = 5 |
| `c.or x12, x13` | x12 = x12 \| x13 | x12 = 14 |
| `c.xor x12, x13` | x12 = x12 ^ x13 | x12 = 4 |
| `c.slli x14, 2` | x14 = x14 << 2 | x14 = 32 |
| `c.srli x14, 3` | x14 = x14 >> 3 | x14 = 4 |
| `c.srai x14, 1` | x14 = x14 >>> 1 | x14 = 2 |
| `c.lui x15, 2` | x15 = 2 << 12 | x15 = 8192 |
