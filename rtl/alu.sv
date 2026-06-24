module alu (
    input logic [7:0] operand_a,
    input logic [7:0] operand_b,
    input logic [2:0] op,
    output logic [7:0] result,
    output logic zero_flag
);

always_comb begin
    case(op)
        3'b000: result = operand_a + operand_b; // Addition
        3'b001: result = operand_a - operand_b; // Subtraction
        3'b010: result = operand_a & operand_b; // AND
        3'b011: result = operand_a | operand_b; // OR
        default: result = 8'b0;                  // Default case
    endcase
    zero_flag = (result == 8'b0);
end
endmodule
