module ex_stage (
    input  wire [31:0] RD1E,
    input  wire [31:0] RD2E,
    input  wire [31:0] ImmExtE,
    input  wire [31:0] PCE,
    input  wire [31:0] PCPlus4E,
    input  wire [4:0]  RdE,
    input  wire [3:0]  ALUControlE,
    input  wire        ALUSrcE,
    input  wire        BranchE,
    input  wire        JumpE,
    input  wire        JalrE,
    input  wire [2:0]  funct3E,
    input  wire [1:0]  ForwardAE,
    input  wire [1:0]  ForwardBE,
    input  wire [31:0] ALUResultM,
    input  wire [31:0] ResultW,
    output wire [31:0] ALUResultE,
    output wire [31:0] WriteDataE,
    output wire [31:0] PCTargetE,
    output wire [31:0] PCJalrE,
    output wire [1:0]  PCSrcE
);
    wire [31:0] SrcAE, SrcBE, SrcBE_alu;
    mux3 #(32) fwdA_mux (.d0(RD1E), .d1(ResultW), .d2(ALUResultM), .s(ForwardAE), .y(SrcAE));
    mux3 #(32) fwdB_mux (.d0(RD2E), .d1(ResultW), .d2(ALUResultM), .s(ForwardBE), .y(SrcBE));
    assign WriteDataE = SrcBE;
    assign SrcBE_alu  = ALUSrcE ? ImmExtE : SrcBE;
    alu alu_inst (
        .a(SrcAE),
        .b(SrcBE_alu),
        .alucontrol(ALUControlE),
        .result(ALUResultE),
        .zero()
    );
    adder branch_adder (.a(PCE), .b(ImmExtE), .y(PCTargetE));
    assign PCJalrE = {ALUResultE[31:1], 1'b0};
    wire eqE = (SrcAE == SrcBE);
    wire ltE = ($signed(SrcAE) < $signed(SrcBE));
    reg  branchCond;
    always @* case (funct3E)
        3'b000:  branchCond = eqE;
        3'b001:  branchCond = ~eqE;
        3'b100:  branchCond = ltE;
        3'b101:  branchCond = ~ltE;
        default: branchCond = 1'b0;
    endcase
    wire branchTakenE = BranchE & branchCond;
    assign PCSrcE = JalrE              ? 2'b10 :
                    (branchTakenE | JumpE) ? 2'b01 : 2'b00;
endmodule