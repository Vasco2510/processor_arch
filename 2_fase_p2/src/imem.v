module imem #(
    parameter MEM_FILE = "mem/programa1_no_dependencias.mem"
) (
    input  wire [31:0] a,
    output wire [31:0] rd
);
    reg [15:0] RAM [0:127];
    initial begin
        $readmemh(MEM_FILE, RAM);
        $display("imem: Loaded instructions from %s", MEM_FILE);
    end
    wire [6:0] idx = a[7:1];
    assign rd = {RAM[idx + 7'd1], RAM[idx]};
endmodule