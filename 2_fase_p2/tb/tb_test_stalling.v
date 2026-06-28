module tb_test_stalling;
    reg clk;
    reg reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_stalling.mem")
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
        $display("=== Programa 3: Test Stalling ===");
    end
    initial begin
        #3000;
        $display("=== Simulacion finalizada ===");
        $display("x1=%0d x2=%0d x6=%0d x7=%0d", dut.pipe.ids.rf.rf[1], dut.pipe.ids.rf.rf[2],
            dut.pipe.ids.rf.rf[6], dut.pipe.ids.rf.rf[7]);
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_stalling.vcd");
        $dumpvars(0, tb_test_stalling.dut.pipe.PCF);
        $dumpvars(0, tb_test_stalling.dut.pipe.InstrD);
        $dumpvars(0, tb_test_stalling.dut.pipe.StallF);
        $dumpvars(0, tb_test_stalling.dut.pipe.StallD);
        $dumpvars(0, tb_test_stalling.dut.pipe.FlushE);
    end
endmodule