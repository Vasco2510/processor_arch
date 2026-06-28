module tb_programa_rvc1;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/programa_rvc1.mem")
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
        $display("=== TB RVC1: programa RVC puro ===");
    end
    initial begin
        #500;
        $display("--- Resultados (ciclo ~50) ---");
        $display("x1 = %0d  (esperado: 19)", dut.pipe.ids.rf.rf[1]);
        $display("x2 = %0d  (esperado:  6)", dut.pipe.ids.rf.rf[2]);
        if (dut.pipe.ids.rf.rf[1] === 32'd19 &&
            dut.pipe.ids.rf.rf[2] === 32'd6)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_programa_rvc1.vcd");
        $dumpvars(0, tb_programa_rvc1.dut.pipe.PCF);
        $dumpvars(0, tb_programa_rvc1.dut.pipe.InstrF);
        $dumpvars(0, tb_programa_rvc1.dut.pipe.InstrD);
        $dumpvars(0, tb_programa_rvc1.dut.pipe.ifs.IsCompressedF);
    end
endmodule