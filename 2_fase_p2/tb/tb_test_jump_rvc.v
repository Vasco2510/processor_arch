module tb_test_jump_rvc;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_jump_rvc.mem")
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
        $display("=== TB Jump RVC: C.J, C.JAL, C.JR, C.JALR ===");
    end
    initial begin
        #1000;
        $display("--- Resultados ---");
        $display("x8  = %0d (esperado:   5)",  dut.pipe.ids.rf.rf[8]);
        $display("x9  = %0d (esperado:  10)",  dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d (esperado:  20)",  dut.pipe.ids.rf.rf[10]);
        if (dut.pipe.ids.rf.rf[8]  === 32'd5   &&
            dut.pipe.ids.rf.rf[9]  === 32'd10  &&
            dut.pipe.ids.rf.rf[10] === 32'd20)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_jump_rvc.vcd");
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.PCF);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.InstrF);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.InstrD);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.ifs.IsCompressedF);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.PCSrcE);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.RdE);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.ALUResultE);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.exs.PCTargetE);
        $dumpvars(0, tb_test_jump_rvc.dut.pipe.exs.PCJalrE);
    end
endmodule
