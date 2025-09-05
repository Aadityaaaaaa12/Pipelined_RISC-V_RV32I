module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,       // operands
    input       [3:0] alu_ctrl,         // ALU control
    output reg  [WIDTH-1:0] alu_out,    // ALU output
    output      zero                    // zero flag
);

reg signed [WIDTH-1:0] a_signed, b_signed;

always @(a, b, alu_ctrl) begin
    // Assign signed versions of inputs
    a_signed = a; 
    b_signed = b; 

    case (alu_ctrl)
        4'b0000:  alu_out <= a + b;       // ADD
        4'b0001:  alu_out <= a + ~b + 1;  // SUB
        4'b0010:  alu_out <= a & b;       // AND
        4'b0011:  alu_out <= a | b;       // OR
        4'b0100:  alu_out <= a ^ b;       // XOR
        4'b0101:  alu_out <= (a_signed < b_signed) ? 1 : 0;  // SLT (signed comparison)
        4'b0110:  alu_out <= a >> b[4:0]; // SRL, SRLI (logical shift right)
        4'b0111:  alu_out <= a << b[4:0]; // SLL (shift left)
        4'b1000:  alu_out <= a_signed >>> b[4:0]; // SRA, SRAI (arithmetic right shift)
        4'b1001:  alu_out <= (a < b) ? 1 : 0;     // SLTU (unsigned less than)
        default:  alu_out <= 0;
    endcase
end

assign zero = (alu_out == 0) ? 1'b1 : 1'b0;

endmodule
