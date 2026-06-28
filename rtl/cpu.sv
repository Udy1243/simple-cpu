module cpu (
    input logic clk, 
    input logic rst_n,
    output logic [5:0] pc_out,
    output logic [7:0] alu_out
);

logic [5:0] pc; 
logic [15:0] instruction;
logic [2:0] op;
logic [2:0] rd;
logic [2:0] rs1;
logic [2:0] rs2;
logic [5:0] imm;
logic [7:0] operand_a;
logic [7:0] operand_b;
logic [7:0] alu_result;
logic zero_flag;
logic [7:0] data_read;
logic reg_write_en;
logic mem_write_en;
logic [7:0] reg_write_data;
logic beq_taken;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc <= 6'b0;
    end else begin
        pc <= beq_taken ? pc + imm : pc + 1;
    end
end

register_file inst1 ( 
.read_addr1(rs1), 
.read_addr2(rs2),
.read_data1(operand_a),
.read_data2(operand_b),
.write_addr(rd), 
.write_data (reg_write_data), 
.write_en(reg_write_en), 
.clk(clk),
.rst_n(rst_n)
);
 
alu inst2 (
.operand_a(operand_a),
.operand_b(operand_b),
.op(op),
.result(alu_result),
.zero_flag(zero_flag)
);

memory inst3 (
.instr_addr(pc),
.instr_data(instruction),
.clk(clk),
.data_addr(imm),
.write_en(mem_write_en),
.write_data(operand_a),
.read_data(data_read)
);


assign op = instruction[15:13];
assign rd = instruction[12:10];
assign imm = instruction[9:4];
assign rs1 = (op == 3'b101 || op == 3'b110) ? instruction[12:10] : instruction[9:7];
assign rs2 = (op == 3'b110) ? instruction[3:1] : instruction[6:4];
assign reg_write_en = (op == 3'b000 || op == 3'b001 || op == 3'b010 || op == 3'b011|| op == 3'b100);
assign mem_write_en = (op == 3'b101);
assign reg_write_data = (op == 3'b100) ? data_read : alu_result;
assign beq_taken = (op == 3'b110) && operand_a == operand_b;
assign pc_out = pc;
assign alu_out = alu_result;

endmodule