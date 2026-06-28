# Skill de Redacción — Informe Técnico de Arquitectura de Computadores

## Estilo general

- **Formal y académico**, tono de paper técnico o informe de ingeniería.
- **Sin emojis**, sin flechas (`→`, `⇒`), sin símbolos informales.
- **Voz activa y precisa.** Preferir "la expansión reconstruye" sobre "se reconstruye".
- **Conectores formales:** "el lector notará que", "cabe destacar", "es importante señalar",
  "como era de esperarse", "de manera análoga", "por el contrario", "en contraste".
- **Fluidez orgánica:** cada párrafo debe conectar con el anterior. No iniciar una
  sección con una tabla o bloque de código sin antes anunciarlo en al menos dos líneas.

## Estructura por instrucción

Cada instrucción se redacta con la siguiente plantilla, en este orden:

### 1. Apertura

1–2 párrafos que presentan la instrucción:
- Su propósito semántico (qué hace).
- Su sintaxis en ensamblador RVC.
- A qué instrucción RV32I se expande.
- En qué cuadrante y formato RVC se encuentra.
- Contexto: ¿por qué existe esta versión comprimida?

### 2. Encoding de 16 bits

- **Anunciar la tabla:** "La codificación de la instrucción en su formato de 16 bits
  se presenta en la tabla siguiente. En ella, el lector puede observar..."
- **Insertar tabla markdown** con las posiciones de bits (15–13, 12, 11–7, etc.) y
  los campos correspondientes.
- **Analizar la tabla:** explicar la distribución de los campos, por qué ciertos bits
  están dispersos, cómo se reconstruye el inmediato, cómo se mapean los registros.

### 3. Código de expansión

- **Anunciar el código:** "El fragmento del descompresor que realiza la expansión
  de esta instrucción se encuentra en las líneas X a Y del archivo `decompressor.v`."
- **Insertar bloque Verilog** con las líneas relevantes (sin numeración de líneas).
- **Explicar cada campo de la expansión:**
  - Por qué ese opcode.
  - Cómo se construye el inmediato (despiece bit por bit).
  - De dónde vienen los registros fuente y destino.
  - Por qué ciertos bits se fuerzan a cero.
  - Cómo se relaciona la expansión con el formato RV32I destino (I-type, S-type, B-type, J-type, R-type, U-type).
  - Si hay casos especiales o subcondiciones (bit12, rs2=0, etc.), explicarlos.

### 4. Implicaciones en el datapath

- **Si no hay cambios:** explicar por qué (el opcode ya está soportado en maindec,
  el funct3 ya está decodificado en ex_stage, el hazard unit no necesita modificaciones).
  Incluir referencias a los módulos específicos (`maindec.v`, `ex_stage.v`, `hazard_unit.v`).
- **Si hay cambios:** describir el problema que motiva el cambio, mostrar el código
  antes y después, y analizar el impacto funcional.

## Reglas para recursos visuales

1. **Toda tabla** debe ir precedida de un párrafo que anuncie su contenido y propósito.
2. **Toda tabla** debe ir seguida de un análisis que interprete lo que muestra.
3. **Todo bloque de código** debe ir precedido de una línea que lo introduzca
   (archivo, líneas, contexto).
4. **Todo bloque de código** debe ir seguido de una explicación detallada de su
   funcionamiento, no de una mera paráfrasis.

## Organización del documento

```
# Título del informe

## 4. Implementación de instrucciones

### 4.1 [Grupo: nombre del grupo]

#### 4.1.1 [Instrucción 1]
  - Apertura
  - Encoding
  - Código explicado
  - Implicaciones en datapath

#### 4.1.2 [Instrucción 2]
  - (misma estructura)

### 4.2 [Grupo siguiente]
  - ...

### 4.N Cambios en el datapath (sección consolidada)
  - Solo si varias instrucciones comparten un mismo cambio
  - O si no hubo cambios, explicar por qué
```

## Ejemplo de apertura aceptable

> "La instrucción C.LW carga una palabra de 32 bits desde la memoria de datos
> hacia un registro destino del rango comprimido. Su sintaxis ensamblador es
> `c.lw rd', offset(rs1')`, donde tanto `rd'` como `rs1'` pertenecen al conjunto
> de registros x8 a x15. La dirección de memoria se obtiene sumando el valor del
> registro base `rs1'` con un desplazamiento de 7 bits, cuyo valor se encuentra
> implícitamente multiplicado por 2 (alineación a halfword). Esta instrucción
> constituye la versión compacta de la instrucción estándar `lw rd, offset(rs1)`
> del repertorio RV32I, y su propósito principal es reducir el tamaño del código
> en programas donde los accesos a memoria utilizan registros del rango bajo."

## Ejemplo de apertura NO aceptable

> "Sintaxis RVC: c.lw rd', offset(rs1'). Donde rd' y rs1' mapean a x8 + n."

Motivos: es improvisado, no hay fluidez, no anuncia nada, no hay análisis posterior.
