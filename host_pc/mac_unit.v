module mac_unit(
input clk,
input rst_n,
input signed [7:0] din_a,
input signed [7:0] din_b,
input valid_in,
input acc_clr,     // 新增：累加清零端口
output reg signed [15:0] acc_out,
output reg valid_out
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        acc_out <= 16'd0;
        valid_out <= 1'b0;
    end else begin
        valid_out <= 1'b0;
        if(acc_clr) begin
            acc_out <= 16'd0; // 清零累加寄存器
        end
        else if(valid_in) begin
            acc_out <= acc_out + din_a * din_b;
            valid_out <= 1'b1;
        end
    end
end

endmodule