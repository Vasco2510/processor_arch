module wb_stage (
    input  wire [31:0] ALUResultW,
    input  wire [31:0] ReadDataW,
    input  wire [31:0] PCPlus4W,
    input  wire [1:0]  ResultSrcW,
    output wire [31:0] ResultW
);
    mux3 #(32) result_mux (
        .d0(ALUResultW),
        .d1(ReadDataW),
        .d2(PCPlus4W),
        .s(ResultSrcW),
        .y(ResultW)
    );
endmodule