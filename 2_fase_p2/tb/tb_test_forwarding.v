module tb_test_forwarding;
    reg clk;
    reg reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_forwarding.mem")
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
        $display("=== Programa 2: Test Forwarding ===");
    end
    initial begin
        #3000;
        $display("=== Simulacion finalizada ===");
        $display("x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d x6=%0d x10=%0d",
            dut.pipe.ids.rf.rf[1], dut.pipe.ids.rf.rf[2], dut.pipe.ids.rf.rf[3],
            dut.pipe.ids.rf.rf[4], dut.pipe.ids.rf.rf[5], dut.pipe.ids.rf.rf[6],
            dut.pipe.ids.rf.rf[10]);
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_forwarding.vcd");
        $dumpvars(0, tb_test_forwarding.dut.pipe.PCF);
        $dumpvars(0, tb_test_forwarding.dut.pipe.InstrD);
        $dumpvars(0, tb_test_forwarding.dut.pipe.ForwardAE);
        $dumpvars(0, tb_test_forwarding.dut.pipe.ForwardBE);
        $dumpvars(0, tb_test_forwarding.dut.pipe.ALUResultE);
    end
endmodule