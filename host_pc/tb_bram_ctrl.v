
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/15 19:48:58
// Design Name: 
// Module Name: tb_bram_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
module tb_bram_ctrl;

reg         clk;
reg         rst_n;
reg         wr_en;
reg [8:0]   wr_addr;
reg signed [7:0] wr_data;
reg         rd_en;
reg [8:0]   rd_addr;
wire signed [7:0] rd_data;

bram_ctrl u_bram_ctrl(
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .rd_en(rd_en),
    .rd_addr(rd_addr),
    .rd_data(rd_data)
);

// 100MHz时钟
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    wr_en = 1'b0;
    wr_addr = 9'd0;
    wr_data = 8'd0;
    rd_en = 1'b0;
    rd_addr = 9'd0;
    #20;
    rst_n = 1'b1;
    #10;

    // Case1：地址10写入 -3
    wr_en = 1'b1; wr_addr = 9'd10; wr_data = -8'd3; #10; wr_en = 1'b0;
    #10;
    rd_en = 1'b1; rd_addr = 9'd10; #10; rd_en = 1'b0;
    #20;

    // Case2：地址20写入 6
    wr_en = 1'b1; wr_addr = 9'd20; wr_data = 8'd6; #10; wr_en = 1'b0;
    #10;
    rd_en = 1'b1; rd_addr = 9'd20; #10; rd_en = 1'b0;

    // Case3：地址50写入 -128（INT8最小值）
    wr_en = 1'b1; wr_addr = 9'd50; wr_data = -8'd128; #10; wr_en = 1'b0;
    #10;
    rd_en = 1'b1; rd_addr = 9'd50; #10; rd_en = 1'b0;

    #30;
    $finish;
end

endmodule
