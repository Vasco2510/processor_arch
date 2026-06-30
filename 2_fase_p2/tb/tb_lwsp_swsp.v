// tb_waly_lwsp_swsp.v — Testbench: Waly — c.lwsp y c.swsp
//
// Señales monitoreadas según el Plan de Simulaciones:
//   1. InstrF        → instrucción expandida a 32 bits (verifica que rs1 = x2 = 00010)
//   2. IsCompressedF → confirma que el descompresor detecta instrucción de 16 bits
//   3. ImmExtD       → inmediato extendido (offset = 0 para este test)
//   4. ALUResultE    → dirección efectiva calculada (x2 + 0 = 32)
//   5. WriteDataM    → dato escrito en memoria durante c.swsp (debería ser 7)
//   6. ReadDataM     → dato leído de memoria durante c.lwsp (debería ser 7)
//   7. MemWriteM     → se activa (1) solo durante c.swsp
//   8. ResultSrcW    → bit[0]=1 indica que resultado viene de memoria (c.lwsp)

module tb_waly_lwsp_swsp;

    reg clk, reset;

    top_pipe #(
        .INSTR_MEM_FILE("mem/test_waly_lwsp_swsp.mem")
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
        $display("=== TEST WALY: c.lwsp y c.swsp ===");
        $display("Programa: addi x2=32, addi x9=7, c.swsp x9 0(x2), c.lwsp x10 0(x2)");
    end

    // Verificación final
    initial begin
        #800;
        $display("");
        $display("--- Resultados finales ---");
        $display("x2  = %0d  (esperado: 32)", dut.pipe.ids.rf.rf[2]);
        $display("x9  = %0d   (esperado:  7)", dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d   (esperado:  7)", dut.pipe.ids.rf.rf[10]);

        if (dut.pipe.ids.rf.rf[2]  === 32'd32 &&
            dut.pipe.ids.rf.rf[9]  === 32'd7  &&
            dut.pipe.ids.rf.rf[10] === 32'd7)
            $display("PASS");
        else
            $display("FAIL");

        $finish;
    end

    // VCD para GTKWave — todas las señales del plan
    initial begin
        $dumpfile("waveform/tb_waly_lwsp_swsp.vcd");

        // --- PC e instrucción ---
        $dumpvars(0, dut.pipe.PCF);
        $dumpvars(0, dut.pipe.InstrF);         // instrucción 32 bits expandida
        $dumpvars(0, dut.pipe.InstrD);         // misma, 1 ciclo después
        $dumpvars(0, dut.pipe.ifs.IsCompressedF); // 1 si RVC, 0 si RV32I

        // --- Decode: rs1 forzado a x2, inmediato ---
        $dumpvars(0, dut.pipe.Rs1D);           // debe ser 00010 (x2) en lwsp/swsp
        $dumpvars(0, dut.pipe.ImmExtD);        // offset extendido (0 en este test)

        // --- Execute: cálculo de dirección ---
        $dumpvars(0, dut.pipe.ALUResultE);     // dirección = x2 + 0 = 32

        // --- Memory: escritura y lectura ---
        $dumpvars(0, dut.pipe.WriteDataM);     // dato a escribir (7 durante c.swsp)
        $dumpvars(0, dut.pipe.ReadDataM);      // dato leído (7 durante c.lwsp)
        $dumpvars(0, dut.pipe.MemWriteM);      // 1 solo durante c.swsp
        $dumpvars(0, dut.pipe.ALUResultM);     // dirección en etapa MEM (32)

        // --- Writeback: origen del resultado ---
        $dumpvars(0, dut.pipe.ResultSrcW);     // 01 → resultado de memoria (c.lwsp)

        // --- Registros finales ---
        $dumpvars(0, dut.pipe.ids.rf.rf[2]);   // x2 = 32
        $dumpvars(0, dut.pipe.ids.rf.rf[9]);   // x9 = 7
        $dumpvars(0, dut.pipe.ids.rf.rf[10]);  // x10 = 7
    end

endmodule
