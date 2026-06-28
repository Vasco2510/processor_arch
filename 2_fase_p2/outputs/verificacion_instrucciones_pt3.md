# Verificación de Instrucciones RVC para Entrega 3

## Resultado: ✅ Todas las 10 instrucciones ya están implementadas

A continuación se detalla la ubicación y estado de cada instrucción en `src/decompressor.v`:

| # | Instrucción | Cuadrante | funct3 | Estado | Líneas |
|---|-------------|-----------|--------|--------|--------|
| 1 | **C.LW** | Q0 (00) | `010` | ✅ Implementada | 16-19 |
| 2 | **C.SW** | Q0 (00) | `110` | ✅ Implementada | 20-25 |
| 3 | **C.LWSP** | Q2 (10) | `010` | ✅ Implementada | 109-112 |
| 4 | **C.SWSP** | Q2 (10) | `110` | ✅ Implementada | 130-135 |
| 5 | **C.BEQZ** | Q1 (01) | `110` | ✅ Implementada | 84-91 |
| 6 | **C.BNEZ** | Q1 (01) | `111` | ✅ Implementada | 92-99 |
| 7 | **C.J** | Q1 (01) | `101` | ✅ Implementada | 76-83 |
| 8 | **C.JAL** | Q1 (01) | `001` | ✅ Implementada | 35-42 |
| 9 | **C.JR** | Q2 (10) | `100` (bit12=0, rs2=0) | ✅ Implementada | 114-116 |
| 10 | **C.JALR** | Q2 (10) | `100` (bit12=1, rs2=0) | ✅ Implementada | 121-123 |

## Arquitectura

El decompresor (`src/decompressor.v`) es lógica combinacional pura que expande instrucciones de 16 bits a 32 bits. Opera en la etapa IF, antes de que la instrucción ingrese al pipeline. El hazard unit y el controlador no distinguen RVC de RV32I.

## Cobertura de tests existentes

Los siguientes testbenches ejercitan estas instrucciones:

- `tb_test_10_instrucciones` → `mem/test_10_instrucciones.mem`
- `tb_programa_rvc1` → `mem/programa_rvc1.mem`
- `tb_programa_rvc2` → `mem/programa_rvc2.mem`

## Conclusión

No se requiere implementación adicional. El diseño actual soporta la totalidad de las 10 instrucciones solicitadas para la entrega 3.
