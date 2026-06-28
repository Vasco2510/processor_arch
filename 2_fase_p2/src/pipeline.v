module pipeline #(
    parameter INSTR_MEM_FILE = "mem/programa1_no_dependencias.mem"
) (
    input  wire clk,
    input  wire reset
);
    wire [31:0] PCF, InstrF, PCPlus4F;
    reg  [31:0] PCD, InstrD, PCPlus4D;
    wire [31:0] RD1D, RD2D, ImmExtD;
    wire [4:0]  Rs1D, Rs2D, RdD;
    wire [6:0]  opD;
    wire [2:0]  funct3D;
    wire        funct7b5D;
    wire [1:0]  ResultSrcD;
    wire [2:0]  ImmSrcD;
    wire [3:0]  ALUControlD;
    wire        RegWriteD, MemWriteD, JumpD, JalrD, BranchD, ALUSrcD;
    reg  [31:0] PCE, PCPlus4E, RD1E, RD2E, ImmExtE;
    reg  [4:0]  Rs1E, Rs2E, RdE;
    reg  [2:0]  funct3E;
    reg  [3:0]  ALUControlE;
    reg  [1:0]  ResultSrcE;
    reg         RegWriteE, MemWriteE, JumpE, JalrE, BranchE, ALUSrcE;
    wire [31:0] ALUResultE, WriteDataE, PCTargetE, PCJalrE;
    wire [1:0]  PCSrcE;
    reg  [31:0] PCPlus4M, ALUResultM, WriteDataM;
    reg  [4:0]  RdM;
    reg  [1:0]  ResultSrcM;
    reg         RegWriteM, MemWriteM;
    wire [31:0] ReadDataM;
    reg  [31:0] PCPlus4W, ALUResultW, ReadDataW;
    reg  [4:0]  RdW;
    reg  [1:0]  ResultSrcW;
    reg         RegWriteW;
    wire [31:0] ResultW;
    wire        MemReadE = ResultSrcE[0];
    wire        PCSrcTakenE = (PCSrcE != 2'b00);
    wire [1:0]  ForwardAE, ForwardBE;
    wire        StallF, StallD, FlushD, FlushE;
    if_stage #(.INSTR_MEM_FILE(INSTR_MEM_FILE)) ifs (
        .clk(clk), .reset(reset),
        .StallF(StallF),
        .PCSrcE(PCSrcE),
        .PCTargetE(PCTargetE),
        .PCJalrE(PCJalrE),
        .PCF(PCF), .InstrF(InstrF),
        .PCPlus4F(PCPlus4F)
    );
    always @(posedge clk or posedge reset) begin
        if (reset || FlushD) begin
            PCD <= 32'b0; InstrD <= 32'b0; PCPlus4D <= 32'b0;
        end else if (!StallD) begin
            PCD <= PCF; InstrD <= InstrF; PCPlus4D <= PCPlus4F;
        end
    end
    id_stage ids (
        .clk(clk), .reset(reset),
        .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D),
        .RegWriteW(RegWriteW), .RdW(RdW), .ResultW(ResultW),
        .ImmSrcD(ImmSrcD),
        .RD1D(RD1D), .RD2D(RD2D), .ImmExtD(ImmExtD),
        .Rs1D(Rs1D), .Rs2D(Rs2D), .RdD(RdD),
        .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D)
    );
    controller_pipe ctrl (
        .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D),
        .ResultSrcD(ResultSrcD), .MemWriteD(MemWriteD), .ALUSrcD(ALUSrcD),
        .RegWriteD(RegWriteD), .JumpD(JumpD), .JalrD(JalrD), .BranchD(BranchD),
        .ImmSrcD(ImmSrcD), .ALUControlD(ALUControlD)
    );
    always @(posedge clk or posedge reset) begin
        if (reset || FlushE) begin
            PCE<=0; PCPlus4E<=0; RD1E<=0; RD2E<=0; ImmExtE<=0;
            Rs1E<=0; Rs2E<=0; RdE<=0; funct3E<=0; ALUControlE<=0; ResultSrcE<=0;
            RegWriteE<=0; MemWriteE<=0; JumpE<=0; JalrE<=0; BranchE<=0; ALUSrcE<=0;
        end else begin
            PCE<=PCD; PCPlus4E<=PCPlus4D; RD1E<=RD1D; RD2E<=RD2D; ImmExtE<=ImmExtD;
            Rs1E<=Rs1D; Rs2E<=Rs2D; RdE<=RdD; funct3E<=funct3D;
            ALUControlE<=ALUControlD; ResultSrcE<=ResultSrcD;
            RegWriteE<=RegWriteD; MemWriteE<=MemWriteD;
            JumpE<=JumpD; JalrE<=JalrD; BranchE<=BranchD; ALUSrcE<=ALUSrcD;
        end
    end
    ex_stage exs (
        .RD1E(RD1E), .RD2E(RD2E), .ImmExtE(ImmExtE),
        .PCE(PCE), .PCPlus4E(PCPlus4E), .RdE(RdE),
        .ALUControlE(ALUControlE), .ALUSrcE(ALUSrcE),
        .BranchE(BranchE), .JumpE(JumpE), .JalrE(JalrE), .funct3E(funct3E),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
        .ALUResultM(ALUResultM), .ResultW(ResultW),
        .ALUResultE(ALUResultE), .WriteDataE(WriteDataE),
        .PCTargetE(PCTargetE), .PCJalrE(PCJalrE), .PCSrcE(PCSrcE)
    );
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PCPlus4M<=0; ALUResultM<=0; WriteDataM<=0; RdM<=0;
            ResultSrcM<=0; RegWriteM<=0; MemWriteM<=0;
        end else begin
            PCPlus4M<=PCPlus4E; ALUResultM<=ALUResultE; WriteDataM<=WriteDataE; RdM<=RdE;
            ResultSrcM<=ResultSrcE; RegWriteM<=RegWriteE; MemWriteM<=MemWriteE;
        end
    end
    mem_stage mems (
        .clk(clk), .MemWriteM(MemWriteM),
        .ALUResultM(ALUResultM), .WriteDataM(WriteDataM), .ReadDataM(ReadDataM)
    );
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PCPlus4W<=0; ALUResultW<=0; ReadDataW<=0; RdW<=0; ResultSrcW<=0; RegWriteW<=0;
        end else begin
            PCPlus4W<=PCPlus4M; ALUResultW<=ALUResultM; ReadDataW<=ReadDataM; RdW<=RdM;
            ResultSrcW<=ResultSrcM; RegWriteW<=RegWriteM;
        end
    end
    wb_stage wbs (
        .ALUResultW(ALUResultW), .ReadDataW(ReadDataW), .PCPlus4W(PCPlus4W),
        .ResultSrcW(ResultSrcW), .ResultW(ResultW)
    );
    hazard_unit hu (
        .Rs1D(Rs1D), .Rs2D(Rs2D), .Rs1E(Rs1E), .Rs2E(Rs2E),
        .RdE(RdE), .RdM(RdM), .RdW(RdW),
        .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
        .MemReadE(MemReadE), .PCSrcTakenE(PCSrcTakenE),
        .StallF(StallF), .StallD(StallD), .FlushD(FlushD), .FlushE(FlushE),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE)
    );
endmodule