module tb_test_10_instrucciones;
    reg clk, reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_10_instrucciones.mem")
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
        $display("===  10 instrucciones RVC ===");
    end
    initial begin
        #1500;
        $display("--- Resultados ---");
        $display("x8  = %0d  (esperado: 13)",  dut.pipe.ids.rf.rf[8]);
        $display("x9  = %0d  (esperado: 16)",  dut.pipe.ids.rf.rf[9]);
        $display("x10 = %0d  (esperado:  5)",  dut.pipe.ids.rf.rf[10]);
        $display("x11 = %0d  (esperado:  7)",  dut.pipe.ids.rf.rf[11]);
        $display("x12 = %0d  (esperado:  4)",  dut.pipe.ids.rf.rf[12]);
        $display("x13 = %0d  (esperado: 10)",  dut.pipe.ids.rf.rf[13]);
        $display("x14 = %0d  (esperado:  2)",  dut.pipe.ids.rf.rf[14]);
        $display("x15 = %0d  (esperado: 8192)", dut.pipe.ids.rf.rf[15]);
        if (dut.pipe.ids.rf.rf[8]  === 32'd13  &&
            dut.pipe.ids.rf.rf[9]  === 32'd16  &&
            dut.pipe.ids.rf.rf[10] === 32'd5   &&
            dut.pipe.ids.rf.rf[11] === 32'd7   &&
            dut.pipe.ids.rf.rf[12] === 32'd4   &&
            dut.pipe.ids.rf.rf[13] === 32'd10  &&
            dut.pipe.ids.rf.rf[14] === 32'd2   &&
            dut.pipe.ids.rf.rf[15] === 32'd8192)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_10_instrucciones.vcd");
        $dumpvars(0, tb_test_10_instrucciones.dut.pipe.PCF);
        $dumpvars(0, tb_test_10_instrucciones.dut.pipe.InstrF);
        $dumpvars(0, tb_test_10_instrucciones.dut.pipe.InstrD);
        $dumpvars(0, tb_test_10_instrucciones.dut.pipe.ifs.IsCompressedF);
        $dumpvars(0, tb_test_10_instrucciones.dut.pipe.ALUResultE);
    end
endmodule