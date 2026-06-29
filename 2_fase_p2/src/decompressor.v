module decompressor (
    input  wire [15:0] instr16,
    output reg  [31:0] instr32,
    output wire        is_compressed
);
    assign is_compressed = (instr16[1:0] != 2'b11);
    wire [4:0] rd_p  = {2'b01, instr16[4:2]};
    wire [4:0] rs1_p = {2'b01, instr16[9:7]};
    wire [4:0] rs2_p = {2'b01, instr16[4:2]};
    wire [4:0] rd_f  = instr16[11:7];
    wire [4:0] rs2_f = instr16[6:2];
    always @(*) begin
        case (instr16[1:0])
            2'b00: begin
                case (instr16[15:13])
                    3'b010: begin
                        instr32 = {5'b00000, instr16[5], instr16[12:10], instr16[6], 2'b00,
                                   rs1_p, 3'b010, rd_p, 7'b0000011};
                    end
                    3'b110: begin
                        instr32 = {5'b00000, instr16[5], instr16[12],
                                   rs2_p, rs1_p, 3'b010,
                                   instr16[11:10], instr16[6], 2'b00,
                                   7'b0100011};
                    end
                    default: instr32 = 32'h00000013;
                endcase
            end
            2'b01: begin
                case (instr16[15:13])
                    3'b000: begin
                        instr32 = {{6{instr16[12]}}, instr16[12], instr16[6:2],
                                   rd_f, 3'b000, rd_f, 7'b0010011};
                    end
                    3'b001: begin
                        instr32 = {instr16[12],
                                   instr16[8], instr16[10:9], instr16[6],
                                   instr16[7], instr16[2], instr16[11], instr16[5:3],
                                   instr16[12],
                                   {8{instr16[12]}},
                                   5'b00001, 7'b1101111};
                    end
                    3'b011: begin
                        instr32 = {{14{instr16[12]}}, instr16[12], instr16[6:2],
                                   rd_f, 7'b0110111};
                    end
                    3'b100: begin
                        case (instr16[11:10])
                            2'b00: begin
                                instr32 = {7'b0000000, instr16[6:2],
                                           rs1_p, 3'b101, rs1_p, 7'b0010011};
                            end
                            2'b01: begin
                                instr32 = {7'b0100000, instr16[6:2],
                                           rs1_p, 3'b101, rs1_p, 7'b0010011};
                            end
                            2'b10: begin
                                instr32 = {{6{instr16[12]}}, instr16[12], instr16[6:2],
                                           rs1_p, 3'b111, rs1_p, 7'b0010011};
                            end
                            2'b11: begin
                                case ({instr16[12], instr16[6:5]})
                                    3'b000: instr32 = {7'b0100000, rs2_p,
                                                       rs1_p, 3'b000, rs1_p, 7'b0110011};
                                    3'b001: instr32 = {7'b0000000, rs2_p,
                                                       rs1_p, 3'b100, rs1_p, 7'b0110011};
                                    3'b010: instr32 = {7'b0000000, rs2_p,
                                                       rs1_p, 3'b110, rs1_p, 7'b0110011};
                                    3'b011: instr32 = {7'b0000000, rs2_p,
                                                       rs1_p, 3'b111, rs1_p, 7'b0110011};
                                    default: instr32 = 32'h00000013;
                                endcase
                            end
                        endcase
                    end
                    3'b101: begin
                        instr32 = {instr16[12],
                                   instr16[8], instr16[10:9], instr16[6],
                                   instr16[7], instr16[2], instr16[11], instr16[5:3],
                                   instr16[12],
                                   {8{instr16[12]}},
                                   5'b00000, 7'b1101111};
                    end
                    3'b110: begin
                        instr32 = {instr16[12],
                                   instr16[12], instr16[12], instr16[12],
                                   instr16[6], instr16[5], instr16[2],
                                   5'b00000, rs1_p, 3'b000,
                                   instr16[11:10], instr16[4:3], instr16[12],
                                   7'b1100011};
                    end
                    3'b111: begin
                        instr32 = {instr16[12],
                                   instr16[12], instr16[12], instr16[12],
                                   instr16[6], instr16[5], instr16[2],
                                   5'b00000, rs1_p, 3'b001,
                                   instr16[11:10], instr16[4:3], instr16[12],
                                   7'b1100011};
                    end
                    default: instr32 = 32'h00000013;
                endcase
            end
            2'b10: begin
                case (instr16[15:13])
                    3'b000: begin
                        instr32 = {7'b0000000, instr16[6:2],
                                   rd_f, 3'b001, rd_f, 7'b0010011};
                    end
                    3'b010: begin
                         instr32 = {5'b00000, instr16[5], instr16[12], instr16[4], instr16[3], instr16[6], 2'b00,
                                    5'b00010, 3'b010, rd_f, 7'b0000011};
                     end
                    3'b100: begin
                        if (!instr16[12]) begin
                            if (instr16[6:2] == 5'b00000) begin
                                instr32 = {12'b0, rd_f, 3'b000, 5'b00000, 7'b1100111};
                            end else begin
                                instr32 = {7'b0000000, rs2_f, 5'b00000,
                                           3'b000, rd_f, 7'b0110011};
                            end
                        end else begin
                            if (instr16[6:2] == 5'b00000) begin
                                instr32 = {12'b0, rd_f, 3'b000, 5'b00001, 7'b1100111};
                            end else begin
                                instr32 = {7'b0000000, rs2_f, rd_f,
                                           3'b000, rd_f, 7'b0110011};
                            end
                        end
                    end
                    3'b110: begin
                         instr32 = {4'b0000, instr16[12:10],
                                    rs2_f, 5'b00010, 3'b010,
                                    instr16[9:7], 2'b00,
                                    7'b0100011};
                     end
                    default: instr32 = 32'h00000013;
                endcase
            end
            default: instr32 = 32'h00000013;
        endcase
    end
endmodule