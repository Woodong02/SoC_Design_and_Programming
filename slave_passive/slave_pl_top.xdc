# slave_pl_top.xdc
# 마스터(top.xdc)와 크로스 연결 기준으로 작성.
#   Master GPIO_out (E16) → 슬레이브 i_master_serial
#   Master GPIO_in  (F16) ← 슬레이브 o_slave_serial

# Clock
set_property IOSTANDARD "LVCMOS33" [get_ports "i_clk"]
set_property PACKAGE_PIN "M19"     [get_ports "i_clk"]
create_clock -period 40 -name i_clk -waveform {0.000 20} [get_ports i_clk]

# Reset (active-low button)
set_property IOSTANDARD "LVCMOS33" [get_ports "i_resetn"]
set_property PACKAGE_PIN "Y18"     [get_ports "i_resetn"]

# Serial RX: 마스터 GPIO_out과 크로스 연결
set_property IOSTANDARD "LVCMOS33" [get_ports "i_master_serial"]
set_property PACKAGE_PIN "E16"     [get_ports "i_master_serial"]
set_property PULLDOWN   "TRUE"     [get_ports "i_master_serial"]

# Serial TX: 마스터 GPIO_in과 크로스 연결
set_property IOSTANDARD "LVCMOS33" [get_ports "o_slave_serial"]
set_property PACKAGE_PIN "F16"     [get_ports "o_slave_serial"]

# LED[0]: 수신선 상태 (마스터 LED_in과 같은 핀)
set_property IOSTANDARD "LVCMOS33" [get_ports "o_led[0]"]
set_property PACKAGE_PIN "T16"     [get_ports "o_led[0]"]

# LED[1]: 송신선 상태 (마스터 LED_out과 같은 핀)
set_property IOSTANDARD "LVCMOS33" [get_ports "o_led[1]"]
set_property PACKAGE_PIN "T17"     [get_ports "o_led[1]"]
