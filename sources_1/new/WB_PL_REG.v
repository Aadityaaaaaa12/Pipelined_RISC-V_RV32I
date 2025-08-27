
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2025
// Design Name: 
// Module Name: WB_PL_REG
// Description: Memory to Writeback Pipeline Register
//////////////////////////////////////////////////////////////////////////////////

module WB_PL_REG(
    input         clk, reset,
    input         RegWriteMW,
    input [1:0]   ResultSrcMW,
    input [31:0]  ALUResultMW,
    input [31:0] LauiPCMW,
    input [31:0]  ReadData,
    input [4:0]   RdMW,
    input [31:0]  PC4MW,

    output reg         RegWriteWB,
    output reg [1:0]   ResultSrcWB,
    output reg [31:0]  ALUResultWB,
    output reg [31:0]  LauiPCWB,
    output reg [31:0]  ReadDataWB,
    output reg [4:0]   RdWB,
    output reg [31:0]  PC4WB
);


always @(posedge clk or posedge reset) begin
    if (reset) begin
        RegWriteWB   <= 0;
        ResultSrcWB  <= 0;
        ALUResultWB  <= 0;
        LauiPCWB     <= 0;
        ReadDataWB   <= 0;
        RdWB         <= 0;
        PC4WB        <= 0;
    end else begin
        RegWriteWB   <= RegWriteMW;
        ResultSrcWB  <= ResultSrcMW;
        ALUResultWB  <= ALUResultMW;
        LauiPCWB     <= LauiPCMW;
        ReadDataWB   <= ReadData;
        RdWB         <= RdMW;
        PC4WB        <= PC4MW;
    end
end

endmodule
