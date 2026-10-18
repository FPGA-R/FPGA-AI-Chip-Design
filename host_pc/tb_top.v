`timescale 1ns/1ps
module tb_top;

reg clk;
reg rst_n;
reg uart_rx;
wire uart_tx;

top_pl_uart_matmul u_dut(
.clk_100m(clk),
.rst_n(rst_n),
.uart_rx(uart_rx),
.uart_tx(uart_tx)
);

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    rst_n = 0;
    uart_rx =1;
    #200;
    rst_n = 1;
    #200000;
    $finish;
end

endmodule