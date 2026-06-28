module id_stage (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] InstrD,
    input  wire [31:0] PCD,
    input  wire [31:0] PCPlus4D,
    input  wire        RegWriteW,
    input  wire [4:0]  RdW,
    input  wire [31:0] ResultW,
    input  wire [2:0]  ImmSrcD,
    output wire [31:0] RD1D,
    output wire [31:0] RD2D,
    output wire [31:0] ImmExtD,
    output wire [4:0]  Rs1D,
    output wire [4:0]  Rs2D,
    output wire [4:0]  RdD,
    output wire [6:0]  opD,
    output wire [2:0]  funct3D,
    output wire        funct7b5D
);
    assign opD      = InstrD[6:0];
    assign funct3D  = InstrD[14:12];
    assign funct7b5D = InstrD[30];
    assign Rs1D     = InstrD[19:15];
    assign Rs2D     = InstrD[24:20];
    assign RdD      = InstrD[11:7];
    regfile rf (
        .clk(clk),
        .we3(RegWriteW),
        .a1(Rs1D),
        .a2(Rs2D),
        .a3(RdW),
        .wd3(ResultW),
        .rd1(RD1D),
        .rd2(RD2D)
    );
    extend ext (
        .instr(InstrD[31:7]),
        .immsrc(ImmSrcD),
        .immext(ImmExtD)
    );
endmodule