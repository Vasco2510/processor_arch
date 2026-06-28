module top_pipe #(
    parameter INSTR_MEM_FILE = "mem/programa1_no_dependencias.mem"
) (
    input wire clk,
    input wire reset
);
    pipeline #(
        .INSTR_MEM_FILE(INSTR_MEM_FILE)
    ) pipe (
        .clk(clk),
        .reset(reset)
    );
endmodule