module tb_test_instrucciones;
    reg clk;
    reg reset;
    top_pipe #(
        .INSTR_MEM_FILE("mem/test_instrucciones.mem")
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
        $display("=== Test de las 24 instrucciones del Cuadro 1 ===");
    end
    initial begin
        #3000;
        $display("=== Simulacion finalizada ===");
        $display("x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d x6=%0d x7=%0d x8=%0d",
            dut.pipe.ids.rf.rf[1], dut.pipe.ids.rf.rf[2], dut.pipe.ids.rf.rf[3], dut.pipe.ids.rf.rf[4],
            dut.pipe.ids.rf.rf[5], dut.pipe.ids.rf.rf[6], dut.pipe.ids.rf.rf[7], dut.pipe.ids.rf.rf[8]);
        $display("x9=%0d x10=%0d x11=%0d x12=%0d x13=%0d x14=%0d x15=%0d x16=%0d",
            dut.pipe.ids.rf.rf[9], dut.pipe.ids.rf.rf[10], dut.pipe.ids.rf.rf[11], dut.pipe.ids.rf.rf[12],
            dut.pipe.ids.rf.rf[13], dut.pipe.ids.rf.rf[14], dut.pipe.ids.rf.rf[15], dut.pipe.ids.rf.rf[16]);
        $display("x17=0x%0h x18=%0d x19=%0d x20=%0d x21=%0d x22=%0d x23=%0d x24=%0d x25=%0d",
            dut.pipe.ids.rf.rf[17], dut.pipe.ids.rf.rf[18], dut.pipe.ids.rf.rf[19], dut.pipe.ids.rf.rf[20],
            dut.pipe.ids.rf.rf[21], dut.pipe.ids.rf.rf[22], dut.pipe.ids.rf.rf[23], dut.pipe.ids.rf.rf[24],
            dut.pipe.ids.rf.rf[25]);
        $finish;
    end
    initial begin
        $dumpfile("waveform/tb_test_instrucciones.vcd");
        $dumpvars(0, tb_test_instrucciones.dut.pipe.PCF);
        $dumpvars(0, tb_test_instrucciones.dut.pipe.InstrF);
        $dumpvars(0, tb_test_instrucciones.dut.pipe.InstrD);
        $dumpvars(0, tb_test_instrucciones.dut.pipe.ALUResultE);
    end
endmodule