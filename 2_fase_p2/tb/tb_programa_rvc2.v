module tb_programa_rvc2;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/programa_rvc2.mem")
    ) dut (
        .clk(clk),
        .reset(reset)
    );
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        reset = 1;
        #25;
        reset = 0;
        $display("=== TB RVC2: programa mixto RVC + RV32I ===");
    end
    initial begin
        #500;
        $display("--- Resultados (ciclo ~50) ---");
        $display("x1 = %0d  (esperado: 20)", dut.pipe.ids.rf.rf[1]);
        $display("x2 = %0d  (esperado: 10)", dut.pipe.ids.rf.rf[2]);
        $display("x3 = %0d  (esperado: 15)", dut.pipe.ids.rf.rf[3]);
        if (dut.pipe.ids.rf.rf[1] === 32'd20 &&
            dut.pipe.ids.rf.rf[2] === 32'd10 &&
            dut.pipe.ids.rf.rf[3] === 32'd15)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_programa_rvc2.vcd");
        $dumpvars(0, tb_programa_rvc2.dut.pipe.PCF);
        $dumpvars(0, tb_programa_rvc2.dut.pipe.InstrF);
        $dumpvars(0, tb_programa_rvc2.dut.pipe.InstrD);
        $dumpvars(0, tb_programa_rvc2.dut.pipe.ifs.IsCompressedF);
    end
endmodule