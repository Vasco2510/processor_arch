module maindec(input  [6:0] op,
               output       RegWrite,
               output [2:0] ImmSrc,
               output       ALUSrc,
               output       MemWrite,
               output [1:0] ResultSrc,
               output       Branch,
               output [1:0] ALUOp,
               output       Jump,
               output       Jalr); // esta no la vi en el SC
  reg [12:0] controls;
  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump, Jalr} = controls; // ¿considge que todos tengan 13 bits? 
  always @* case(op)
    7'b0000011: controls = 13'b1_000_1_0_01_0_00_0_0; // separando con _ para mas legible lectura
    7'b0100011: controls = 13'b0_001_1_1_00_0_00_0_0;
    7'b0110011: controls = 13'b1_000_0_0_00_0_10_0_0;
    7'b1100011: controls = 13'b0_010_0_0_00_1_01_0_0;
    7'b0010011: controls = 13'b1_000_1_0_00_0_10_0_0;
    7'b1101111: controls = 13'b1_011_0_0_10_0_00_1_0;
    7'b1100111: controls = 13'b1_000_1_0_10_0_00_1_1;
    7'b0110111: controls = 13'b1_100_1_0_00_0_11_0_0;
    default:    controls = 13'b0_000_0_0_00_0_00_0_0;
  endcase
endmodule