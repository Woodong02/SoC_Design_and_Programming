vlib work
vmap work work

# -----------------------------------------------------------------------
# Master 소스
# -----------------------------------------------------------------------
vlog -work work Master_source/Master_slot.v
vlog -work work Master_source/Master_tx.v
vlog -work work Master_source/Master_rx.v
vlog -work work Master_source/hamming_enc.v
vlog -work work Master_source/hamming_dec.v
vlog -work work Master_source/error_with_hamming.v
vlog -work work Master_source/bin2seg.v
vlog -work work Master_source/seven_seg.v
vlog -work work Master_source/g2m.v
vlog -work work Master_source/rgb.v
vlog -work work Master_source/vertical.v
vlog -work work Master_source/horizontal.v
vlog -work work Master_source/TFTLCDCtrl.v
vlog -work work Master_source/Master_top.v
vlog -work work Master_source/Master_v1_0_S00_AXI.v

# -----------------------------------------------------------------------
# Slave 소스 (test_src: slave_cfg_shadow 직통 pass-through 버전)
# -----------------------------------------------------------------------
vlog -work work test_src/slave_hamming_enc.v
vlog -work work test_src/slave_hamming_dec.v
vlog -work work test_src/slave_cfg_shadow.v
vlog -work work test_src/slave_broadcast_rx.v
vlog -work work test_src/slave_broadcast_decoder.v
vlog -work work test_src/slave_sync_detector.v
vlog -work work test_src/slave_timing_scheduler.v
vlog -work work test_src/slave_tx_serializer.v
vlog -work work test_src/slave_frame_builder.v
vlog -work work test_src/slave_payload_table.v
vlog -work work test_src/slave_slot_sequencer.v
vlog -work work test_src/slave_status_event.v
vlog -work work test_src/slave_ip_top.v

# 버튼 payload 컨트롤러
vlog -work work test_src/btn_payload_ctrl.v

# TB
vlog -work work tb/tb_btn_slave_master_comm.v

# -----------------------------------------------------------------------
# GUI 시뮬레이션 시작 (-novopt: 계층 참조 보존)
# -----------------------------------------------------------------------
vsim -novopt work.tb_btn_slave_master_comm

# -----------------------------------------------------------------------
# 파형 윈도우 구성
# -----------------------------------------------------------------------

# ----- 클럭 / 리셋 / 버튼 -----
add wave -divider "=== Clock / Reset / Button ==="
add wave -noupdate -label clk         /tb_btn_slave_master_comm/clk
add wave -noupdate -label resetn      /tb_btn_slave_master_comm/resetn
add wave -noupdate -label i_BTN       /tb_btn_slave_master_comm/i_BTN

# ----- 버튼 컨트롤러 내부 -----
add wave -divider "=== BTN Payload Controller ==="
add wave -noupdate -label btn_cnt         -radix unsigned /tb_btn_slave_master_comm/u_btn/cnt
add wave -noupdate -label btn_sample_tick /tb_btn_slave_master_comm/u_btn/sample_tick
add wave -noupdate -label btn_q           /tb_btn_slave_master_comm/u_btn/btn_q
add wave -noupdate -label btn_pressed     /tb_btn_slave_master_comm/u_btn/btn_pressed
add wave -noupdate -label btn_payload0    -radix unsigned /tb_btn_slave_master_comm/btn_payload0
add wave -noupdate -label btn_payload1    -radix unsigned /tb_btn_slave_master_comm/btn_payload1
add wave -noupdate -label btn_payload2    -radix unsigned /tb_btn_slave_master_comm/btn_payload2
add wave -noupdate -label btn_payload3    -radix unsigned /tb_btn_slave_master_comm/btn_payload3
add wave -noupdate -label btn_payload4    -radix unsigned /tb_btn_slave_master_comm/btn_payload4
add wave -noupdate -label btn_payload5    -radix unsigned /tb_btn_slave_master_comm/btn_payload5
add wave -noupdate -label btn_payload6    -radix unsigned /tb_btn_slave_master_comm/btn_payload6
add wave -noupdate -label btn_payload7    -radix unsigned /tb_btn_slave_master_comm/btn_payload7

# ----- 직렬 통신선 -----
add wave -divider "=== Serial Lines ==="
add wave -noupdate -label master_serial /tb_btn_slave_master_comm/master_serial
add wave -noupdate -label slave_serial  /tb_btn_slave_master_comm/slave_serial

# ----- 마스터 슬롯 제어 -----
add wave -divider "=== Master Slot Control ==="
add wave -noupdate -label cycle_cnt       -radix unsigned /tb_btn_slave_master_comm/cycle_cnt
add wave -noupdate -label slot            -radix unsigned /tb_btn_slave_master_comm/slot_sig
add wave -noupdate -label slot_pre_change /tb_btn_slave_master_comm/slot_pre_change

# ----- 마스터 수신 결과 — slot_out 0~7 -----
add wave -divider "=== Master Slot Output (payload received) ==="
add wave -noupdate -label slot_out0 -radix unsigned /tb_btn_slave_master_comm/slot_out0
add wave -noupdate -label slot_out1 -radix unsigned /tb_btn_slave_master_comm/slot_out1
add wave -noupdate -label slot_out2 -radix unsigned /tb_btn_slave_master_comm/slot_out2
add wave -noupdate -label slot_out3 -radix unsigned /tb_btn_slave_master_comm/slot_out3
add wave -noupdate -label slot_out4 -radix unsigned /tb_btn_slave_master_comm/slot_out4
add wave -noupdate -label slot_out5 -radix unsigned /tb_btn_slave_master_comm/slot_out5
add wave -noupdate -label slot_out6 -radix unsigned /tb_btn_slave_master_comm/slot_out6
add wave -noupdate -label slot_out7 -radix unsigned /tb_btn_slave_master_comm/slot_out7

# ----- 에러 카운터 -----
add wave -divider "=== Error Counters ==="
add wave -noupdate -label err_cnt0 -radix hex /tb_btn_slave_master_comm/err_cnt0
add wave -noupdate -label err_cnt1 -radix hex /tb_btn_slave_master_comm/err_cnt1
add wave -noupdate -label err_cnt2 -radix hex /tb_btn_slave_master_comm/err_cnt2
add wave -noupdate -label err_cnt3 -radix hex /tb_btn_slave_master_comm/err_cnt3
add wave -noupdate -label err_cnt4 -radix hex /tb_btn_slave_master_comm/err_cnt4
add wave -noupdate -label err_cnt5 -radix hex /tb_btn_slave_master_comm/err_cnt5
add wave -noupdate -label err_cnt6 -radix hex /tb_btn_slave_master_comm/err_cnt6
add wave -noupdate -label err_cnt7 -radix hex /tb_btn_slave_master_comm/err_cnt7

# ----- 슬레이브 TX 프레임 -----
add wave -divider "=== Slave TX Frame ==="
add wave -noupdate -label slv_tx_frame_valid /tb_btn_slave_master_comm/slv_tx_frame_valid
add wave -noupdate -label slv_tx_frame_ready /tb_btn_slave_master_comm/slv_tx_frame_ready
add wave -noupdate -label slv_tx_slot_id  -radix unsigned /tb_btn_slave_master_comm/slv_tx_slot_id
add wave -noupdate -label slv_tx_payload  -radix unsigned /tb_btn_slave_master_comm/slv_tx_payload

# ----- 슬레이브 동기화 / 스케줄러 -----
add wave -divider "=== Slave Sync / Scheduler ==="
add wave -noupdate -label sync_pulse      /tb_btn_slave_master_comm/u_slave_ip_top/sync_pulse
add wave -noupdate -label rx_active       /tb_btn_slave_master_comm/u_slave_ip_top/rx_active
add wave -noupdate -label tx_active       /tb_btn_slave_master_comm/u_slave_ip_top/tx_active
add wave -noupdate -label schedule_active /tb_btn_slave_master_comm/u_slave_ip_top/schedule_active
add wave -noupdate -label core_idle       /tb_btn_slave_master_comm/u_slave_ip_top/core_idle

# ----- AXI 채널 -----
add wave -divider "=== AXI-Lite Init ==="
add wave -noupdate -label awaddr  -radix hex /tb_btn_slave_master_comm/axi_awaddr
add wave -noupdate -label awvalid /tb_btn_slave_master_comm/axi_awvalid
add wave -noupdate -label wdata   -radix hex /tb_btn_slave_master_comm/axi_wdata
add wave -noupdate -label wvalid  /tb_btn_slave_master_comm/axi_wvalid
add wave -noupdate -label bvalid  /tb_btn_slave_master_comm/axi_bvalid

# -----------------------------------------------------------------------
# 파형 창 설정
# -----------------------------------------------------------------------
configure wave -namecolwidth  220
configure wave -valuecolwidth 120
configure wave -justifyvalue  left
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# -----------------------------------------------------------------------
# 전체 신호 로깅 (add wave에 없는 계층 신호도 시뮬 후 추가 가능)
# -----------------------------------------------------------------------
log -r /*

run -all

# 파형 표시 갱신 및 전체 보기
WaveformUpdate
wave zoom full

# 파형 설정 저장 (나중에 do wave_btn_slave_saved.do 로 복원 가능)
write wave -format do wave_btn_slave_saved.do
