
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
    
    $display("IF Stage: PC = %h, Instr = %h, Stall = %b", PC, Instr, StallF);
    $display("   PCMux inputs: PCPlus4 = %h, PCTarget = %h, PCSrcE = %b | PCNext = %h",
             PCPlus4, PCTarget, PCSrcE, PCNext);

   
    $display("DE Stage: PCD = %h, InstrD = %h, flush = %b, RegWrite = %b, ALUSrc = %b, ResultSrc = %b, ALUControl = %b, ImmSrc = %b, Jalr = %b, Jump = %b, Branch = %b",
             PCD, InstrD, FlushD, RegWrite, ALUSrc, ResultSrc, ALUControl, ImmSrc, Jalr, Jump, Branch);

    
    $display("E Stage: PCE = %h", PCE);
    $display("   SrcAForward MUX inputs: RD1E = %h, Result = %h, ALUResultMW = %h | ForwardAE = %b -> SrcA = %h",
             RD1E, Result, ALUResultMW, ForwardAE, SrcA);
    $display("   SrcBForward MUX inputs: RD2E = %h, Result = %h, ALUResultMW = %h | ForwardBE = %b -> RD2EF = %h",
             RD2E, Result, ALUResultMW, ForwardBE, RD2EF);
             
    $display("   ImmExtE = %h, SrcB(after ALUSrc mux) = %h, ALUResult = %h, Zero = %b, ALUR31 = %b",
             ImmExtE, SrcB, ALUResult, Zero, ALUR31);
             
    $display("   BranchE = %b, TakeBranchE = %b, JumpE = %b, PCSrcE = %b",
             BranchE, TakeBranchE, JumpE, PCSrcE);

   
    $display("MEM Stage: PCMW = %h, Mem_WrData = %h, Mem_WrAddr = %h, MemWriteMW = %b", 
             PCMW, RD2MW, ALUResultMW, MemWriteMW);

  
    $display("WB Stage: PCWB = %h, Result = %h, WB_address = %h, RegWriteWB = %b", 
             PCWB, Result, RdWB, RegWriteWB);

    $display("");
end







//DECODE STAGE WIRES
wire [31:0] PCD,PC4D,ImmExtD,RD1D,RD2D;
wire [4:0] RdD;

//EXECUTE STAGE WIRES 
wire [31:0] PCE,PC4E,ImmExtE,RD1E,RD2E,RD2EF,SrcBE,PCTargetE,InstrE;
wire [4:0] RdE,RS1E,RS2E;
wire RegWriteE;
wire [1:0]   ResultSrcE;
wire [3:0]   ALUControlE;
wire BranchTest;
reg BranchTestT;
wire ALUSrcE;
wire [2:0] funct3;
wire [6:0] op;
wire PCSrcE;
wire JumpE,jalrE;

//memory write stage wires
wire         RegWriteMW;
wire [1:0]   ResultSrcMW;
wire [31:0]  ALUResultMW,PCMW;
wire [31:0]  LauiPCMW;
wire [31:0]  RD2MW;
wire [4:0]   RdMW;
wire [31:0]  PC4MW;


//WRITE BACK STAGE WIRES
wire [1:0]   ResultSrcWB;
wire [31:0]  ALUResultWB;
wire [31:0]  ReadDataWB;
wire [4:0]   RdWB;
wire [31:0]  PC4WB,LauiPCWB,PCWB;

// next PC logic
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrcE, PCNext);
mux2 #(32)		jalrmux(PCNext, ALUResult, jalrE, PCJalr);
adder          pcadd4(PC, 32'd4, PCPlus4);


reset_ff #(32) pcreg(clk, reset,StallPC, PCJalr, PC);



IF_PL_REG IF_reg (
    .clk(clk),
    .reset(reset),
    .Instr(Instr),
    .PC_in(PC),
    .PC4_in(PCPlus4),
    .Stall(StallF), 
    .Flush(FlushF),
    .InstrF(InstrD),
    .PCF(PCD),
    .PC4_out(PC4D)
);



reg_file       rf (clk, RegWriteWB, InstrD[19:15], InstrD[24:20], RdWB, Result, RD1D, RD2D);
imm_extend     ext (InstrD[31:7], ImmSrc, ImmExt);

DE_PL_REG DE_reg(
    .clk(clk),
    .reset(reset),
    .Flush(FlushD), 
    .ResultSrcD(ResultSrc),
    .ALUSrcD(ALUSrc),
    .RegWriteD(RegWrite),
    .ALUControlD(ALUControl),
    .MemWriteD(MemWrite),
    .RD1D(RD1D),
    .RD2D(RD2D),
    .PCD(PCD),
    .RdD(InstrD[11:7]),
    .RS1D(InstrD[19:15]),
    .RS2D(InstrD[24:20]),
    .ImmExtD(ImmExt),
    .InstrD(InstrD),
    .PC4D(PC4D),
    .Jump(Jump),
    .Branch(Branch),
    .jalr(Jalr),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .ALUControlE(ALUControlE),
    .ALUSrcE(ALUSrcE),
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .RdE(RdE),
    .RS1E(RS1E),
    .RS2E(RS2E),
    .ImmExtE(ImmExtE),
    .InstrE(InstrE),
    .PC4E(PC4E),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .jalrE(jalrE)
);






//FORWARDING ALU LOGIC
mux3 #(32) SrcAForward(RD1E,Result,ALUResultMW,ForwardAE,SrcA);
mux3 #(32) SrcBForward(RD2E,Result,ALUResultMW,ForwardBE,RD2EF);

// ALU logic
mux2 #(32)     srcbmux(RD2EF, ImmExtE, ALUSrcE, SrcB);
alu            alu (SrcA, SrcB, ALUControlE, ALUResult, Zero);
adder #(32)		auipcadder({InstrE[31:12],12'b0}, PCE, AuiPC);
mux2 #(32)		LauiPCmux(AuiPC, {InstrE[31:12], 12'b0}, InstrE[5], LauiPC);

adder          pcaddbranch(PCE, ImmExtE, PCTarget);

assign ALUR31 = ALUResult[31];

reg TakeBranchE;

always @(*) begin
    case (InstrE[14:12]) 
        3'b000: TakeBranchE = Zero;       // beq
        3'b001: TakeBranchE = !Zero;      // bne
        3'b100: TakeBranchE = ALUR31;     // blt
        3'b101: TakeBranchE = !ALUR31;    // bge
        3'b110: TakeBranchE = ALUR31;     // bltu
        3'b111: TakeBranchE = !ALUR31;    // bgeu
        default: TakeBranchE = 0;
    endcase
end
assign PCSrcE = (TakeBranchE & BranchE) | JumpE | jalrE;



MW_PL_REG MW(clk,reset,PCE,RegWriteE,ResultSrcE,MemWriteE,ALUResult,LauiPC,RD2E,InstrE,RdE,PC4E,PCMW,RegWriteMW,ResultSrcMW,MemWriteMW,ALUResultMW,LauiPCMW,RD2MW,InstrMW,RdMW,PC4MW);



assign Mem_WrData = RD2MW;
assign Mem_WrAddr = ALUResultMW;


WB_PL_REG WB(clk,rst,PCMW,RegWriteMW,ResultSrcMW,ALUResultMW,LauiPCMW,ReadData,RdMW,PC4MW,PCWB,RegWriteWB,ResultSrcWB,ALUResultWB,LauiPCWB,ReadDataWB,RdWB,PC4WB);

//result mux
mux4 #(32)     resultmux(ALUResultWB, ReadDataWB, PC4WB, LauiPCWB, ResultSrcWB, Result);




// HAZARD UNIT CALL AND DECLARATIONS
wire [1:0] ForwardAE,ForwardBE;
wire StallPC,StallF,FlushD,FlushF;
HAZARD_UNIT HU(RS1D,RS2D,RS1E,RS2E,RdD,RdE,RdMW,RdWB,RegWriteMW,RegWriteWB,ResultSrcE,PCSrcE,ForwardAE,ForwardBE,StallPC,StallF,FlushF,FlushD);
//HAZARD UNIT END


endmodule

