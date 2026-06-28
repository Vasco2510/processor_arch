module tb_test_branch_rvc;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_branch_rvc.mem")
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
        $display("=== TB Branch RVC: C.BEQZ, C.BNEZ ===");
    end
    initial begin
        #1000;
        $display("--- Resultados ---");
        $display("x8  = %0d (esperado:  1)",  dut.pipe.ids.rf.rf[8]);
        $display("x9  = %0d (esperado:  0)",  dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d (esperado:  0)",  dut.pipe.ids.rf.rf[10]);
        $display("x11 = %0d (esperado:  0)",  dut.pipe.ids.rf.rf[11]);
        $display("x12 = %0d (esperado:  1)",  dut.pipe.ids.rf.rf[12]);
        if (dut.pipe.ids.rf.rf[8]  === 32'd1  &&
            dut.pipe.ids.rf.rf[9]  === 32'd0  &&
            dut.pipe.ids.rf.rf[10] === 32'd0  &&
            dut.pipe.ids.rf.rf[11] === 32'd0  &&
            dut.pipe.ids.rf.rf[12] === 32'd1)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_branch_rvc.vcd");
        $dumpvars(0, tb_test_branch_rvc.dut.pipe.PCF);
        $dumpvars(0, tb_test_branch_rvc.dut.pipe.InstrF);
        $dumpvars(0, tb_test_branch_rvc.dut.pipe.InstrD);
        $dumpvars(0, tb_test_branch_rvc.dut.pipe.ifs.IsCompressedF);
        $dumpvars(0, tb_test_branch_rvc.dut.pipe.PCSrcE);
        $dumpvars(0, tb_test_branch_rvc.dut.pipe.exs.branchCond);
        $dumpvars(0, tb_test_branch_rvc.dut.pipe.exs.PCTargetE);
    end
endmodule
