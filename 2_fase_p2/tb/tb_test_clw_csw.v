module tb_test_clw_csw;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("Z:/26-1/ARQUI/proy2/entrega2/2_fase_p2/mem/test_clw_csw.mem")
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
        $display("=== TB: C.LW / C.SW (Quadrant 0, _p mapping) ===");
    end
    initial begin
        #1000;
        $display("--- Resultados ---");
        $display("x8  = %0d  (base ptr, esperado: 0)",  dut.pipe.ids.rf.rf[8]);
        $display("x9  = %0d  (C.ADDI 10+15, esperado: 25)", dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d  (C.LW  0(x8), esperado: 10)", dut.pipe.ids.rf.rf[10]);
        $display("x11 = %0d  (C.LW  8(x8), esperado: 10)", dut.pipe.ids.rf.rf[11]);
        $display("x12 = %0d  (C.LW 20(x8), esperado: 25)", dut.pipe.ids.rf.rf[12]);
        $display("x13 = %0d  (C.LW  0(x8), esperado: 10)", dut.pipe.ids.rf.rf[13]);
        $finish;
    end
    initial begin
        $dumpfile("Z:/26-1/ARQUI/proy2/entrega2/2_fase_p2/waveform/tb_test_clw_csw.vcd");
        $dumpvars(0, tb_test_clw_csw.dut.pipe.PCF);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.InstrF);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.InstrD);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ifs.IsCompressedF);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ALUResultE);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ids.rf.rf[8]);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ids.rf.rf[9]);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ids.rf.rf[10]);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ids.rf.rf[11]);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ids.rf.rf[12]);
        $dumpvars(0, tb_test_clw_csw.dut.pipe.ids.rf.rf[13]);
    end
endmodule
