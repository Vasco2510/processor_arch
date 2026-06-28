
# 3. Implementación de las instrucciones c.

### 3.1. Filosofía de Diseño y Arquitectura del Descompresor (`decompressor.v`)

_Aquí explicas cómo interactúa el descompresor con el resto del procesador antes de entrar en los detalles de cada instrucción._

- **Naturaleza combinacional:** Explicar que el módulo es lógica combinacional pura colocada en la etapa **Fetch (IF)**. Intercepta los 16 bits leídos de la memoria (`imem`) y, si detecta que es comprimida, entrega una instrucción estándar de 32 bits compatible con el pipeline RV32I.
    
- **Detección de compresión:** Detallar el criterio de selección físico: si los dos bits menos significativos de la instrucción de 16 bits son distintos de `2'b11`, el procesador activa la señal `is_compressed`.
    
- **Mapeo de registros restringidos (3 bits a 5 bits):** Explicar formalmente cómo el descompresor traduce los registros compactos de 3 bits (usados en la mayoría de instrucciones RVC) al espacio real de registros de la CPU, mapeándolos exclusivamente al rango `x8` a `x15` mediante la concatenación binaria `{2'b01, reg_3bits}`.
    

### 3.2. Clasificación de las 10 Instrucciones Implementadas

_Una pequeña sección introductoria con una tabla para darle un toque muy profesional y ordenado al informe._

- Presentar una tabla resumen que clasifique las 10 instrucciones según su cuadrante (`01` o `10`), su formato RVC (CI, CR, CA, CB) y su equivalente nativo en RV32I.
    

### 3.3. Especificación Detallada de Expansión por Grupos

_(Para cada uno de los siguientes subpuntos, tu trabajo al revisar el código Verilog será explicar: 1. Qué bits de la instrucción de 16 bits forman el inmediato o los registros. 2. Cómo se reconstruye el Opcode, Funct3 y Funct7 de 32 bits)._

#### 3.3.1. Operaciones Aritméticas con Inmediato (`c.addi` y `c.lui`)

- **`c.addi`:** Explicar el formato CI. Detallar cómo el inmediato de 6 bits se extiende con signo a 32 bits y cómo el registro actúa como fuente y destino a la vez.
    
- **`c.lui`:** Explicar cómo el inmediato corto (`nzimm`) se mapea en los bits superiores `[17:12]` de la instrucción de 32 bits para cargar constantes altas en los registros.
    

#### 3.3.2. Operaciones Aritméticas Registro-Registro (`c.add` y `c.sub`)

- **`c.add`:** Resaltar que utiliza el formato CR, el cual permite usar el banco completo de 5 bits de registros (cualquiera del `x0` al `x31`) en lugar de limitarse a la zona restringida.
    
- **`c.sub`:** Explicar el formato CA. Mostrar cómo se fuerza el bit de resta en el campo `funct7` de 32 bits (`funct7 = 0100000`) para que la ALU sepa que debe restar.
    

#### 3.3.3. Operaciones Lógicas de Bits (`c.and`, `c.or`, `c.xor`)

- Explicar que las tres comparten el formato CA y operan sobre los registros restringidos `x8-x15`.
    
- Detallar cómo el descompresor altera el campo `funct3` final (`111` para AND, `110` para OR, `001` para XOR) para heredar el comportamiento exacto de las operaciones tipo R de RV32I.
    

#### 3.3.4. Instrucciones de Desplazamiento (`c.slli`, `c.srli`, `c.srai`)

- **`c.slli` (Shift Left Logical Immediate):** Formato CI. Explicar cómo se extrae la cantidad de desplazamiento (`shamt`) de los bits `[6:2]`.
    
- **`c.srli` y `c.srai` (Shift Right Logical / Arithmetic):** Formato CB. Explicar la diferencia clave en el bit de signo mapeado en `funct7` para diferenciar un desplazamiento lógico (rellena con ceros) de uno aritmético (mantiene el signo).