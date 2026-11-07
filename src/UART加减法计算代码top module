
`timescale 1ns / 1ps

// ============================================================
// 顶层模块：纯PL UART 8位加减法计算器
//
// UART参数：115200 baud, 8 data bits, 1 stop bit, no parity
//
// 请求帧：A5 OP A B
// OP=01：A+B
// OP=02：A-B
//
// 响应帧：5A OP RESULT_H RESULT_L
//
// 例如：
// A5 01 12 34 -> 5A 01 00 46
// A5 02 12 34 -> 5A 02 FF DE
// ============================================================

module uart_calculator #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire clk_100m,
    input  wire rst_n,
    input  wire uart_rx,
    output wire uart_tx
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // --------------------------------------------------------
    // UART接收模块
    // --------------------------------------------------------

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx_module #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_rx (
        .clk       (clk_100m),
        .rst_n     (rst_n),
        .uart_rx   (uart_rx),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid)
    );

    // --------------------------------------------------------
    // UART发送模块
    // --------------------------------------------------------

    wire       tx_start;
    wire [7:0] tx_data;
    wire       tx_busy;

    uart_tx_module #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (
        .clk       (clk_100m),
        .rst_n     (rst_n),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .uart_tx   (uart_tx),
        .tx_busy   (tx_busy)
    );

    // --------------------------------------------------------
    // 指令解析状态机
    // --------------------------------------------------------

    localparam CMD_HEADER = 2'd0;
    localparam CMD_OPCODE = 2'd1;
    localparam CMD_A      = 2'd2;
    localparam CMD_B      = 2'd3;

    reg [1:0] cmd_state;

    reg [7:0] opcode_reg;
    reg [7:0] operand_a;

    // 9位减法结果，支持-255到255
    wire [8:0] sub_result;

    assign sub_result =
        {1'b0, operand_a} - {1'b0, rx_data};

    // --------------------------------------------------------
    // 运算结果寄存器
    // --------------------------------------------------------

    reg [15:0] result_reg;
    reg [7:0]  response_opcode;

    // --------------------------------------------------------
    // 响应发送状态机
    // --------------------------------------------------------

    localparam RSP_IDLE      = 3'd0;
    localparam RSP_SEND      = 3'd1;
    localparam RSP_WAIT_BUSY = 3'd2;
    localparam RSP_WAIT_DONE = 3'd3;

    reg [2:0] rsp_state;
    reg [1:0] rsp_index;

    // 根据发送索引选择响应帧中的字节
    reg [7:0] tx_data_select;

    always @(*) begin
        case (rsp_index)
            2'd0: tx_data_select = 8'h5A;
            2'd1: tx_data_select = response_opcode;
            2'd2: tx_data_select = result_reg[15:8];
            2'd3: tx_data_select = result_reg[7:0];
            default: tx_data_select = 8'h00;
        endcase
    end

    assign tx_data = tx_data_select;

    // 发送状态机处于SEND且TX空闲时，启动一次发送
    assign tx_start =
        (rsp_state == RSP_SEND) && (!tx_busy);

    // --------------------------------------------------------
    // 主控制逻辑
    // --------------------------------------------------------

    always @(posedge clk_100m or negedge rst_n) begin

        if (!rst_n) begin

            cmd_state      <= CMD_HEADER;
            opcode_reg     <= 8'h00;
            operand_a      <= 8'h00;

            result_reg     <= 16'h0000;
            response_opcode <= 8'h00;

            rsp_state      <= RSP_IDLE;
            rsp_index      <= 2'd0;

        end
        else begin

            // ================================================
            // 第一部分：接收和解析请求帧
            // 采用停等协议：上一帧响应完成后再接收下一帧
            // ================================================

            if ((rsp_state == RSP_IDLE) && rx_valid) begin

                case (cmd_state)

                    // 等待帧头 A5
                    CMD_HEADER: begin

                        if (rx_data == 8'hA5) begin
                            cmd_state <= CMD_OPCODE;
                        end

                    end

                    // 接收运算指令
                    CMD_OPCODE: begin

                        opcode_reg <= rx_data;
                        cmd_state  <= CMD_A;

                    end

                    // 接收操作数A
                    CMD_A: begin

                        operand_a <= rx_data;
                        cmd_state <= CMD_B;

                    end

                    // 接收操作数B并执行运算
                    CMD_B: begin

                        cmd_state <= CMD_HEADER;

                        if (opcode_reg == 8'h01) begin

                            // 8位无符号加法，结果扩展到16位
                            result_reg <=
                                {8'h00, operand_a} +
                                {8'h00, rx_data};

                            response_opcode <= 8'h01;

                            rsp_index <= 2'd0;
                            rsp_state <= RSP_SEND;

                        end
                        else if (opcode_reg == 8'h02) begin

                            // 9位减法结果进行符号扩展
                            result_reg <=
                                {{7{sub_result[8]}}, sub_result};

                            response_opcode <= 8'h02;

                            rsp_index <= 2'd0;
                            rsp_state <= RSP_SEND;

                        end
                        else begin

                            // 不支持的指令，丢弃本帧
                            cmd_state <= CMD_HEADER;

                        end

                    end

                    default: begin
                        cmd_state <= CMD_HEADER;
                    end

                endcase

            end

            // ================================================
            // 第二部分：发送响应帧
            // 每个字节都等待TX完成后再发送下一个字节
            // ================================================

            case (rsp_state)

                RSP_IDLE: begin
                    // 等待完整请求帧
                end

                RSP_SEND: begin

                    if (!tx_busy) begin
                        // tx_start同时有效，TX在本时钟沿接收数据
                        rsp_state <= RSP_WAIT_BUSY;
                    end

                end

                RSP_WAIT_BUSY: begin

                    if (tx_busy) begin
                        rsp_state <= RSP_WAIT_DONE;
                    end

                end

                RSP_WAIT_DONE: begin

                    if (!tx_busy) begin

                        if (rsp_index == 2'd3) begin

                            // 四个字节全部发送完成
                            rsp_state <= RSP_IDLE;

                        end
                        else begin

                            rsp_index <= rsp_index + 1'b1;
                            rsp_state <= RSP_SEND;

                        end

                    end

                end

                default: begin
                    rsp_state <= RSP_IDLE;
                end

            endcase

        end
    end

endmodule


// ============================================================
// UART接收模块
// 115200 baud, 8N1
// ============================================================

module uart_rx_module #(
    parameter integer CLKS_PER_BIT = 868
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

    // 两级同步器
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

                        // UART低位先传输
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


// ============================================================
// UART发送模块
// 115200 baud, 8N1
// ============================================================

module uart_tx_module #(
    parameter integer CLKS_PER_BIT = 868
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
