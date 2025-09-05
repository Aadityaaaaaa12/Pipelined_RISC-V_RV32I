module HAZARD_UNIT(
    input wire [4:0] RS1D, RS2D,   
    input wire [4:0] RS1E, RS2E,   
    input wire [4:0] RdD, RdE, RdMW, RdWB, 
    input wire RegWriteMW, RegWriteWB,
    input wire ResultSrcE, PCSrcE,          

    output reg [1:0] ForwardAE, ForwardBE,
    output reg StallPC, StallF, FlushF, FlushD  
);

   
    always @(*) begin
        if ((RS1E == RdMW) && RegWriteMW && (RS1E != 0))
            ForwardAE = 2'b10; 
        else if ((RS1E == RdWB) && RegWriteWB && (RS1E != 0))
            ForwardAE = 2'b01;
        else 
            ForwardAE = 2'b00; 
    end
    
    always @(*) begin
        if ((RS2E == RdMW) && RegWriteMW && (RS2E != 0))
            ForwardBE = 2'b10; 
        else if ((RS2E == RdWB) && RegWriteWB && (RS2E != 0))
            ForwardBE = 2'b01;
        else 
            ForwardBE = 2'b00; 
    end

   
    wire LWstall;
    assign LWstall = ResultSrcE && ((RS1D == RdE) || (RS2D == RdE)) && (RdE != 0);

  
always @(*) begin
  // defaults
  StallPC = 1'b0;
  StallF = 1'b0;
  FlushD  = 1'b0;
  FlushF  = 1'b0;

  
  if (PCSrcE) begin
    FlushF  = 1'b1;   
    FlushD  = 1'b1;   
  end
  else if (LWstall) begin
    StallPC = 1'b1;  
    StallF = 1'b1;  
    FlushD  = 1'b1;   
  end
end


endmodule
