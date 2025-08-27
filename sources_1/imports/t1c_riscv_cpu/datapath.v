
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input [1:0]   ImmSrc,
    input [3:0]   ALUControl,
	 input 			Jalr,Jump,Branch,
	 input        MemWrite,
    output        Zero, ALUR31,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] InstrD,
    output [31:0] InstrMW,
    output        MemWriteMW,
    output [31:0] Result
);

wire [31:0] PCNext, PCJalr, PCPlus4, PCTarget, AuiPC, LauiPC;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;


always @(posedge clk) begin
    $display("IF Stage: PC = %h, Instr = %h, Stall = %b", PC, Instr, Stall);
    $display("DE Stage: PCD = %h, InstrD = %h, flush = %b,RegWrite = %b, ALUSrc = %b, ResultSrc = %b, ALUControl = %b, ImmSrc = %b, Jalr = %b, PCSrcE = %b",
             PCD,InstrD,Flush, RegWrite, ALUSrc, ResultSrc, ALUControl, ImmSrc, Jalr, PCSrcE);
    $display("E Stage: PCE = %h,SrcA = %h,RD2E = %h,ImmExtE = %b, SrcB = %h, ALUResult = %h, Zero = %b, ALUR31 = %b",
             PCE,RD1E,RD2E,ImmExtE, SrcB, ALUResult, Zero, ALUR31);
   
    $display("PCMW = %h,Mem_WrData = %h, Mem_WrAddr = %h, MemWriteMW = %b ,RegWriteMW = %b,Reg_Addr: = %h" ,PCMW,RD2MW,ALUResultMW,MemWriteMW,RegWriteMW,RdMW);
     $display("Writeback: Result = %h",Result);
      $display("MemWrites: MemWrite = %h, MemWriteE = %h",MemWrite,MemWriteE);
    
end



//DECODE STAGE WIRES
wire [31:0] PCD,PC4D,ImmExtD,RD1D,RD2D;
wire [4:0] RdD;

//EXECUTE STAGE WIRES 
wire [31:0] PCE,PC4E,ImmExtE,RD1E,RD2E,SrcBE,PCTargetE,InstrE;
wire [4:0] RdE;
wire RegWriteE;
wire [1:0]   ResultSrcE;
wire [3:0]   ALUControlE;
wire BranchTest;
reg BranchTestT;
wire ALUSrcE;
wire [2:0] funct3;
wire [6:0] op;
wire PCSrcE;
wire JumpE;

//memory write stage wires
wire         RegWriteMW;
wire [1:0]   ResultSrcMW;
wire [31:0]  ALUResultMW,PCMW;
wire [31:0]  LauiPCMW;
wire [31:0]  RD2MW;
wire [4:0]   RdMW;
wire [31:0]  PC4MW;

// next PC logic
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrcE, PCNext);
mux2 #(32)		jalrmux(PCNext, ALUResult, Jalr, PCJalr);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PCE, ImmExtE, PCTarget);

reset_ff #(32) pcreg(clk, reset, PCJalr, PC);

wire Stall = Branch; // Stall when a branch instruction is in decode

IF_PL_REG IF_reg (
    .clk(clk),
    .reset(reset),
    .Instr(Instr),
    .PC_in(PC),
    .PC4_in(PCPlus4),
    .Stall(Stall), // Connect Stall signal
    .InstrF(InstrD),
    .PCF(PCD),
    .PC4_out(PC4D)
);

wire Flush = PCSrcE | JumpE | Jalr;
// register file logic
reg_file       rf (clk, RegWriteMW, InstrD[19:15], InstrD[24:20], RdMW, Result, SrcA, WriteData);
imm_extend     ext (InstrD[31:7], ImmSrc, ImmExt);

DE_PL_REG DE_reg(
    .clk(clk),
    .reset(reset),
    .Flush(Flush), // Connect PCSrcE to Flush
    .ResultSrcD(ResultSrc),
    .ALUSrcD(ALUSrc),
    .RegWriteD(RegWrite),
    .ALUControlD(ALUControl),
    .MemWriteD(MemWrite),
    .RD1D(SrcA),
    .RD2D(WriteData),
    .PCD(PCD),
    .RdD(InstrD[11:7]),
    .ImmExtD(ImmExt),
    .InstrD(InstrD),
    .PC4D(PC4D),
    .Jump(Jump),
    .Branch(Branch),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .ALUControlE(ALUControlE),
    .ALUSrcE(ALUSrcE),
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .RdE(RdE),
    .ImmExtE(ImmExtE),
    .InstrE(InstrE),
    .PC4E(PC4E),
    .JumpE(JumpE),
    .BranchE(BranchE)
);

// ALU logic
mux2 #(32)     srcbmux(RD2E, ImmExtE, ALUSrcE, SrcB);
alu            alu (RD1E, SrcB, ALUControlE, ALUResult, Zero);
adder #(32)		auipcadder({InstrE[31:12],12'b0}, PCE, AuiPC);
mux2 #(32)		LauiPCmux(AuiPC, {InstrE[31:12], 12'b0}, InstrE[5], LauiPC);

assign ALUR31 = ALUResult[31];

reg TakeBranchE;

always @(*) begin
    case (InstrE[14:12]) // funct3 in execute stage
        3'b000: TakeBranchE = Zero;       // beq
        3'b001: TakeBranchE = !Zero;      // bne
        3'b100: TakeBranchE = ALUR31;     // blt
        3'b101: TakeBranchE = !ALUR31;    // bge
        3'b110: TakeBranchE = ALUR31;     // bltu
        3'b111: TakeBranchE = !ALUR31;    // bgeu
        default: TakeBranchE = 0;
    endcase
end
assign PCSrcE = (TakeBranchE & BranchE) | JumpE;



MW_PL_REG MW(clk,reset,PCE,RegWriteE,ResultSrcE,MemWriteE,ALUResult,LauiPC,RD2E,InstrE,RdE,PC4E,PCMW,RegWriteMW,ResultSrcMW,MemWriteMW,ALUResultMW,LauiPCMW,RD2MW,InstrMW,RdMW,PC4MW);



assign Mem_WrData = RD2MW;
assign Mem_WrAddr = ALUResultMW;




//result mux
mux4 #(32)     resultmux(ALUResultMW, ReadData, PC4MW, LauiPCMW, ResultSrcMW, Result);



endmodule

