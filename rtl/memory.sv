module memory(
    input logic [5:0] instr_addr,
    output logic [15:0] instr_data,
    input  logic        clk,
    input  logic [5:0]  data_addr,
    input  logic        write_en,
    input  logic [7:0]  write_data,
    output logic [7:0]  read_data
);

logic [15:0] instr_mem [63:0]; // 64 instructions of 16 bits each
logic [7:0] data_mem [63:0];    // 64 data locations

always_comb begin
    instr_data = instr_mem[instr_addr];
end

always_comb begin
    read_data = data_mem[data_addr];
end

always_ff @(posedge clk) begin
    if (write_en) begin
        data_mem[data_addr] <= write_data;
    end
end

endmodule