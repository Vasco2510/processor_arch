module hazard_unit (
    input  wire [4:0] Rs1D, Rs2D,
    input  wire [4:0] Rs1E, Rs2E,
    input  wire [4:0] RdE, RdM, RdW,
    input  wire       RegWriteM, RegWriteW,
    input  wire       MemReadE,
    input  wire       PCSrcTakenE,
    output wire       StallF, StallD,
    output wire       FlushD, FlushE,
    output wire [1:0] ForwardAE, ForwardBE
);
    assign ForwardAE = (Rs1E != 0 && Rs1E == RdM && RegWriteM) ? 2'b10 :
                       (Rs1E != 0 && Rs1E == RdW && RegWriteW) ? 2'b01 : 2'b00;
    assign ForwardBE = (Rs2E != 0 && Rs2E == RdM && RegWriteM) ? 2'b10 :
                       (Rs2E != 0 && Rs2E == RdW && RegWriteW) ? 2'b01 : 2'b00;
    wire lwStall = MemReadE && (RdE != 0) && ((Rs1D == RdE) || (Rs2D == RdE));
    assign StallF = lwStall;
    assign StallD = lwStall;
    assign FlushD = PCSrcTakenE;
    assign FlushE = lwStall | PCSrcTakenE;
endmodule