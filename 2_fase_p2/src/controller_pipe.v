module controller_pipe (
    input  wire [6:0] opD,
    input  wire [2:0] funct3D,
    input  wire       funct7b5D,
    output wire [1:0] ResultSrcD,
    output wire       MemWriteD,
    output wire       ALUSrcD,
    output wire       RegWriteD,
    output wire       JumpD,
    output wire       JalrD,
    output wire       BranchD,
    output wire [2:0] ImmSrcD,
    output wire [3:0] ALUControlD
);
    wire [1:0] ALUOp;
    maindec md (
        .op(opD),
        .RegWrite(RegWriteD),
        .ImmSrc(ImmSrcD),
        .ALUSrc(ALUSrcD),
        .MemWrite(MemWriteD),
        .ResultSrc(ResultSrcD),
        .Branch(BranchD),
        .ALUOp(ALUOp),
        .Jump(JumpD),
        .Jalr(JalrD)
    );
    aludec ad (
        .opb5(opD[5]),
        .funct3(funct3D),
        .funct7b5(funct7b5D),
        .ALUOp(ALUOp),
        .ALUControl(ALUControlD)
    );
endmodule