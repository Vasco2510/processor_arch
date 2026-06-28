# Informe de Auditoría — RISC-V Pipeline con extensión RVC (Parte 2)

**Fecha:** 25/06/2026
**Proyecto:** Procesador pipelined RV32I + extensión 'C' (RVC)
**Archivos fuente:** `src/*.v` (21 módulos), `tb/*.v` (7 testbenches), `mem/*.mem` (7 programas)

---

## 0. Estructura del proyecto

```
files/
├── AGENTS.md                      # Instrucciones para OpenCode
├── cambios_realizados.md          # Documentación de cambios RVC
├── outputs/
│   └── infor_25_06.md             # ← Este informe
├── mem/                           # Programas de prueba (.mem)
│   ├── programa_rvc1.mem          #   RVC puro (6 instr + beq)
│   ├── programa_rvc2.mem          #   Mixto RVC + RV32I
│   ├── test_10_instrucciones.mem  #   10 instr RVC del E2
│   ├── test_flushing.mem          #   Test de branches
│   ├── test_forwarding.mem        #   Test de forwarding
│   ├── test_instrucciones.mem     #   24 instr RV32I del Cuadro 1
│   └── test_stalling.mem          #   Test de load-use stall
├── src/                           # Fuentes Verilog (21 módulos)
│   ├── top_pipe.v                 #   Top-level
│   ├── pipeline.v                 #   Orquestador 5 etapas
│   ├── if_stage.v                 #   Instruction Fetch
│   ├── id_stage.v                 #   Instruction Decode
│   ├── ex_stage.v                 #   Execute
│   ├── mem_stage.v                #   Memory Access
│   ├── wb_stage.v                 #   Write Back
│   ├── controller_pipe.v          #   Unidad de control
│   ├── maindec.v                  #   Decodificador principal
│   ├── aludec.v                   #   Decodificador ALU
│   ├── hazard_unit.v              #   Forwarding / stalls / flushes
│   ├── decompressor.v             #   ⚠️ Expansor RVC (BUG corregido)
│   ├── regfile.v                  #   Banco de registros
│   ├── imem.v                     #   Memoria de instr (halfwords)
│   ├── dmem.v                     #   Memoria de datos
│   ├── extend.v                   #   Generador de inmediatos
│   ├── alu.v                      #   ALU
│   ├── adder.v                    #   Sumador
│   ├── flopr.v                    #   Registro con reset
│   ├── mux2.v                     #   Multiplexor 2:1
│   └── mux3.v                     #   Multiplexor 3:1
├── tb/                            # Testbenches (7)
│   ├── tb_test_instrucciones.v
│   ├── tb_test_forwarding.v
│   ├── tb_test_flushing.v
│   ├── tb_test_stalling.v
│   ├── tb_test_10_instrucciones.v
│   ├── tb_programa_rvc1.v
│   └── tb_programa_rvc2.v
├── waveform/                      # VCD y binario de simulación
│   ├── sim.out                    #   Ejecutable iverilog
│   ├── tb_test_instrucciones.vcd
│   ├── tb_test_forwarding.vcd
│   ├── tb_test_flushing.vcd
│   ├── tb_test_stalling.vcd
│   ├── tb_test_10_instrucciones.vcd
│   ├── tb_programa_rvc1.vcd
│   └── tb_programa_rvc2.vcd
├── comandsToRun/                  # Referencia de comandos
│   └── run_tb_test_instrucciones.md
├── contexto/
│   └── propuesta.md               # Propuesta de fix (IA)
└── Entrega1-Documento.pdf         # Documento de la Parte 1
```

**Dependencias entre módulos (dataflow):**
```
top_pipe → pipeline
               ├── if_stage → imem, decompressor, flopr, mux3
               ├── id_stage → regfile, extend, controller_pipe (→ maindec, aludec)
               ├── ex_stage → alu, adder, mux3 (forwarding)
               ├── mem_stage → dmem
               └── wb_stage → mux3
               └── hazard_unit (conectado a IF, ID, EX)
```

---

## 1. Resumen de arquitectura

### 1.1 Top-level y pipeline

| Módulo | Ruta | Rol |
|---|---|---|
| `top_pipe` | `src/top_pipe.v` | Top-level. Parámetro `INSTR_MEM_FILE` selecciona el `.mem` a cargar. |
| `pipeline` | `src/pipeline.v` | Orquestador de las 5 etapas. Conecta IF, ID, EX, MEM, WB y el hazard unit. |

### 1.2 Etapa IF (Instruction Fetch) — `src/if_stage.v`

- Instancia `imem` (lectura de memoria de instrucciones), `decompressor` (expansión RVC), `flopr` (PC).
- **PC avanza +2 si es RVC, +4 si es RV32I** (señal `IsCompressedF` del decompressor).
- Multiplexor de 3 entradas para `PCNextF`: 00=PC+N, 01=PCTargetE (branch/jal), 10=PCJalrE (jalr).
- Exporta `PCPlus4F` (históricamente PC+4, ahora puede ser PC+2 o PC+4).

### 1.3 Etapa ID (Instruction Decode) — `src/id_stage.v`

- Decodifica campos de la instrucción: `Rs1D`, `Rs2D`, `RdD`, `opD`, `funct3D`, `funct7b5D`.
- Instancia `regfile` (lectura de registros) y `extend` (generación de inmediato).
- Instancia `controller_pipe` → `maindec` + `aludec` para generar señales de control.

### 1.4 Etapa EX (Execute) — `src/ex_stage.v`

- Forwarding muxes (SrcAE, SrcBE) para datos desde MEM y WB.
- ALU con control de 4 bits (add, sub, and, or, xor, slt, sll, srl, sra, passB).
- Cálculo de `PCTargetE = PCE + ImmExtE` y `PCJalrE = {ALUResultE[31:1], 1'b0}`.
- Resolución de branches por funct3 con flags `eqE` y `ltE`.
- `PCSrcE` de 2 bits: 00=PC+N, 01=branch/jal, 10=jalr.

### 1.5 Etapa MEM (Memory Access) — `src/mem_stage.v`

- Instancia `dmem` (memoria de datos, 64×32 bits, alineada a 4 bytes).

### 1.6 Etapa WB (Write Back) — `src/wb_stage.v`

- Mux3 para seleccionar resultado: ALUResultW / ReadDataW / PCPlus4W.

### 1.7 Hazard Unit — `src/hazard_unit.v`

- Forwarding: prioridad MEM (10) sobre WB (01).
- Load-use stall: congela IF e ID, inserta burbuja en EX.
- Flushing en branch/jump tomado: descarta IF/ID y EX.

---

## 2. Extension RVC — Módulos específicos

### 2.1 `decompressor.v` — Expansión de instrucciones comprimidas

- **Lógica combinacional pura.** Entrada: `instr16[15:0]`. Salida: `instr32[31:0]`, `is_compressed`.
- Detecta comprimidas por `instr16[1:0] != 2'b11`.
- Registros restringidos x8–x15: `{2'b01, reg_3bits}`.
- 4 quadrantes (bits [1:0]), cada uno con sub-cases por funct3 (bits [15:13]).

### 2.2 `imem.v` — Memoria de instrucciones en halfwords

- Cambio clave respecto a Parte 1: ahora `reg [15:0] RAM[0:127]` (128 halfwords).
- Lectura alineada a 2 bytes: `idx = a[7:1]`, siempre devuelve 32 bits: `{RAM[idx+1], RAM[idx]}`.
- **Formato .mem:** 32 bits → 2 líneas (little-endian halfwords), 16 bits → 1 línea.

### 2.3 `regfile.v` — Zeroeo inicial

- `initial` block zeroea todos los registros al inicio de simulación.
- **Necesario para RVC:** `c.addi rd, imm` se expande a `addi rd, rd, imm`, que lee rd como fuente.

### 2.4 Hazard Unit — Sin cambios

- No distingue RVC de RV32I. El decompressor ya expandió antes de que las señales lleguen al hazard.

---

## 3. Señales de control

### 3.1 `maindec.v` — Decodificador principal

| Instrucción | opcode | RegWrite | ImmSrc | ALUSrc | MemWrite | ResultSrc | Branch | ALUOp | Jump | Jalr |
|---|---|---|---|---|---|---|---|---|---|---|
| lw | 0000011 | 1 | 000 (I) | 1 | 0 | 01 | 0 | 00 | 0 | 0 |
| sw | 0100011 | 0 | 001 (S) | 1 | 1 | 00 | 0 | 00 | 0 | 0 |
| R-type | 0110011 | 1 | 000 (I) | 0 | 0 | 00 | 0 | 10 | 0 | 0 |
| Branch | 1100011 | 0 | 010 (B) | 0 | 0 | 00 | 1 | 01 | 0 | 0 |
| I-ALU | 0010011 | 1 | 000 (I) | 1 | 0 | 00 | 0 | 10 | 0 | 0 |
| **jal** | **1101111** | 1 | 011 (J) | 0 | 0 | **10** | 0 | 00 | **1** | 0 |
| **jalr** | **1100111** | 1 | **000 (I)** | 1 | 0 | **10** | 0 | 00 | **1** | **1** |
| lui | 0110111 | 1 | 100 (U) | 1 | 0 | 00 | 0 | 11 | 0 | 0 |

- `ResultSrc = 10` → escribe `PCPlus4` en el registro destino (para jal/jalr).

### 3.2 `aludec.v` — Decodificador de ALU

- ALUOp=00 → add (lw, sw, jal, jalr)
- ALUOp=01 → sub (comparación de branch)
- ALUOp=10 → usar funct3/funct7b5 (R-type, I-type ALU)
- ALUOp=11 → passB (lui)

### 3.3 `extend.v` — Extensor de inmediatos

- I=000, S=001, B=010, J=011, U=100.
- **J-type (011):** `{{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}` — correcto.

---

## 4. 🔴 Error de implementación: c.jal / c.j en `decompressor.v`

### 4.1 Síntomas

Las expansiones de `c.jal` (quadrant 01, funct3=001) y `c.j` (quadrant 01, funct3=101) en el decompressor producen una concatenación de **31 bits** en lugar de 32 bits para la instrucción J-type.

### 4.2 Causa raíz

Formato J-type de 32 bits (JAL):
```
bit [31]   = imm[20]
bit [30:21] = imm[10:1]   (10 bits)
bit [20]   = imm[11]
bit [19:12] = imm[19:12]  (8 bits)
bit [11:7]  = rd           (5 bits)
bit [6:0]   = opcode       (7 bits)
```

En la expansión de `c.jal` (y `c.j`), **falta el bit `imm[11]` en la posición `instr32[20]`**.

**Código actual (erróneo):**
```verilog
instr32 = {instr16[12],           // [31] imm[20]           (1 bit)
           instr16[8], instr16[10:9], instr16[6],         // [30:28]
           instr16[7], instr16[2], instr16[11], instr16[5:3],  // [27:21]  imm[10:1] (10 bits)
           {8{instr16[12]}},       // [20:13]  ← DEBERÍA empezar en [19]   (8 bits)
           5'b00001,               // [12:8]   ← desplazado 1 bit           (5 bits)
           7'b1101111};            // [7:1]    ← desplazado 1 bit           (7 bits)
```

**Conteo:** 1 + 4 + 6 + 8 + 5 + 7 = **31 bits**. Verilog zero-pads el bit 31.

### 4.3 Código corregido (propuesta)

```verilog
instr32 = {instr16[12],           // [31] imm[20]
           instr16[8], instr16[10:9], instr16[6],         // [30:28]
           instr16[7], instr16[2], instr16[11], instr16[5:3],  // [27:21] imm[10:1]
           instr16[12],            // [20] imm[11]  ← BIT AGREGADO (FIX)
           {8{instr16[12]}},       // [19:12] imm[19:12]
           5'b00001,               // [11:7] rd
           7'b1101111};            // [6:0] opcode
```

**Conteo:** 1 + 10 + 1 + 8 + 5 + 7 = **32 bits**. ✓

### 4.4 Impacto

- `c.jal rd, imm` (expande a `jal x1, imm`) → el offset del salto está corrupto.
- `c.j imm` (expande a `jal x0, imm`) → idem.
- Para saltos hacia adelante (inmediato positivo, `instr[12]=0`): el zero-padding de Verilog en bit 31 produce imm[20]=0, que coincide con imm[11]=0, por lo que el offset funciona **por coincidencia** en algunos casos.
- Para saltos hacia atrás (inmediato negativo, `instr[12]=1`): el offset está corrupto porque imm[20]=0 (debería ser 1) y la posición del sign extension está desplazada.

### 4.5 Archivos afectados

- `src/decompressor.v` — línea 84-90 (c.jal) y línea 150-156 (c.j).

### 4.6 Tests existentes

Ninguno de los 7 testbenches existentes ejercita `c.jal` o `c.j`. Los programas de prueba usan solo `c.addi`, `c.add`, `c.sub`, `c.xor`, `c.or`, `c.and`, `c.slli`, `c.srli`, `c.srai`, `c.lui`, y `beq`.

---

## 5. Otras observaciones

### 5.1 Puntos fuertes

- Separación limpia de etapas con pipeline registers entre cada par.
- Hazard unit correcto: forwarding, load-use stall, branch flushing.
- Decompressor completo con las 10 instrucciones del E2 más soporte para c.lw/c.sw/c.jalr/c.jr/c.lwsp/c.swsp (no evaluados).
- PC avanza +2 o +4 correctamente según `IsCompressedF`.

### 5.2 Riesgos potenciales

- `dmem.v` usa `RAM[a[31:2]]` — alineado a 4 bytes. No hay soporte para loads/stores no alineados (correcto para RV32I estándar).
- `hazard_unit.v` no maneja el caso de `JalrD` como fuente de hazard de lectura después de escritura (ej: `jalr x1, x1, 0` seguido de `add x2, x1, x0`). Esto se maneja por forwarding desde MEM/WB normalmente.
- No hay testbench que evalúe saltos (jal, jalr, c.jal, c.j, c.jalr, c.jr) — todos los .mem existentes terminan con `beq x0, x0, 0`.

---

## 6. Resumen de módulos

| Archivo | Líneas | Función |
|---|---|---|
| `adder.v` | 5 | Sumador simple |
| `alu.v` | 28 | ALU de 32 bits con 9 operaciones |
| `aludec.v` | 32 | Decodificador de ALUControl |
| `controller_pipe.v` | 44 | Unidad de control (maindec + aludec) |
| **`decompressor.v`** | 246 | ⚠️ Expansor RVC (BUG aquí) |
| `dmem.v` | 12 | Memoria de datos |
| `ex_stage.v` | 72 | Etapa Execute |
| `extend.v` | 20 | Generador de inmediatos |
| `flopr.v` | 11 | Registro con reset |
| `hazard_unit.v` | 35 | Forwarding + stalls + flushes |
| `id_stage.v` | 53 | Etapa Decode |
| `if_stage.v` | 47 | Etapa Fetch (con decompressor) |
| `imem.v` | 32 | Memoria de instrucciones (halfwords) |
| `maindec.v` | 40 | Decodificador principal |
| `mem_stage.v` | 20 | Etapa Memory |
| `mux2.v` | 8 | Multiplexor 2:1 |
| `mux3.v` | 8 | Multiplexor 3:1 |
| `pipeline.v` | 176 | Orquestador del pipeline |
| `regfile.v` | 27 | Banco de registros |
| `top_pipe.v` | 20 | Top-level |
| `wb_stage.v` | 20 | Etapa Write Back |
