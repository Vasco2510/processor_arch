# AGENTS.md — RISC-V Pipeline con extensión RVC (Parte 2)

## Simulación

**iverilog** (sin Makefile):
```sh
iverilog -o waveform/sim.out src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v src/ex_stage.v src/mem_stage.v src/wb_stage.v src/controller_pipe.v src/maindec.v src/aludec.v src/hazard_unit.v src/extend.v src/regfile.v src/imem.v src/dmem.v src/alu.v src/adder.v src/flopr.v src/mux2.v src/mux3.v src/decompressor.v tb/<testbench>.v && vvp waveform/sim.out
```

13 testbenches en `tb/` (ver `simulation_guide.md`). Waveform → `waveform/<testbench>.vcd`.

**Vivado**: agregar `src/*.v` como design sources, `tb/<testbench>.v` como simulation source.

## Arquitectura

- **`top_pipe.v`** es el top-level. Parámetro `INSTR_MEM_FILE` selecciona qué `.mem` cargar.
- **`pipeline.v`** orquesta las 5 etapas (IF/ID/EX/MEM/WB) y el hazard unit.
- **`if_stage.v`** contiene el decompressor; el PC avanza +2 (RVC) o +4 (RV32I).
- **`decompressor.v`** es lógica combinacional pura — expande instrucciones de 16 bits a 32 bits.
  Detecta comprimidas por `instr16[1:0] != 2'b11`.
- **`imem.v`** almacena en halfwords de 16 bits (128×16), lee siempre 32 bits alineados a 2 bytes.
- **`regfile.v`** tiene un `initial` que zeroea todos los registros — necesario porque RVC lee x8–x15 como fuente.
- Hazard unit **no** distingue RVC de RV32I; el decompressor ya expandió antes.

## Formato de archivos .mem

Cada instrucción de 32 bits `AAAABBBB` se almacena en **dos líneas** (little-endian halfwords):
```
BBBB    ← halfword bajo (bits 15:0), dirección par
AAAA    ← halfword alto (bits 31:16), dirección par+2
```
Instrucciones RVC de 16 bits ocupan **una sola línea**. Se permiten comentarios con `//`.

## Convenios de testbenches

- Usan `top_pipe #(.INSTR_MEM_FILE("mem/..."))` para seleccionar programa.
- Jerarquía para acceder a registros: `dut.pipe.ids.rf.rf[<n>]`.
- Dump de señales con `$dumpfile("waveform/<nombre>.vcd")` y `$dumpvars`.
- Reset activo por ~25ns; clock period 10ns (toggle cada 5ns).
- PASS/FAIL con `$display`.
