module tb_test_flushing;
    reg clk;
    reg reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_flushing.mem")
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
        $display("=== Programa 4: Test Flushing ===");
    end
    initial begin
        #3000;
        $display("=== Simulacion finalizada ===");
        $display("x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d x6=%0d x30=%0d x31=%0d",
            dut.pipe.ids.rf.rf[1], dut.pipe.ids.rf.rf[2], dut.pipe.ids.rf.rf[3],
            dut.pipe.ids.rf.rf[4], dut.pipe.ids.rf.rf[5], dut.pipe.ids.rf.rf[6],
            dut.pipe.ids.rf.rf[30], dut.pipe.ids.rf.rf[31]);
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_flushing.vcd");
        $dumpvars(0, tb_test_flushing.dut.pipe.PCF);
        $dumpvars(0, tb_test_flushing.dut.pipe.InstrD);
        $dumpvars(0, tb_test_flushing.dut.pipe.FlushD);
        $dumpvars(0, tb_test_flushing.dut.pipe.FlushE);
        $dumpvars(0, tb_test_flushing.dut.pipe.PCSrcE);
    end
endmodule