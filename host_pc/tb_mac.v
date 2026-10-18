`timescale 1ns / 1ps
module tb_mac;

reg         clk;
reg         rst_n;
reg         acc_clr;
reg signed [7:0] din_a;
reg signed [7:0] din_b;
reg         valid_in;
wire signed [15:0] acc_out;
wire        valid_out;

mac_unit u_mac_unit(
    .clk(clk),
    .rst_n(rst_n),
    .clr_acc(acc_clr), // ?修正端口名 clr_acc
    .din_a(din_a),
    .din_b(din_b),
    .valid_in(valid_in),
    .acc_out(acc_out),
    .valid_out(valid_out)
);

// 100MHz时钟，周期10ns
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    acc_clr = 1'b0;
    din_a = 8'd0;
    din_b = 8'd0;
    valid_in = 1'b0;
    #20;
    rst_n = 1'b1;
    #10;

    // ========== 测试1：先清零，计算 1*2 + (-3)*4 ==========
    acc_clr = 1'b1; #10; acc_clr = 1'b0; // 清零，acc_out=0
    din_a = 8'sd1;  din_b = 8'sd2; valid_in = 1'b1; #10; valid_in = 1'b0; // +2
    din_a = -8'sd3; din_b = 8'sd4; valid_in = 1'b1; #10; valid_in = 1'b0; // +(-12) → 总和 -10
    #20;

    // ========== 测试2：再次清零，计算 (-5)*(-5) ==========
    acc_clr = 1'b1; #10; acc_clr = 1'b0;
    din_a = -8'sd5; din_b = -8'sd5; valid_in = 1'b1; #10; valid_in = 1'b0; // +25
    #20;

    $display("========仿真完成========");
    $finish;
end

endmodule