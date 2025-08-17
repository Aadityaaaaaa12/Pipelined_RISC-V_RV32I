
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
    output [31:0] InstrE,
    output        MemWriteE,
    output [31:0] Result
);

wire [31:0] PCNext, PCJalr, PCPlus4, PCTarget, AuiPC, LauiPC;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;


always @(posedge clk) begin
    $display("IF Stage: PC = %h, Instr = %h", PC, Instr);
    $display("DE Stage: InstrD = %h, RegWrite = %b, ALUSrc = %b, ResultSrc = %b, ALUControl = %h, ImmSrc = %b, Jalr = %b, PCSrcE = %b",
             InstrD, RegWrite, ALUSrc, ResultSrc, ALUControl, ImmSrc, Jalr, PCSrcE);
    $display("DE Stage: SrcA = %h, SrcB = %h, ALUResult = %h, Zero = %b, ALUR31 = %b",
             SrcA, SrcB, ALUResult, Zero, ALUR31);
    $display("DE Stage Writeback: Result = %h, Mem_WrAddr = %h, Mem_WrData = %h, ReadData = %h",
             Result, Mem_WrAddr, Mem_WrData, ReadData);
    $display("DE Stage RegFile Write: wr_addr = %h, wr_data = %h, wr_en = %b",
             InstrE[11:7], Result, RegWriteE);
    $display("Execute: BranchE = %b, Zero = %b, ALUR31 = %b, funct3E = %b, JumpE = %b, PCSrcE = %b, PCTarget = %h",
             BranchE, Zero, ALUR31, funct3E, JumpE, PCSrcE, PCTarget);
end

//DECODE STAGE WIRES
wire [31:0] PCD,PC4D,ImmExtD,RD1D,RD2D;
wire [4:0] RdD;

//EXECUTE STAGE WIRES 
wire [31:0] PCE,PC4E,ImmExtE,RD1E,RD2E,SrcBE,PCTargetE;
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




// next PC logic
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrcE, PCNext);
mux2 #(32)		jalrmux(PCNext, ALUResult, Jalr, PCJalr);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PCE, ImmExtE, PCTarget);

reset_ff #(32) pcreg(clk, reset, PCJalr, PC);

IF_PL_REG IF_reg (
    .clk(clk),
    .reset(reset),
    .Instr(Instr),
    .PC_in(PC),
    .PC4_in(PCPlus4),
    .InstrF(InstrD),
    .PCF(PCD),
    .PC4_out(PC4D)
);


// register file logic
reg_file       rf (clk, RegWrite, InstrD[19:15], InstrD[24:20], RdE, Result, SrcA, WriteData);
imm_extend     ext (InstrD[31:7], ImmSrc, ImmExt);

DE_PL_REG DE_reg(clk,reset,ResultSrc,ALUSrc,RegWrite,ALUControl,MemWrite,SrcA,WriteData,PCD,InstrD[11:7],ImmExt,InstrD,PC4D,Jump,Branch,RegWriteE,ResultSrcE,MemWriteE,ALUControlE,ALUSrcE,RD1E,RD2E,PCE,RdE,ImmExtE,InstrE,PC4E,JumpE,BranchE);


// ALU logic
mux2 #(32)     srcbmux(RD2E, ImmExtE, ALUSrcE, SrcB);
alu            alu (RD1E, SrcB, ALUControlE, ALUResult, Zero);
adder #(32)		auipcadder({InstrE[31:12],12'b0}, PCE, AuiPC);
mux2 #(32)		LauiPCmux(AuiPC, {InstrE[31:12], 12'b0}, InstrE[5], LauiPC);

wire funct3E = InstrE[14:12];

assign PCSrcE = ((Zero&BranchE)|JumpE);

//assign PCSrcE = ((Zero & BranchE & (funct3E == 3'b000)) | // BEQ
//                 (~Zero & BranchE & (funct3E == 3'b001)) | // BNE
//                 (ALUR31 & BranchE & (funct3E == 3'b100)) | // BLT
//                 (~ALUR31 & BranchE & (funct3E == 3'b101)) | // BGE
//                 (ALUR31 & BranchE & (funct3E == 3'b110)) | // BLTU
//                 (~ALUR31 & BranchE & (funct3E == 3'b111)) | // BGEU
//                 JumpE);

//wire Stall = (InstrD[6:0] == 7'b1100011); // Stall for branch instructions

always @(posedge clk) begin
    $display("Execute: BranchE = %b, Zero = %b, JumpE = %b, PCSrcE = %b", BranchE, Zero, JumpE, PCSrcE);
end


//result mux
mux4 #(32)     resultmux(ALUResult, ReadData, PC4E, LauiPC, ResultSrcE, Result);

assign ALUR31 = ALUResult[31];
assign Mem_WrData = RD2E;
assign Mem_WrAddr = ALUResult;

endmodule

