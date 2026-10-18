module pl_uart(
input clk,
input rst_n,
input rx_pin,
output reg tx_pin,

input [7:0] tx_data,
input tx_valid,
output reg tx_ready,

output reg [7:0] rx_data,
output reg rx_valid,
output rx_sync_done
);

localparam CLK_FREQ = 100000000;
localparam BAUD = 115200;
localparam DIV_CNT = CLK_FREQ / BAUD;

assign rx_sync_done = 1'b1;

reg [1:0] rx_sync_reg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rx_sync_reg <= 2'b11;
    else rx_sync_reg <= {rx_sync_reg[0], rx_pin};
end
wire rx_synced = rx_sync_reg[1];

reg [15:0] rx_cnt;
reg [3:0] rx_bit_cnt;
reg rx_busy;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_cnt <= 0; rx_bit_cnt <=0; rx_busy <=0; rx_data <=0; rx_valid <=0;
    end else begin
        rx_valid <= 1'b0;
        if(!rx_busy) begin
            if(!rx_synced) begin
                rx_busy <= 1'b1;
                rx_cnt <= DIV_CNT/2;
                rx_bit_cnt <= 4'd0;
            end
        end else begin
            rx_cnt <= rx_cnt + 1'b1;
            if(rx_cnt == DIV_CNT - 1) begin
                rx_cnt <= 0;
                rx_bit_cnt <= rx_bit_cnt + 1'b1;
                case(rx_bit_cnt)
                    4'd0: ; //起始位
                    4'd1: rx_data[0] <= rx_synced;
                    4'd2: rx_data[1] <= rx_synced;
                    4'd3: rx_data[2] <= rx_synced;
                    4'd4: rx_data[3] <= rx_synced;
                    4'd5: rx_data[4] <= rx_synced;
                    4'd6: rx_data[5] <= rx_synced;
                    4'd7: rx_data[6] <= rx_synced;
                    4'd8: rx_data[7] <= rx_synced;
                    4'd9: begin rx_valid <= 1'b1; rx_busy <= 1'b0; end //停止位
                endcase
            end
        end
    end
end

reg [15:0] tx_cnt;
reg [3:0] tx_bit_cnt;
reg tx_busy;
reg [7:0] tx_shift_reg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_pin <= 1'b1; tx_ready <= 1'b1; tx_cnt <=0; tx_bit_cnt <=0; tx_busy <=0; tx_shift_reg <=0;
    end else begin
        if(!tx_busy) begin
            tx_ready <= 1'b1;
            if(tx_valid) begin
                tx_ready <= 1'b0;
                tx_busy <= 1'b1;
                tx_shift_reg <= tx_data;
                tx_bit_cnt <= 0;
                tx_cnt <= 0;
            end
        end else begin
            tx_ready <= 1'b0;
            tx_cnt <= tx_cnt + 1'b1;
            if(tx_cnt == DIV_CNT - 1) begin
                tx_cnt <= 0;
                tx_bit_cnt <= tx_bit_cnt + 1'b1;
                case(tx_bit_cnt)
                    4'd0: tx_pin <= 1'b0;
                    4'd1: tx_pin <= tx_shift_reg[0];
                    4'd2: tx_pin <= tx_shift_reg[1];
                    4'd3: tx_pin <= tx_shift_reg[2];
                    4'd4: tx_pin <= tx_shift_reg[3];
                    4'd5: tx_pin <= tx_shift_reg[4];
                    4'd6: tx_pin <= tx_shift_reg[5];
                    4'd7: tx_pin <= tx_shift_reg[6];
                    4'd8: tx_pin <= tx_shift_reg[7];
                    4'd9: begin tx_pin <= 1'b1; tx_busy <= 1'b0; end
                endcase
            end
        end
    end
end

endmodule