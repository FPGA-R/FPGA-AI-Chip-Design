`timescale 1ns / 1ps

module top_pl_uart_matmul_tb;

// 1. TB信号定义
reg clk;
reg rst_n;
reg rx_pin;
wire tx_pin;

// 100MHz系统时钟
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// 复位
initial begin
    rst_n = 1'b0;
    #200;
    rst_n = 1'b1;
end

// 例化顶层
top_pl_uart_matmul u_top(
    .clk(clk),
    .rst_n(rst_n),
    .rx_pin(rx_pin),
    .tx_pin(tx_pin)
);

// UART发送任务：发送1字节，波特率115200，位周期≈8681ns
task uart_send_byte;
    input [7:0] data;
    integer i;
begin
    rx_pin <= 1'b1;
    #8681;
    rx_pin <= 1'b0;        //起始位
    #8681;
    for(i=0;i<8;i=i+1) begin
        rx_pin <= data[i];
        #8681;
    end
    rx_pin <= 1'b1;        //停止位
    #8681;
end
endtask

// 测试序列：发送64个INT8测试矩阵数据，送入PL串口
initial begin
    rx_pin = 1'b1;
    #300;
    // 发送64个数据：全部是8'd1，矩阵乘法累加结果=64*1*1=64
    repeat(64) begin
        uart_send_byte(8'd1);
    end
    
    #2000000; //等待运算+串口回传
    $display("========仿真结束========");
    $finish;
end

// 波形dump，Vivado自动抓取所有信号
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, top_pl_uart_matmul_tb);
end

endmodule