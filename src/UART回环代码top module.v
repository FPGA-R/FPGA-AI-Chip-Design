module uart_loopback (
    input  wire clk_100m,
    input  wire rst_n,
    input  wire uart_rx,
    output wire uart_tx
);

    parameter CLK_FREQ  = 100_000_000;
    parameter BAUD_RATE = 115200;
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // =====================================
    // UART接收模块
    // =====================================

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx_module #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_rx (
        .clk      (clk_100m),
        .rst_n    (rst_n),
        .uart_rx  (uart_rx),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    // =====================================
    // UART发送模块
    // =====================================

    wire       tx_busy;
    wire       tx_start;
    wire [7:0] tx_data;

    uart_tx_module #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (
        .clk      (clk_100m),
        .rst_n    (rst_n),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .uart_tx  (uart_tx),
        .tx_busy  (tx_busy)
    );

    // =====================================
    // FIFO缓存模块
    // 深度16，每个位置保存1字节
    // =====================================

    localparam FIFO_DEPTH = 16;

    reg [7:0] fifo_mem [0:FIFO_DEPTH-1];

    reg [3:0] wr_ptr;
    reg [3:0] rd_ptr;
    reg [4:0] fifo_count;

    wire fifo_push;
    wire fifo_pop;

    // FIFO有数据且发送模块空闲时，取出一个字节
    assign fifo_pop = (fifo_count != 0) && (!tx_busy);

    // FIFO未满，或者当前周期同时取出一个字节时，允许写入
    assign fifo_push = rx_valid &&
                       ((fifo_count < FIFO_DEPTH) || fifo_pop);

    assign tx_start = fifo_pop;
    assign tx_data  = fifo_mem[rd_ptr];

    // FIFO读写控制
    always @(posedge clk_100m or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr     <= 0;
            rd_ptr     <= 0;
            fifo_count <= 0;
        end
        else begin

            // 接收到的数据写入FIFO
            if (fifo_push) begin
                fifo_mem[wr_ptr] <= rx_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            // 将FIFO中的数据交给UART发送模块
            if (fifo_pop) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            // 更新FIFO中的字节数量
            case ({fifo_push, fifo_pop})

                2'b10:
                    fifo_count <= fifo_count + 1'b1;

                2'b01:
                    fifo_count <= fifo_count - 1'b1;

                default:
                    fifo_count <= fifo_count;

            endcase
        end
    end

endmodule


// =====================================================
// UART接收模块
// 波特率115200，数据位8，停止位1，无校验
// =====================================================

module uart_rx_module #(
    parameter CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,

    output reg  [7:0] rx_data,
    output reg        rx_valid
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;

    reg [7:0] rx_shift;

    // UART输入两级同步
    reg rx_sync1;
    reg rx_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end
        else begin
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_shift  <= 0;
            rx_data   <= 0;
            rx_valid  <= 0;
        end
        else begin

            rx_valid <= 1'b0;

            case (state)

                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;

                    if (rx_sync2 == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT / 2 - 1)) begin
                        clk_count <= 0;

                        if (rx_sync2 == 1'b0) begin
                            state <= DATA;
                        end
                        else begin
                            state <= IDLE;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;

                        // UART低位先接收
                        rx_shift[bit_index] <= rx_sync2;

                        if (bit_index == 3'd7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= IDLE;

                        if (rx_sync2 == 1'b1) begin
                            rx_data  <= rx_shift;
                            rx_valid <= 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    clk_count <= 0;
                end

            endcase
        end
    end

endmodule


// =====================================================
// UART发送模块
// 波特率115200，数据位8，停止位1，无校验
// =====================================================

module uart_tx_module #(
    parameter CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       tx_start,
    input  wire [7:0] tx_data,

    output reg        uart_tx,
    output wire       tx_busy
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] tx_shift;

    assign tx_busy = (state != IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift  <= 0;
            uart_tx   <= 1'b1;
        end
        else begin

            case (state)

                IDLE: begin
                    uart_tx   <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_start) begin
                        tx_shift <= tx_data;
                        uart_tx  <= 1'b0;
                        state    <= START;
                    end
                end

                START: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        bit_index <= 0;

                        uart_tx <= tx_shift[0];
                        state   <= DATA;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;

                        if (bit_index == 3'd7) begin
                            uart_tx <= 1'b1;
                            state   <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                            uart_tx <= tx_shift[bit_index + 1'b1];
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= IDLE;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    uart_tx <= 1'b1;
                    clk_count <= 0;
                end

            endcase
        end
    end

endmodule
