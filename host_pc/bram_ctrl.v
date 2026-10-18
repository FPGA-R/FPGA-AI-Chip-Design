module bram_ctrl(
input               clk,
input               rst_n,
input               wr_en,
input      [8:0]    wr_addr,
input signed [7:0]  wr_data,
input               rd_en,
input      [8:0]    rd_addr,
output reg signed [7:0] rd_data
);

reg signed [7:0] mem [0:511];

always @(posedge clk) begin
    if(wr_en) mem[wr_addr] <= wr_data;
    if(rd_en) rd_data <= mem[rd_addr];
end

endmodule