module if_stage #(
    parameter INSTR_MEM_FILE = "mem/programa1_no_dependencias.mem"
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        StallF,
    input  wire [1:0]  PCSrcE,
    input  wire [31:0] PCTargetE,
    input  wire [31:0] PCJalrE,
    output wire [31:0] PCF,
    output wire [31:0] InstrF,
    output wire [31:0] PCPlus4F
);
    wire [31:0] PCNextF, PCIncF, PCMuxOut;
    wire [31:0] RawInstrF;
    wire        IsCompressedF;
    wire [31:0] DecompInstrF;
    flopr #(32) pcreg (.clk(clk), .reset(reset), .d(PCNextF), .q(PCF));
    imem #(.MEM_FILE(INSTR_MEM_FILE)) im (.a(PCF), .rd(RawInstrF));
    decompressor decomp (
        .instr16(RawInstrF[15:0]),
        .instr32(DecompInstrF),
        .is_compressed(IsCompressedF)
    );
    assign InstrF = IsCompressedF ? DecompInstrF : RawInstrF;
    assign PCIncF   = IsCompressedF ? (PCF + 32'd2) : (PCF + 32'd4);
    assign PCPlus4F = PCIncF;
    mux3 #(32) pcmux (.d0(PCIncF), .d1(PCTargetE), .d2(PCJalrE), .s(PCSrcE), .y(PCMuxOut));
    assign PCNextF = StallF ? PCF : PCMuxOut;
endmodule