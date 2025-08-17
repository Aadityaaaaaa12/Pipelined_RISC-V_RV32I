module DE_PL_REG(
    input         clk, reset,
    input [1:0]   ResultSrcD,
    input         ALUSrcD,
    input         RegWriteD,
     input [3:0]   ALUControlD,
    input         MemWriteD,
    input [31:0]  RD1D, RD2D,
    input [31:0]  PCD,
    input [4:0]   RdD,
    input [31:0]  ImmExtD,InstrD,
    input [31:0]  PC4D,
    input         Jump,Branch, 

    output reg         RegWriteE,
    output reg [1:0]   ResultSrcE,
    output reg         MemWriteE,
    output reg [3:0]   ALUControlE,
    output reg         ALUSrcE,
    output reg [31:0]  RD1E, RD2E,
    output reg [31:0]  PCE,
    output reg [4:0]   RdE,
    output reg [31:0]  ImmExtE,InstrE,
    output reg [31:0]  PC4E,
    output reg         JumpE,BranchE
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        RegWriteE    <= 0;
        ResultSrcE   <= 0;
        MemWriteE    <= 0;
        ALUControlE  <= 0;
        ALUSrcE      <= 0;
        RD1E         <= 0;
        RD2E         <= 0;
        PCE          <= 0;
        RdE          <= 0;
        ImmExtE      <= 0;
        InstrE       <= 0;   
        PC4E         <= 0;
        JumpE        <= 0;
        BranchE      <= 0;
    end else begin
        RegWriteE    <= RegWriteD;
        ResultSrcE   <= ResultSrcD;
        MemWriteE    <= MemWriteD;
        ALUControlE  <= ALUControlD;
        ALUSrcE      <= ALUSrcD;
        RD1E         <= RD1D;
        RD2E         <= RD2D;
        PCE          <= PCD;
        RdE          <= RdD;
        ImmExtE      <= ImmExtD;
        InstrE       <= InstrD;
        PC4E         <= PC4D;
        JumpE        <= Jump;
        BranchE      <= Branch;
    end
end

endmodule