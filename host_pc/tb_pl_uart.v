module pl_uart_tb;

// 信号声明
reg clk;
reg rst_n;
reg rx_pin;
wire tx_pin;

reg [7:0] tx_data;
reg tx_valid;
wire tx_ready;

wire [7:0] rx_data;
wire rx_valid;
wire rx_sync_done;

// 例化串口模块
pl_uart u_pl_uart(
    .clk(clk),
    .rst_n(rst_n),
    .rx_pin(rx_pin),
    .tx_pin(tx_pin),

    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready),

    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .rx_sync_done(rx_sync_done)
);

// 100MHz时钟，周期10ns
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// UART发送任务：tb模拟串口发送字节，驱动rx_pin，发给pl_uart的接收端
task uart_send_byte;
    input [7:0] din;
    integer i;
begin
    // 起始位 0
    rx_pin <= 1'b0;
    #8680; // 115200波特，1bit时间约8680ns
    // 8bit数据，低位在前
    for(i=0;i<8;i=i+1) begin
        rx_pin <= din[i];
        #8680;
    end
    // 停止位 1
    rx_pin <= 1'b1;
    #8680;
end
endtask

initial begin
    // 初始化
    rst_n = 1'b0;
    rx_pin = 1'b1;
    tx_data = 8'd0;
    tx_valid = 1'b0;
    #20;
    rst_n = 1'b1;
    #100;

    $display("======== 测试接收通路：串口发送 0x55 ========");
    uart_send_byte(8'h55); // 0x55 = 01010101，发给PL串口接收
    #20000;

    $display("======== 测试发送通路：PL向外发送0xAA ========");
    tx_data <= 8'hAA;
    tx_valid <= 1'b1;
    #10;
    tx_valid <= 1'b0;
    wait(tx_ready == 1'b1); // 等待发送完成
    #20000;

    $display("======== 测试接收：0x12 ========");
    uart_send_byte(8'h12);
    #20000;

    $display("======== 仿真结束 ========");
    #10000;
    $finish;
end

// 打印收到的数据
always @(posedge clk) begin
    if(rx_valid) begin
        $display("TB: pl_uart 收到字节 = 0x%h", rx_data);
    end
end

endmodule