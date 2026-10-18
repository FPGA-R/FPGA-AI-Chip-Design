module top_pl_uart_matmul(
    input               clk,
    input               rst_n,
    input               rx_pin,
    output              tx_pin
);

//==================== 状态定义 ====================
localparam IDLE        = 3'd0;
localparam RX_DATA     = 3'd1;
localparam LOAD_BRAM   = 3'd2;
localparam MAT_MUL     = 3'd3;
localparam SEND_RESULT = 3'd4;

reg [2:0] state;
reg [8:0] data_cnt;

//==================== 内部信号定义 ====================
// BRAM 控制信号（always块内赋值 → reg）
reg                 bram_wr_en;
reg [8:0]           bram_wr_addr;
reg [7:0]           bram_wr_data;
reg                 bram_rd_en;
reg [8:0]           bram_rd_addr;
wire [7:0]          bram_rd_data;
reg                 fifo_tx_rd_en;
wire [7:0]          fifo_tx_dout;

// MAC单元信号
reg  signed [7:0]   mac_din_a;
reg  signed [7:0]   mac_din_b;
reg                 mac_valid_in;
reg                 mac_clr_acc;
wire signed [15:0]  mac_acc_out;
wire                mac_valid_out;

// RX FIFO（串口接收缓存）
reg                 fifo_rx_rd_en;
wire [7:0]          fifo_rx_dout;
wire                fifo_rx_full;
wire                fifo_rx_empty;

// TX FIFO（结果发送缓存）
reg                 fifo_tx_wr_en;
reg [7:0]           fifo_tx_din;
wire                fifo_tx_full;
wire                fifo_tx_empty;

// UART模块信号
reg                 uart_tx_valid;
reg [7:0]           uart_tx_data;
wire [7:0]          uart_rx_data;
wire                uart_rx_valid;
wire                uart_tx_ready;

//==================== 主状态机时序逻辑 ====================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state           <= IDLE;
        data_cnt        <= 9'd0;
        bram_wr_en      <= 1'b0;
        bram_wr_addr    <= 9'd0;
        bram_wr_data    <= 8'd0;
        bram_rd_en      <= 1'b0;
        bram_rd_addr    <= 9'd0;
        mac_din_a       <= 8'd0;
        mac_din_b       <= 8'd0;
        mac_valid_in    <= 1'b0;
        mac_clr_acc     <= 1'b0;
        fifo_rx_rd_en   <= 1'b0;
        fifo_tx_wr_en   <= 1'b0;
        fifo_tx_din     <= 8'd0;
        uart_tx_valid   <= 1'b0;
        uart_tx_data    <= 8'd0;
        fifo_tx_rd_en   <= 1'b0;
    end else begin
        // 默认值，避免锁存
        bram_wr_en      <= 1'b0;
        bram_rd_en      <= 1'b0;
        mac_valid_in    <= 1'b0;
        mac_clr_acc     <= 1'b0;
        fifo_rx_rd_en   <= 1'b0;
        fifo_tx_wr_en   <= 1'b0;
        uart_tx_valid   <= 1'b0;
        fifo_tx_rd_en   <= 1'b0;

        case(state)
            IDLE: begin
                data_cnt <= 9'd0;
                mac_clr_acc <= 1'b1; // MAC累加清零
                if(!fifo_rx_empty) begin
                    state <= RX_DATA;
                end
            end

            RX_DATA: begin
                // 读FIFO，把串口收到的数据写入BRAM
                if(!fifo_rx_empty) begin
                    fifo_rx_rd_en <= 1'b1;
                    bram_wr_en    <= 1'b1;
                    bram_wr_addr  <= data_cnt;
                    bram_wr_data  <= fifo_rx_dout;
                    data_cnt <= data_cnt + 9'd1;
                    if(data_cnt == 9'd511) begin // BRAM深度512
                        data_cnt <= 9'd0;
                        state <= LOAD_BRAM;
                    end
                end else begin
                    state <= LOAD_BRAM;
                end
            end

            LOAD_BRAM: begin
                // 从BRAM读出矩阵A、B送入MAC做乘累加
                bram_rd_en <= 1'b1;
                bram_rd_addr <= data_cnt;
                mac_din_a <= bram_rd_data;
                mac_din_b <= bram_rd_data;
                mac_valid_in <= 1'b1;
                data_cnt <= data_cnt + 9'd1;
                if(data_cnt == 9'd511) begin
                    data_cnt <= 9'd0;
                    state <= MAT_MUL;
                end
            end

            MAT_MUL: begin
                // MAC运算完成，把结果写入TX FIFO
                if(mac_valid_out) begin
                    fifo_tx_wr_en <= 1'b1;
                    fifo_tx_din <= mac_acc_out[7:0]; //低8位，可根据需求改成16bit拆分
                    state <= SEND_RESULT;
                end
            end

            SEND_RESULT: begin
    // 从TX FIFO读出，串口回传PC
    if(!fifo_tx_empty && uart_tx_ready) begin
        fifo_tx_rd_en <= 1'b1;
        uart_tx_valid <= 1'b1;
        uart_tx_data <= fifo_tx_dout;
    end
    if(fifo_tx_empty) begin
        state <= IDLE;
    end
end
            default: state <= IDLE;
        endcase
    end
end

//==================== 模块例化 ====================
// UART模块
pl_uart u_pl_uart(
    .clk(clk),
    .rst_n(rst_n),
    .rx_pin(rx_pin),
    .tx_pin(tx_pin),

    .tx_data(uart_tx_data),
    .tx_valid(uart_tx_valid),
    .tx_ready(uart_tx_ready),

    .rx_data(uart_rx_data),
    .rx_valid(uart_rx_valid),
    .rx_sync_done()
);

// RX FIFO IP（接收串口数据）
fifo_rx u_fifo_rx(
  .clk(clk),
  .rst(!rst_n),
  .din(uart_rx_data),
  .wr_en(uart_rx_valid),
  .rd_en(fifo_rx_rd_en),
  .dout(fifo_rx_dout),
  .full(fifo_rx_full),
  .empty(fifo_rx_empty)
);

// TX FIFO IP（缓存运算结果）
fifo_tx u_fifo_tx(
  .clk(clk),
  .rst(!rst_n),
  .din(fifo_tx_din),
  .wr_en(fifo_tx_wr_en),
  .rd_en(fifo_tx_rd_en),
  .dout(fifo_tx_dout),
  .full(fifo_tx_full),
  .empty(fifo_tx_empty)
);

// MAC单元（带累加清零）
mac_unit u_mac(
    .clk(clk),
    .rst_n(rst_n),
    .din_a(mac_din_a),
    .din_b(mac_din_b),
    .valid_in(mac_valid_in),
    .acc_clr(mac_clr_acc),
    .acc_out(mac_acc_out),
    .valid_out(mac_valid_out)
);

// BRAM控制器
bram_ctrl u_bram(
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(bram_wr_en),
    .wr_addr(bram_wr_addr),
    .wr_data(bram_wr_data),
    .rd_en(bram_rd_en),
    .rd_addr(bram_rd_addr),
    .rd_data(bram_rd_data)
);

endmodule