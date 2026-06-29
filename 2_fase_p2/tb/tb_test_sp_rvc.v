module tb_test_sp_rvc;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("Z:/26-1/ARQUI/proy2/entrega2/2_fase_p2/mem/test_sp_rvc.mem")
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
        $display("=== TB: C.LWSP / C.SWSP (SP-relative) ===");
    end
    initial begin
        #1000;
        $display("--- Resultados ---");
        $display("x2  = %0d  (sp,    esperado: 0)",  dut.pipe.ids.rf.rf[2]);
        $display("x8  = %0d  (valor, esperado: 25)", dut.pipe.ids.rf.rf[8]);
        $display("x9  = %0d  (C.LWSP 0(sp),  esperado: 10)", dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d  (C.LWSP 4(sp),  esperado: 10)", dut.pipe.ids.rf.rf[10]);
        $display("x11 = %0d  (C.LWSP 8(sp),  esperado: 25)", dut.pipe.ids.rf.rf[11]);
        $display("x12 = %0d  (C.LWSP 20(sp), esperado: 25)", dut.pipe.ids.rf.rf[12]);
        $display("x13 = %0d  (C.LWSP 0(sp),  esperado: 10)", dut.pipe.ids.rf.rf[13]);
        $finish;
    end
    initial begin
        $dumpfile("Z:/26-1/ARQUI/proy2/entrega2/2_fase_p2/waveform/tb_test_sp_rvc.vcd");
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.PCF);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.InstrF);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.InstrD);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ifs.IsCompressedF);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ALUResultE);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ids.rf.rf[2]);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ids.rf.rf[8]);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ids.rf.rf[9]);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ids.rf.rf[10]);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ids.rf.rf[11]);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ids.rf.rf[12]);
        $dumpvars(0, tb_test_sp_rvc.dut.pipe.ids.rf.rf[13]);
    end
endmodule
