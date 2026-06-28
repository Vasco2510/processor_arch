module mem_stage (
    input  wire        clk,
    input  wire        MemWriteM,
    input  wire [31:0] ALUResultM,
    input  wire [31:0] WriteDataM,
    output wire [31:0] ReadDataM
);
    dmem dm (
        .clk(clk),
        .we(MemWriteM),
        .a(ALUResultM),
        .wd(WriteDataM),
        .rd(ReadDataM)
    );
endmodule