module cpu_tb;
    logic clk;
    logic rst_n;

initial clk = 0;
always #5 clk = ~clk;
initial begin 
    rst_n = 0;
    #30 rst_n = 1;
end

cpu dut (
    .clk(clk),
    .rst_n(rst_n)
);

initial begin
     $readmemh("program.hex", dut.inst3.instr_mem);
     $readmemh("data.hex", dut.inst3.data_mem);
end


always @(posedge clk) begin
    if (rst_n) begin
    $display("PC: %0d, Instruction: %h, alu Result: %0d, reg_write_en: %0d, rd: %0d, reg_write_data: %0d", 
        dut.pc, dut.instruction, dut.alu_result, dut.reg_write_en, dut.rd, dut.reg_write_data);
    end
end

initial begin
    #200 $finish;
end
endmodule