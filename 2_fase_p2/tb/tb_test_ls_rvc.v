module tb_test_ls_rvc;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_ls_rvc.mem")
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
        $display("=== TB Load/Store RVC: C.LW, C.SW, C.LWSP, C.SWSP ===");
    end
    initial begin
        #1000;
        $display("--- Resultados ---");
        $display("x8  = %0d (esperado: 16)",  dut.pipe.ids.rf.rf[8]);
        $display("x9  = %0d (esperado:  7)",  dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d (esperado:  7)",  dut.pipe.ids.rf.rf[10]);
        $display("x11 = %0d (esperado:  7)",  dut.pipe.ids.rf.rf[11]);
        $display("x2  = %0d (esperado: 16)",  dut.pipe.ids.rf.rf[2]);
        if (dut.pipe.ids.rf.rf[8]  === 32'd16 &&
            dut.pipe.ids.rf.rf[9]  === 32'd7  &&
            dut.pipe.ids.rf.rf[10] === 32'd7  &&
            dut.pipe.ids.rf.rf[11] === 32'd7  &&
            dut.pipe.ids.rf.rf[2]  === 32'd16)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_ls_rvc.vcd");
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.PCF);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.InstrF);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.InstrD);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.ifs.IsCompressedF);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.ALUResultE);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.ids.rf.rf[8]);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.ids.rf.rf[9]);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.ids.rf.rf[10]);
        $dumpvars(0, tb_test_ls_rvc.dut.pipe.ids.rf.rf[11]);
    end
endmodule
