vlib work
vmap work work

vlog -work work rtl/btn_payload_ctrl.v
vlog -work work tb/tb_btn_payload_ctrl.v

vsim work.tb_btn_payload_ctrl

# 파형 창 열기
add wave -radix binary   /tb_btn_payload_ctrl/i_CLK
add wave -radix binary   /tb_btn_payload_ctrl/i_RST_N
add wave -radix binary   /tb_btn_payload_ctrl/i_BTN
add wave -radix binary   /tb_btn_payload_ctrl/DUT/sample_tick
add wave -radix binary   /tb_btn_payload_ctrl/DUT/btn_q
add wave -radix binary   /tb_btn_payload_ctrl/DUT/btn_pressed
add wave -radix unsigned /tb_btn_payload_ctrl/DUT/cnt
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD0
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD1
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD2
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD3
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD4
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD5
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD6
add wave -radix unsigned /tb_btn_payload_ctrl/o_PAYLOAD7

run -all
