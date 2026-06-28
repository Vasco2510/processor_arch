module alu(input  [31:0] a, b,
           input  [3:0]  alucontrol,
           output [31:0] result,
           output        zero);
  reg [31:0] result_reg;
  assign result = result_reg;
  always @* case (alucontrol)
      4'b0000: result_reg = a + b;
      4'b0001: result_reg = a - b;
      4'b0010: result_reg = a & b;
      4'b0011: result_reg = a | b;
      4'b0100: result_reg = a ^ b;
      4'b0101: result_reg = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      4'b0110: result_reg = a << b[4:0];
      4'b0111: result_reg = a >> b[4:0];
      4'b1000: result_reg = $signed(a) >>> b[4:0];
      4'b1001: result_reg = b;
      default: result_reg = 32'b0;
    endcase
  assign zero = (result_reg == 32'b0);
endmodule