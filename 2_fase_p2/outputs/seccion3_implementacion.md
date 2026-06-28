# 3. Implementación de las instrucciones comprimidas

## 3.1. Filosofía de Diseño y Arquitectura del Descompresor (`decompressor.v`)

### 3.1.1. Naturaleza combinacional del descompresor

El módulo `decompressor.v` es el núcleo de la extensión RVC. Se implementa como
**lógica combinacional pura** — no tiene entradas de reloj, no mantiene estado
interno y su salida depende exclusivamente de la entrada actual de 16 bits. Está
colocado en la **etapa Fetch (IF)** del pipeline, justo después de la memoria de
instrucciones (`imem.v`) y antes de que la instrucción ingrese al registro
pipeline IF/ID.

```
imem (lectura) → decompressor (expansión) → InstrF (32 bits) → IF/ID register
```

Su función es transparente para el resto del pipeline: intercepta los 16 bits
leídos de `imem` y, si detecta que corresponden a una instrucción comprimida,
entrega una instrucción estándar de 32 bits compatible con el datapath RV32I.
Si la instrucción ya es de 32 bits, la deja pasar sin modificaciones.

### 3.1.2. Detección de compresión

El criterio de detección está dado por la arquitectura RISC-V: los dos bits
menos significativos (`instr16[1:0]`) definen el *quadrant* de la instrucción.
Si son iguales a `2'b11`, la instrucción es de 32 bits (formato RV32I estándar).
Cualquier otro valor (`2'b00`, `2'b01`, `2'b10`) indica una instrucción
comprimida de 16 bits.

```verilog
assign is_compressed = (instr16[1:0] != 2'b11);
```

Esta señal `is_compressed` se propaga a `if_stage.v` para dos propósitos:

1. **Seleccionar la salida:** si está activa, se usa la instrucción expandida
   `DecompInstrF`; si no, se usa la instrucción original `RawInstrF`.
2. **Ajustar el PC:** cuando es 1, el PC avanza +2 bytes; cuando es 0, avanza +4.

```verilog
assign InstrF = IsCompressedF ? DecompInstrF : RawInstrF;
assign PCIncF = IsCompressedF ? (PCF + 32'd2) : (PCF + 32'd4);
```

### 3.1.3. Mapeo de registros restringidos (3 bits a 5 bits)

Los formatos RVC utilizan campos de 3 bits para referirse a registros en la
mayoría de las instrucciones (formatos CA, CB, CL, CS). Esto permite empaquetar
la instrucción en 16 bits, pero limita el rango direccionable a 8 registros.
La especificación RISC-V mapea estos 3 bits al rango `x8`–`x15`:

```verilog
wire [4:0] rd_p  = {2'b01, instr16[4:2]};  // rd'  → x8..x15
wire [4:0] rs1_p = {2'b01, instr16[9:7]};  // rs1' → x8..x15
wire [4:0] rs2_p = {2'b01, instr16[4:2]};  // rs2' → x8..x15
```

La concatenación `{2'b01, reg_3bits}` produce un registro de 5 bits completo
en el rango `8` a `15` (`0b01000` a `0b01111`).

Excepcionalmente, algunas instrucciones RVC como `c.add` y `c.slli` utilizan
el **formato CR/CI**, que emplea campos de 5 bits directos y puede direccionar
cualquier registro del banco (`x0`–`x31`):

```verilog
wire [4:0] rd_f  = instr16[11:7];  // rd completo (CR, CI, CSS)
wire [4:0] rs2_f = instr16[6:2];   // rs2 completo (CR, CSS)
```

---

## 3.2. Clasificación de las 10 Instrucciones Implementadas

La siguiente tabla resume las 10 instrucciones RVC implementadas, clasificadas
por su quadrante, formato RVC y equivalente en RV32I:

| Instrucción RVC | Quadrant | Formato RVC | Equivalente 32 bits | Tipo |
|---|---|---|---|---|
| `c.addi rd, imm` | 01 | CI | `addi rd, rd, imm` | Aritmética con inmediato |
| `c.lui rd, nzimm` | 01 | CI | `lui rd, nzimm` | Carga de constante |
| `c.add rd, rs2` | 10 | CR | `add rd, rd, rs2` | Aritmética registro-registro |
| `c.sub rd', rs2'` | 01 | CA | `sub rd', rd', rs2'` | Aritmética registro-registro |
| `c.and rd', rs2'` | 01 | CA | `and rd', rd', rs2'` | Lógica |
| `c.or rd', rs2'` | 01 | CA | `or rd', rd', rs2'` | Lógica |
| `c.xor rd', rs2'` | 01 | CA | `xor rd', rd', rs2'` | Lógica |
| `c.slli rd, shamt` | 10 | CI | `slli rd, rd, shamt` | Desplazamiento |
| `c.srli rd', shamt` | 01 | CB | `srli rd', rd', shamt` | Desplazamiento |
| `c.srai rd', shamt` | 01 | CB | `srai rd', rd', shamt` | Desplazamiento |

Los formatos RVC se definen así:
- **CI:** Inmediato compacto, un registro fuente-destino.
- **CR:** Dos registros completos (5 bits cada uno).
- **CA:** Dos registros restringidos (3 bits cada uno, x8–x15) más funct.
- **CB:** Un registro restringido más un inmediato de desplazamiento.

---

## 3.3. Especificación Detallada de Expansión por Grupos

### 3.3.1. Operaciones Aritméticas con Inmediato (`c.addi` y `c.lui`)

#### `c.addi rd, imm` → `addi rd, rd, imm`

- **Quadrant:** `01` | **Funct3:** `000` | **Formato:** CI
- **Campos:** `rd` = `instr[11:7]` (5 bits, cualquier registro)

El inmediato de 6 bits se extrae de los campos `instr[12]` (bit de signo) e
`instr[6:2]` (magnitud). Se sign-extiende a 12 bits para formar el campo
inmediato I-type de la instrucción de 32 bits. El registro `rd` actúa
simultáneamente como fuente y destino, reflejando la semántica de la
instrucción comprimida que no codifica un registro fuente por separado.

**Expansión bit a bit para `c.addi x8, 3` (`0x040D`):**

| instr16[15:0] | `0000_0100_0000_1101` |
|---|---|
| instr16[12] | `0` (inmediato positivo) |
| instr16[6:2] | `00011` (3 en decimal) |
| rd (instr[11:7]) | `01000` (x8) |
| **instr32** | `000000000011_01000_000_01000_0010011` = `0x00A00413` |
| | = `addi x8, x8, 3` |

```verilog
instr32 = {{6{instr16[12]}}, instr16[12], instr16[6:2],
           rd_f, 3'b000, rd_f, 7'b0010011};
```

El opcode `0010011` (I-type), funct3 `000` (add) y el inmediato
sign-extendido son heredados de la instrucción `addi` de RV32I.

---

#### `c.lui rd, nzimm` → `lui rd, nzimm`

- **Quadrant:** `01` | **Funct3:** `011` | **Formato:** CI
- **Campos:** `rd` = `instr[11:7]` (5 bits, cualquier registro)

A diferencia de `c.addi`, el inmediato de 6 bits `{instr[12], instr[6:2]}`
se mapea a los bits `[17:12]` del campo U-type de 20 bits. Los bits
superiores (`[31:18]`) se obtienen por sign-extension. Esto permite cargar
constantes de hasta 17 bits (con signo) en la parte alta de un registro.

**Expansión bit a bit para `c.lui x15, 2` (`0x6789`):**

| instr16[15:0] | `0110_0111_1000_1001` |
|---|---|
| instr16[12] | `0` (signo positivo) |
| instr16[6:2] | `00010` (2 en decimal) |
| rd (instr[11:7]) | `01111` (x15) |
| nzimm[17:12] | `{0, 00010}` = `000010` |
| **instr32[31:12]** | `{14{0}}, 0, 00010` = `0x0000_2000` |
| **instr32** | `0x0000_2000_01111_0110111` = `0x0000_2F37` |
| | = `lui x15, 0x2000` (x15 = 8192) |

```verilog
instr32 = {{14{instr16[12]}}, instr16[12], instr16[6:2],
           rd_f, 7'b0110111};
```

El opcode `0110111` (LUI) y el formato U-type hacen que el valor cargado sea
`nzimm << 12`, equivalente a multiplicar el inmediato por 4096.

---

### 3.3.2. Operaciones Aritméticas Registro-Registro (`c.add` y `c.sub`)

#### `c.add rd, rs2` → `add rd, rd, rs2`

- **Quadrant:** `10` | **Funct3:** `100` (instr[15:13]) | **Funct4:** `1001` (instr[15:12]) | **Formato:** CR
- **Campos:** `rd` = `instr[11:7]`, `rs2` = `instr[6:2]` (ambos de 5 bits)

Es una de las pocas instrucciones RVC que permite usar **cualquier registro
del banco** como fuente y destino, gracias a su formato CR que asigna 5 bits
completos para cada campo. Se distingue de `c.jr` y `c.jalr` porque comparten
el mismo quadrante y funct3, pero `c.add` tiene `instr[12]=1` y `rs2≠0`.

**Expansión:**

```verilog
instr32 = {7'b0000000, rs2_f, rd_f, 3'b000, rd_f, 7'b0110011};
```

La concatenación reconstruye una instrucción R-type completa:
- `funct7 = 0000000` (ADD, no SUB)
- `rs2 = rs2_f` (5 bits)
- `rs1 = rd_f` (el mismo registro es fuente y destino)
- `funct3 = 000`
- `rd = rd_f`
- `opcode = 0110011` (R-type)

---

#### `c.sub rd', rs2'` → `sub rd', rd', rs2'`

- **Quadrant:** `01` | **Funct3:** `100` | **Formato:** CA
- **Campo discriminador:** `{instr[12], instr[6:5]} = 3'b000`
- **Registros:** `rd' = rs1' = {2'b01, instr[9:7]}`, `rs2' = {2'b01, instr[4:2]}` (x8–x15)

A diferencia de `c.add`, usa el formato CA con registros restringidos a x8–x15.
La clave de la expansión es forzar `funct7 = 0100000`, que es el bit que la ALU
de RV32I utiliza para diferenciar `SUB` de `ADD` en las instrucciones R-type.

```verilog
instr32 = {7'b0100000, rs2_p, rs1_p, 3'b000, rs1_p, 7'b0110011};
```

El `funct7` en `0100000` (con el bit 30 en 1) indica a la ALU que realice una
resta en lugar de una suma. El `funct3 = 000` y el `opcode = 0110011` completan
la instrucción R-type equivalente a `sub`.

---

### 3.3.3. Operaciones Lógicas de Bits (`c.and`, `c.or`, `c.xor`)

- **Quadrant:** `01` | **Funct3:** `100` | **Formato:** CA
- **Campo discriminador:** `{instr[12], instr[6:5]}`:
  - `001` → xor (`funct3 = 100`)
  - `010` → or  (`funct3 = 110`)
  - `011` → and (`funct3 = 111`)
- **Registros:** `rs1' = {2'b01, instr[9:7]}`, `rs2' = {2'b01, instr[4:2]}` (x8–x15)

Las tres instrucciones comparten el mismo formato CA y se diferencian
exclusivamente por el valor del campo `funct3` en la instrucción expandida.
El decompressor traduce el discriminador `{instr[12], instr[6:5]}` al `funct3`
correspondiente de RV32I.

```verilog
// c.sub: funct3=000, funct7=0100000 (ya visto)
3'b000: instr32 = {7'b0100000, rs2_p, rs1_p, 3'b000, rs1_p, 7'b0110011};

// c.xor: funct3=100
3'b001: instr32 = {7'b0000000, rs2_p, rs1_p, 3'b100, rs1_p, 7'b0110011};

// c.or:  funct3=110
3'b010: instr32 = {7'b0000000, rs2_p, rs1_p, 3'b110, rs1_p, 7'b0110011};

// c.and: funct3=111
3'b011: instr32 = {7'b0000000, rs2_p, rs1_p, 3'b111, rs1_p, 7'b0110011};
```

El `funct7 = 0000000` para las tres operaciones lógicas (solo SUB requiere
`funct7 = 0100000`). El `opcode = 0110011` (R-type) se mantiene constante.
La ALU del pipeline recibe el `funct3` directamente desde el campo decodificado
de la instrucción expandida, por lo que ejecuta la operación correcta sin
ninguna modificación en la etapa EX.

---

### 3.3.4. Instrucciones de Desplazamiento (`c.slli`, `c.srli`, `c.srai`)

#### `c.slli rd, shamt` → `slli rd, rd, shamt`

- **Quadrant:** `10` | **Funct3:** `000` | **Formato:** CI
- **Campos:** `rd` = `instr[11:7]` (5 bits, cualquier registro), `shamt` = `instr[6:2]`

A diferencia de las instrucciones de desplazamiento del quadrante 01,
`c.slli` usa registros de 5 bits completos (formato CI en quadrante 10),
permitiendo desplazar cualquier registro del banco.

```verilog
instr32 = {7'b0000000, instr16[6:2], rd_f, 3'b001, rd_f, 7'b0010011};
```

La expansión reconstruye `slli` (I-type con `funct3 = 001`): el `shamt` se
coloca en los bits `[25:20]` del campo `funct7`, el registro fuente y destino
es el mismo (`rd_f`), y el opcode `0010011` indica una operación ALU con
inmediato.

---

#### `c.srli rd', shamt` y `c.srai rd', shamt`

- **Quadrant:** `01` | **Funct3:** `100` | **Funct2 (instr[11:10]):** `00` (srli), `01` (srai)
- **Formato:** CB
- **Registros:** `rs1' = {2'b01, instr[9:7]}` (x8–x15), `shamt` = `instr[6:2]`

Ambas instrucciones difieren únicamente en el valor de `funct7`. El
decompressor inspecciona `instr[11:10]` para decidir:

- **`c.srli`** (`instr[11:10] = 00`): desplazamiento **lógico** hacia la
  derecha. Usa `funct7 = 0000000`, que indica a la ALU que rellene con ceros.
- **`c.srai`** (`instr[11:10] = 01`): desplazamiento **aritmético** hacia la
  derecha. Usa `funct7 = 0100000`, que indica a la ALU que extienda el bit de
  signo.

```verilog
// c.srli: funct7=0000000 (shift lógico)
instr32 = {7'b0000000, instr16[6:2], rs1_p, 3'b101, rs1_p, 7'b0010011};

// c.srai: funct7=0100000 (shift aritmético)
instr32 = {7'b0100000, instr16[6:2], rs1_p, 3'b101, rs1_p, 7'b0010011};
```

Ambas usan `funct3 = 101` (específico de desplazamientos a la derecha en
RV32I) y `opcode = 0010011` (I-type ALU). La diferencia en `funct7` es la
misma que usa el repertorio RV32I para distinguir `srli` de `srai`.

---

## 3.4. Cambios en el datapath para adaptación

La incorporación de la extensión RVC no se limitó a la creación del módulo
decompressor. Fue necesario modificar varios componentes del datapath del
pipeline base para que pudieran manejar direcciones de memoria alineadas a 2
bytes, instrucciones de 16 bits en la memoria y un avance de PC variable. En
total, cuatro módulos existentes recibieron modificaciones: la memoria de
instrucciones (`imem.v`), la etapa de fetch (`if_stage.v`), el orquestador del
pipeline (`pipeline.v`) y el banco de registros (`regfile.v`). El módulo de
detección de hazards (`hazard_unit.v`), en cambio, no requirió alteración
alguna, y en la última subsección se explicará por qué.

Cada una de las siguientes subsecciones presenta el problema que motivó el
cambio, muestra el código antes y después de la modificación, y analiza el
impacto funcional de la adaptación.

### 3.4.1. `imem.v` — Almacenamiento en halfwords

**Problema.** En el pipeline base de la Parte 1, la memoria de instrucciones
almacenaba palabras completas de 32 bits y el direccionamiento se realizaba
mediante el índice `a[31:2]`, que ignora los dos bits menos significativos de
la dirección. Esto solo permite lecturas alineadas a 4 bytes, que es suficiente
para instrucciones RV32I pero no para RVC. Con la extensión comprimida, el PC
puede apuntar a direcciones pares como 0x02, 0x06 o 0x0A, que no son múltiplos
de 4. Para soportar estas direcciones, la memoria debe ser capaz de leer desde
cualquier alineación a 2 bytes.

**Código antes del cambio (pipeline base):**

```verilog
reg [31:0] RAM [0:63];
assign rd = RAM[a[31:2]];
```

La memoria se declaraba como un arreglo de 64 palabras de 32 bits,
direccionado únicamente con los bits `a[31:2]`. El bit `a[1]` era ignorado,
impidiendo distinguir entre una dirección como 0x00 y otra como 0x02.

**Código después del cambio (con soporte RVC):**

```verilog
reg [15:0] RAM [0:127];
wire [6:0] idx = a[7:1];
assign rd = {RAM[idx + 7'd1], RAM[idx]};
```

El cambio consiste en tres modificaciones. Primero, el ancho de cada entrada
se reduce de 32 bits a 16 bits (halfwords), y la profundidad se duplica de 64
a 127 entradas, manteniendo el mismo espacio total de direccionamiento.
Segundo, el índice de lectura ahora usa `a[7:1]` en lugar de `a[31:2]`, lo que
permite alinear la lectura a 2 bytes en lugar de a 4. Tercero, la salida
siempre devuelve 32 bits concatenando dos halfwords consecutivos en orden
little-endian: el halfword en la posición `idx` contiene los bits 15:0 y el
halfword en `idx+1` contiene los bits 31:16.

Este diseño permite leer correctamente tanto instrucciones de 32 bits
(que ocupan dos halfwords consecutivos) como instrucciones RVC de 16 bits
(que ocupan un solo halfword, con el halfword siguiente correspondiente a la
siguiente instrucción). La lógica del decompressor se encarga de interpretar
correctamente cuál de los dos halfwords debe usar cuando encuentra una
instrucción comprimida.

### 3.4.2. `if_stage.v` — Instanciación del decompressor y PC +2/+4

**Problema.** En el pipeline base, la etapa IF simplemente leía una instrucción
completa de 32 bits desde la memoria y la pasaba directamente al registro
IF/ID. El PC se incrementaba siempre en 4 unidades. Con la extensión RVC es
necesario interponer el decompressor entre la memoria y la salida de la etapa,
y el incremento del PC debe ser de 2 si la instrucción es comprimida o de 4 si
es estándar.

**Código antes del cambio (pipeline base):**

La etapa IF original solo contenía el registro del PC (`flopr`), la instancia
de `imem` y el multiplexor de selección del próximo PC. No había decompressor
ni lógica de detección de compresión, y el incremento era fijo en 4.

```verilog
// Versión base — sin decompressor, PC siempre +4
flopr #(32) pcreg (.clk(clk), .reset(reset), .d(PCNextF), .q(PCF));
imem #(.MEM_FILE(INSTR_MEM_FILE)) im (.a(PCF), .rd(InstrF));
assign PCPlus4F = PCF + 32'd4;
```

**Código después del cambio (con soporte RVC):**

```verilog
wire [31:0] RawInstrF;
wire        IsCompressedF;
wire [31:0] DecompInstrF;

flopr #(32) pcreg (.clk(clk), .reset(reset), .d(PCNextF), .q(PCF));
imem #(.MEM_FILE(INSTR_MEM_FILE)) im (.a(PCF), .rd(RawInstrF));

decompressor decomp (
    .instr16(RawInstrF[15:0]),
    .instr32(DecompInstrF),
    .is_compressed(IsCompressedF)
);

assign InstrF    = IsCompressedF ? DecompInstrF : RawInstrF;
assign PCIncF    = IsCompressedF ? (PCF + 32'd2) : (PCF + 32'd4);
assign PCPlus4F  = PCIncF;
```

Se agregaron tres señales internas: `RawInstrF` transporta la instrucción
cruda leída de la memoria (que puede ser de 16 o 32 bits); `IsCompressedF`
es la bandera que produce el decompressor cuando detecta que los bits
`instr[1:0]` son distintos de `2'b11`; y `DecompInstrF` es la instrucción
ya expandida a 32 bits.

La salida `InstrF` ahora se selecciona entre la instrucción expandida y la
original mediante un multiplexor controlado por `IsCompressedF`. De esta
manera, el resto del pipeline recibe siempre una instrucción de 32 bits
compatible y no necesita conocer el tamaño original de la instrucción.

El incremento del PC, antes fijo en 4, ahora se calcula condicionalmente:
si la instrucción es comprimida (`IsCompressedF` = 1), el PC avanza 2 bytes;
si es estándar, avanza 4 bytes. Este valor se exporta como `PCPlus4F` al
orquestador del pipeline, que lo propagará a las etapas siguientes para su uso
en el cálculo de jal y jalr.

### 3.4.3. `pipeline.v` — Propagación de PCPlus4F

**Problema.** En el pipeline base, el valor `PCPlus4` que viaja por los
registros pipeline IF/ID, ID/EX, EX/MEM y MEM/WB se calculaba directamente
como `PCF + 32'd4` dentro del bloque siempre del registro IF/ID. Esta suma
hardcodeada no funciona con RVC, donde el avance puede ser de 2 bytes.

**Código antes del cambio (pipeline base):**

```verilog
// Declaración de señales en IF
wire [31:0] PCF, InstrF;

// En el registro IF/ID
PCPlus4D <= PCF + 32'd4;
```

El valor `PCPlus4D` se obtenía sumando 4 al PC actual dentro del propio
bloque always de pipeline.v, sin pasar por la etapa IF. Cualquier variación
en el incremento habría requerido modificar esta línea.

**Código después del cambio (con soporte RVC):**

```verilog
// Declaración de señales en IF
wire [31:0] PCF, InstrF, PCPlus4F;

// Conexión del nuevo puerto en la instancia de if_stage
if_stage #(.INSTR_MEM_FILE(INSTR_MEM_FILE)) ifs (
    ...
    .PCPlus4F(PCPlus4F)
);

// En el registro IF/ID
PCPlus4D <= PCPlus4F;
```

Se realizaron tres cambios. Primero, se agregó el cable `PCPlus4F` a la
declaración de señales de la etapa IF. Segundo, se conectó este cable al
puerto del mismo nombre en la instancia de `if_stage`. Tercero, la asignación
en el registro IF/ID dejó de usar la suma hardcodeada `PCF + 32'd4` y pasó a
tomar el valor directamente desde `PCPlus4F`, que ya contiene el incremento
correcto (2 o 4) calculado dentro de `if_stage`.

Este cambio es sutil pero fundamental: permite que el valor `PCPlus4` que se
escribe en el registro destino tras un jal o jalr sea el valor correcto
independientemente de si la instrucción que provocó el salto era de 16 o de 32
bits.

### 3.4.4. `regfile.v` — Inicialización del banco de registros

**Problema.** En el pipeline base, el banco de registros no se inicializaba
explícitamente. En simulación, los registros comenzaban con el valor `x`
(unknown), y como la lectura de `x0` estaba hardcodeada a 0 mediante la
asignación `(a1 != 0) ? rf[a1] : 0`, las instrucciones RV32I que usaban `x0`
como fuente funcionaban correctamente porque nunca leían un registro no
inicializado. Sin embargo, las instrucciones RVC como `c.addi rd, imm` se
expanden a `addi rd, rd, imm`, que lee el registro `rd` como fuente. Si `rd`
no es `x0` y además nunca ha sido escrito, su valor es `x` y el resultado de la
operación propaga ese `x` a través del pipeline.

**Código antes del cambio (pipeline base):**

El banco de registros se declaraba sin ningún bloque de inicialización:

```verilog
reg [31:0] rf[31:0];
```

Los registros comenzaban con contenido indeterminado en simulación.

**Código después del cambio (con soporte RVC):**

```verilog
reg [31:0] rf[31:0];

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1)
        rf[i] = 32'b0;
end
```

Se agregó un bloque `initial` que, al comienzo de la simulación, recorre los
32 registros y les asigna el valor cero. Este bloque se ejecuta una sola vez
antes de que comience la actividad del reloj, de modo que todos los registros
parten de un estado conocido.

Es importante notar que este cambio es puramente funcional para la simulación
y no modifica la semántica del hardware sintetizable. En una implementación
física, los registros de la CPU arrancan con un valor indefinido, pero el
software de inicialización (rutina de boot) debe escribir los registros antes
de usarlos. La inicialización explícita en el modelo Verilog simplemente
elimina la indeterminación en las pruebas, permitiendo verificar el
comportamiento de las instrucciones RVC sin necesidad de un programa de
inicialización previa.

### 3.4.5. Hazard unit — Ausencia de cambios

El módulo `hazard_unit.v` no requirió ninguna modificación para soportar la
extensión RVC. La razón es arquitectónica: el decompressor se encuentra en la
etapa IF, antes de que la instrucción llegue a las etapas ID y EX donde opera
el hazard unit. Para cuando la instrucción atraviesa el registro IF/ID y entra
en la lógica de detección de hazards, ya ha sido expandida a 32 bits. El
hazard unit recibe los números de registro `Rs1D`, `Rs2D` y `RdD` provenientes
de la instrucción ya expandida, y las señales de control `RegWrite`, `MemRead`
y `PCSrcTaken` generadas a partir de esa misma instrucción. Nunca tiene
conocimiento de si la instrucción original era de 16 o de 32 bits.

Esto significa que el mecanismo de forwarding (que retrasa datos desde las
etapas MEM y WB para evitar dependencias), el stalling por load-use (que
congela IF e ID cuando un load está en EX y la instrucción en ID necesita su
resultado) y el flushing por branches y jumps (que descarta las instrucciones
en IF/ID y EX cuando se toma un salto) funcionan de manera idéntica tanto para
instrucciones RV32I como para instrucciones RVC expandidas. El hazard unit
opera sobre un espacio de registros de 5 bits (x0 a x31), y las instrucciones
RVC que usan registros restringidos x8 a x15 producen números de registro de 5
bits perfectamente válidos tras la expansión en el decompressor.

Esta transparencia es una de las ventajas del diseño elegido: al expandir las
instrucciones comprimidas al inicio del pipeline, el resto del procesador
puede permanecer inalterado, lo que simplifica la verificación y reduce el
riesgo de introducir errores en la lógica de control del pipeline.
