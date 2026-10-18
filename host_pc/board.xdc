#========= 100M PL时钟 C8 =========
create_clock -name clk_100m -period 10 [get_ports clk_100m]
set_property PACKAGE_PIN C8 [get_ports clk_100m]
set_property IOSTANDARD LVCMOS18 [get_ports clk_100m]

# ========= 复位rst_n，SW1 H13（PL按键）=========
set_property PACKAGE_PIN H13 [get_ports rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports rst_n]

# ========= FEP扩展板 PL串口（纯PL，W16/Y16，HP Bank，1.8V）=========
set_property PACKAGE_PIN W16 [get_ports uart_tx]
set_property PACKAGE_PIN Y16 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS18 [get_ports {uart_tx uart_rx}]