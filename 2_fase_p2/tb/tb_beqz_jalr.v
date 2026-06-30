// tb_valentino_beqz_jalr.v — Testbench: Valentino — c.beqz y c.jalr
//
// Señales monitoreadas según el Plan de Simulaciones:
//   1. PCF / PCPlus4F (= PCIncF)  → muestra avance +2 (RVC) y saltos
//   2. IsCompressedF              → confirma detección de instrucción de 16 bits
//   3. PCSrcE [1:0]               → 00=secuencial, 01=branch, 10=JALR
//   4. PCTargetE                  → PC + offset (destino de c.beqz)
//   5. PCJalrE                    → rs1 + 0 (destino de c.jalr)
//   6. FlushD                     → 1 cuando se descarta la etapa ID
//   7. FlushE                     → 1 cuando se descarta la etapa EX
//   8. branchCond (en ex_stage)   → 1 si la condición del branch es verdadera

module tb_valentino_beqz_jalr;

    reg clk, reset;

    top_pipe #(
        .INSTR_MEM_FILE("mem/test_valentino_beqz_jalr.mem")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock: periodo 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset inicial
    initial begin
        reset = 1;
        #25;
        reset = 0;
        $display("=== TEST VALENTINO: c.beqz y c.jalr ===");
        $display("Programa: addi x9=0, addi x8=5, c.beqz x9+4, [dead], addi x10=24, c.jalr x10, [dead], addi x12=77");
    end

    // Verificación final
    initial begin
        #1200;
        $display("");
        $display("--- Resultados finales ---");
        $display("x1  = %0d  (esperado: 18)  [return addr c.jalr = 0x12]", dut.pipe.ids.rf.rf[1]);
        $display("x8  = %0d   (esperado:  5)  [NO 6 => c.beqz saltó correctamente]", dut.pipe.ids.rf.rf[8]);
        $display("x9  = %0d   (esperado:  0)", dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d  (esperado: 24)  [dirección destino c.jalr]", dut.pipe.ids.rf.rf[10]);
        $display("x11 = %0d   (esperado:  0)  [NO 1 => c.jalr saltó correctamente]", dut.pipe.ids.rf.rf[11]);
        $display("x12 = %0d  (esperado: 77)  [llegamos al destino de c.jalr]", dut.pipe.ids.rf.rf[12]);

        if (dut.pipe.ids.rf.rf[1]  === 32'd18 &&
            dut.pipe.ids.rf.rf[8]  === 32'd5  &&
            dut.pipe.ids.rf.rf[9]  === 32'd0  &&
            dut.pipe.ids.rf.rf[10] === 32'd24 &&
            dut.pipe.ids.rf.rf[11] === 32'd0  &&
            dut.pipe.ids.rf.rf[12] === 32'd77)
            $display("PASS");
        else
            $display("FAIL");

        $finish;
    end

    // VCD para GTKWave — señales del Plan de Simulaciones
    initial begin
        $dumpfile("waveform/tb_valentino_beqz_jalr.vcd");

        // --- PC y detección RVC ---
        $dumpvars(0, dut.pipe.PCF);
        $dumpvars(0, dut.pipe.PCPlus4F);           // PCIncF: +2 si RVC, +4 si RV32I
        $dumpvars(0, dut.pipe.InstrF);             // instrucción expandida a 32 bits
        $dumpvars(0, dut.pipe.InstrD);
        $dumpvars(0, dut.pipe.ifs.IsCompressedF);  // 1 para c.beqz y c.jalr

        // --- Control de flujo (etapa EX) ---
        $dumpvars(0, dut.pipe.PCSrcE);             // 00/01/10 — clave del análisis
        $dumpvars(0, dut.pipe.PCTargetE);          // PC + offset (c.beqz)
        $dumpvars(0, dut.pipe.PCJalrE);            // rs1 + 0   (c.jalr)
        $dumpvars(0, dut.pipe.exs.branchCond);     // condición evaluada del branch

        // --- Flush del pipeline (hazard_unit) ---
        $dumpvars(0, dut.pipe.FlushD);             // descarta instrucción en ID
        $dumpvars(0, dut.pipe.FlushE);             // descarta instrucción en EX

        // --- Registros para verificar comportamiento ---
        $dumpvars(0, dut.pipe.ids.rf.rf[1]);       // x1 = return addr (c.jalr)
        $dumpvars(0, dut.pipe.ids.rf.rf[8]);       // x8 = 5 (no debe cambiar)
        $dumpvars(0, dut.pipe.ids.rf.rf[9]);       // x9 = 0
        $dumpvars(0, dut.pipe.ids.rf.rf[10]);      // x10 = 24
        $dumpvars(0, dut.pipe.ids.rf.rf[11]);      // x11 = 0 (no debe cambiar)
        $dumpvars(0, dut.pipe.ids.rf.rf[12]);      // x12 = 77
    end

endmodule
