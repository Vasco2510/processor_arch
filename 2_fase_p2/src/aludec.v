module aludec(input        opb5,
              input  [2:0] funct3,
              input        funct7b5,
              input  [1:0] ALUOp,
              output [3:0] ALUControl);
  wire RtypeSub;
  reg  [3:0] ALUControl_reg;
  assign RtypeSub   = funct7b5 & opb5;
  assign ALUControl = ALUControl_reg;
  always @* case(ALUOp)
    2'b00: ALUControl_reg = 4'b0000;
    2'b01: ALUControl_reg = 4'b0001;
    2'b11: ALUControl_reg = 4'b1001;
    default: case(funct3)
        3'b000: ALUControl_reg = RtypeSub ? 4'b0001 : 4'b0000;
        3'b001: ALUControl_reg = 4'b0110;
        3'b010: ALUControl_reg = 4'b0101;
        3'b100: ALUControl_reg = 4'b0100;
        3'b101: ALUControl_reg = funct7b5 ? 4'b1000 : 4'b0111;
        3'b110: ALUControl_reg = 4'b0011;
        3'b111: ALUControl_reg = 4'b0010;
        default: ALUControl_reg = 4'b0000;
      endcase
  endcase
endmodule