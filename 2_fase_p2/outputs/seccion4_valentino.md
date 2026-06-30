# 4. Resultados — Prueba de Salto Condicional y Salto por Registro

## 4.1 Programa de prueba

El programa de prueba `test_valentino_beqz_jalr.mem` fue diseñado para verificar el correcto funcionamiento de las instrucciones c.beqz y c.jalr, evaluando tanto el control de flujo como los mecanismos de descarte de instrucciones especulativas del pipeline.

El programa consta de 10 instrucciones en total: 6 instrucciones RV32I y 4 instrucciones RVC, ocupando en memoria 6 × 4 + 4 × 2 = 32 bytes.

### Estrategia de verificación con código muerto

La estrategia central del programa es colocar instrucciones "trampa" inmediatamente después de cada salto. Si el salto se toma correctamente, esas instrucciones quedan en el camino descartado por el pipeline y los registros que modificarían permanecen sin cambio.

| Registro | Valor cargado | Cómo se verifica |
|---|---|---|
| x9 | 0 | Valor que c.beqz evalúa (condición: x9 == 0) |
| x8 | 5 | Debe seguir en 5; si vale 6, c.beqz falló |
| x10 | 24 (0x18) | Dirección destino para c.jalr |
| x1 | calculado | c.jalr debe escribir aquí PC + 2 = 18 (0x12) |
| x11 | 0 | Debe seguir en 0; si vale 1, c.jalr falló |
| x12 | 77 (0x4D) | Solo se carga si el flujo llega a 0x18 |

### Por qué estos valores

x9 se inicializa en cero porque c.beqz evalúa exactamente esa condición (branch if equal to zero). El valor 24 en x10 corresponde a la dirección 0x18, que es donde se ubica la instrucción que carga 77 en x12; si c.jalr salta correctamente a esa dirección, x12 confirma que el flujo llegó al destino exacto. El valor 77 fue elegido por ser un número impar mayor que 16, descartando coincidencias accidentales con offsets o valores de control.

### Verificación automática

El testbench compara los seis registros contra sus valores esperados. La simulación produjo el siguiente resultado:

```
=== TEST: c.beqz y c.jalr ===
--- Resultados finales ---
x1  = 18  (esperado: 18)  [return addr c.jalr = 0x12]
x8  = 5   (esperado:  5)  [NO 6 => c.beqz saltó correctamente]
x9  = 0   (esperado:  0)
x10 = 24  (esperado: 24)  [dirección destino c.jalr]
x11 = 0   (esperado:  0)  [NO 1 => c.jalr saltó correctamente]
x12 = 77  (esperado: 77)  [llegamos al destino de c.jalr]
PASS
```

El programa termina con `beq x0, x0, 0` en la dirección 0x1C, un branch que salta a sí mismo y genera un loop infinito. Esto impide que el procesador avance hacia posiciones de memoria sin inicializar una vez completadas las instrucciones de prueba.

## 4.2 Análisis del waveform

El waveform captura las señales PCF, PCPlus4F, InstrF, InstrD, IsCompressedF, PCSrcE, PCTargetE, PCJalrE, branchCond, FlushD, FlushE y los seis registros de interés.

### PCF — Program Counter

El PC demuestra los dos modos de avance. Para instrucciones de 32 bits avanza de 4 en 4. Al llegar a c.beqz en 0x08, el incremento cae a 2, y PCPlus4F muestra 0x0A en lugar de 0x0C. Lo mismo ocurre en 0x10 para c.jalr, donde PCPlus4F da 0x12. Este patrón es la evidencia directa de que el módulo if_stage detecta instrucciones RVC y selecciona el adder correcto según IsCompressedF.

Las posiciones 0x0A, 0x12 y 0x14 aparecen en el waveform como búsquedas especulativas antes de que los saltos resuelvan en la etapa EX. Ninguna de esas instrucciones produce efecto en los registros, lo que confirman los valores finales de x8 y x11.

### IsCompressedF

La señal se eleva a 1 exactamente en los ciclos en que PCF vale 0x08 (c.beqz) y 0x10 (c.jalr). Permanece en 0 para todas las instrucciones de 32 bits. Esta señal es generada combinacionalmente por el decompressor evaluando `instr[1:0] != 2'b11`.

### InstrF — Instrucción expandida

InstrF siempre muestra la instrucción de 32 bits lista para el pipeline. Cuando PCF vale 0x08, la memoria entrega el halfword 0xC091, pero InstrF muestra 0x00048263 que es `beq x9, x0, 4` en formato RV32I estándar. Cuando PCF vale 0x10, la memoria entrega 0x9502 y InstrF muestra 0x000500E7 que es `jalr x1, x10, 0`. El pipeline nunca ve instrucciones de 16 bits; el decompressor las expande antes del registro IF/ID.

### PCSrcE — Fuente del próximo PC

| Valor | Momento | Significado |
|---|---|---|
| 0x0 | La mayor parte del tiempo | Avance secuencial |
| 0x1 | Cuando c.beqz resuelve en EX | Branch tomado; PC ← PCTargetE = 0x0C |
| 0x2 | Cuando c.jalr resuelve en EX | JALR; PC ← PCJalrE = 0x18 |
| 0x1 | Bucle final en 0x1C | beq x0, x0, 0 siempre tomado |

En el primer evento, branchCond se activa brevemente confirmando que la condición x9 == 0 se evalúa como verdadera. En el segundo, PCJalrE toma el valor de x10 (24 = 0x18), que la unidad de control usa como destino en lugar de PCTargetE.

### FlushD y FlushE

Ambas señales se activan simultáneamente en dos momentos: cuando c.beqz resuelve y cuando c.jalr resuelve. En cada caso, FlushE descarta lo que estaba en el registro ID/EX y FlushD descarta el registro IF/ID, eliminando las instrucciones de código muerto antes de que alcancen la etapa de escritura. Después del bucle final en 0x1C las señales pulsan de forma continua, ya que cada iteración del loop genera y descarta una nueva búsqueda especulativa.

### ALUResultE

| ALUResultE | Decimal | Instrucción | Operación |
|---|---|---|---|
| 0x0 | 0 | addi x9, x0, 0 | inicialización |
| 0x5 | 5 | addi x8, x0, 5 | inicialización |
| 0xC | 12 | c.beqz: PCTargetE | 0x08 + 4 = 0x0C |
| 0x18 | 24 | addi x10, x0, 24 | inicialización |
| 0x18 | 24 | c.jalr: PCJalrE | x10 + 0 = 24 |
| 0x4D | 77 | addi x12, x0, 77 | destino de c.jalr |

### Trazado de c.beqz por las cinco etapas

Para evidenciar que una instrucción comprimida atraviesa el pipeline igual que una de 32 bits, se sigue c.beqz x9, +4 (PC = 0x08) por cada etapa. En IF la memoria entrega 0xC091 y el decompressor lo expande a 0x00048263; un ciclo después aparece en InstrD ya decodificada como un beq ordinario. En EX la unidad de branch evalúa x9 == 0 (verdadero) y la ALU calcula 0x08 + 4 = 0x0C como destino; PCSrcE pasa a 0x1 y FlushD/FlushE se activan. La instrucción pasa por MEM sin acceder a memoria. En WB no escribe en ningún registro. Desde IF en adelante, el origen comprimido de la instrucción es invisible para el resto del pipeline.

### Registros finales

x8 se mantiene en 5 durante toda la simulación: la c.addi de código muerto en 0x0A nunca llegó a WB. x1 pasa a 0x12 cuando c.jalr completa su ciclo; ese valor es exactamente 0x10 + 2, lo que confirma que el incremento de dos bytes se usó para calcular la dirección de retorno. x11 permanece en 0 ya que la c.addi en 0x12 fue descartada por el segundo flush. x12 toma el valor 0x4D (77) confirmando que el flujo llegó a la dirección 0x18.

## 4.3 Comparativa de densidad de código

El programa ocupa 32 bytes. Si todas las instrucciones hubieran sido RV32I de 32 bits, el tamaño total sería 40 bytes (10 instrucciones × 4 bytes). La compresión de cuatro instrucciones al formato de 16 bits genera un ahorro de 8 bytes, una reducción del 20%.

En cuanto al rendimiento, c.beqz y c.jalr producen la misma penalización de dos ciclos que sus equivalentes RV32I. La resolución del destino ocurre en la etapa EX sin importar si la instrucción provino de un halfword o de una palabra completa, ya que el decompressor actúa antes del primer registro de pipeline y entrega una instrucción indistinguible de una RV32I estándar. El ahorro de densidad no introduce ciclos adicionales.
