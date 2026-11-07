#Verilog UART回环代码

# 100MHz 时钟
create_clock -name clk_100m -period 10 [get_ports clk_100m]
set_property PACKAGE_PIN C8 [get_ports clk_100m]
set_property IOSTANDARD LVCMOS18 [get_ports clk_100m]

# 复位
set_property PACKAGE_PIN H13 [get_ports rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports rst_n]

# FEP UART：默认 3.3V
# B22 UART_TXD -> AF15 -> FPGA uart_rx
# B23 UART_RXD -> AF14 -> FPGA uart_tx
set_property PACKAGE_PIN AF14 [get_ports uart_tx]
set_property PACKAGE_PIN AF15 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_tx uart_rx}]
