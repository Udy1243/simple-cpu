module register_file(
input logic clk,
input logic rst_n,
input logic [2:0] read_addr1,
input logic [2:0] read_addr2,
input logic [2:0] write_addr,
input logic write_en,
input logic [7:0] write_data,
output logic [7:0] read_data1,
output logic [7:0] read_data2
);

logic [7:0] reg_arr [7:0];


always_comb begin
        read_data1 = reg_arr[read_addr1];
        read_data2 = reg_arr[read_addr2];
end 

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < 8; i++) begin
            reg_arr[i] <= 8'b0;
        end
    end else if (write_en) begin
        reg_arr[write_addr] <= write_data;
    end
end

endmodule