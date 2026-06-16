vlib work
vmap work work

# Master sources
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

# Slave sources
vlog -work work rtl/slave_hamming_enc.v
vlog -work work rtl/slave_hamming_dec.v
vlog -work work rtl/slave_cfg_shadow.v
vlog -work work rtl/slave_broadcast_rx.v
vlog -work work rtl/slave_broadcast_decoder.v
vlog -work work rtl/slave_sync_detector.v
vlog -work work rtl/slave_timing_scheduler.v
vlog -work work rtl/slave_tx_serializer.v
vlog -work work rtl/slave_frame_builder.v
vlog -work work rtl/slave_payload_table.v
vlog -work work rtl/slave_slot_sequencer.v
vlog -work work rtl/slave_status_event.v
vlog -work work rtl/slave_ip_top.v
vlog -work work rtl/slave_pl_top.v

# TB
vlog -work work tb/tb_axi_master_slave_comm.v

# GUI 모드로 시뮬레이션 시작 (-novopt: 계층 참조 유지)
vsim -novopt work.tb_axi_master_slave_comm

# -----------------------------------------------------------------------
# 파형 윈도우 구성
# -----------------------------------------------------------------------

# ----- 클럭 / 리셋 -----
add wave -divider "=== Clock / Reset ==="
add wave -noupdate -label clk                /tb_axi_master_slave_comm/clk
add wave -noupdate -label resetn             /tb_axi_master_slave_comm/resetn

# ----- 직렬 통신선 -----
add wave -divider "=== Serial Lines ==="
add wave -noupdate -label master_serial      /tb_axi_master_slave_comm/master_serial
add wave -noupdate -label slave_serial       /tb_axi_master_slave_comm/slave_serial

# ----- 마스터 슬롯 제어 -----
add wave -divider "=== Master Slot Control ==="
add wave -noupdate -label cycle_cnt          -radix unsigned /tb_axi_master_slave_comm/cycle_cnt
add wave -noupdate -label slot               -radix unsigned /tb_axi_master_slave_comm/slot_sig
add wave -noupdate -label slot_pre_change    /tb_axi_master_slave_comm/slot_pre_change
add wave -noupdate -label clk_cnt            -radix unsigned /tb_axi_master_slave_comm/u_master_axi/mt0/s0/clk_cnt
add wave -noupdate -label rx_stat            -radix unsigned /tb_axi_master_slave_comm/u_master_axi/mt0/s0/rx_stat

# ----- 마스터 수신 경로 -----
add wave -divider "=== Master RX ==="
add wave -noupdate -label in_sig             /tb_axi_master_slave_comm/in_sig_w
add wave -noupdate -label data_bus_raw42     -radix hex      /tb_axi_master_slave_comm/data_bus_w
add wave -noupdate -label fixed_data_35      -radix hex      /tb_axi_master_slave_comm/fixed_data_w

# ----- 마스터 슬롯 결과 -----
add wave -divider "=== Master Slot Output ==="
add wave -noupdate -label slot_out0          -radix unsigned /tb_axi_master_slave_comm/slot_out0
add wave -noupdate -label slot_out1          -radix unsigned /tb_axi_master_slave_comm/slot_out1
add wave -noupdate -label slot_out2          -radix unsigned /tb_axi_master_slave_comm/slot_out2
add wave -noupdate -label slot_out3          -radix unsigned /tb_axi_master_slave_comm/slot_out3
add wave -noupdate -label err_cnt0           -radix hex      /tb_axi_master_slave_comm/err_cnt0
add wave -noupdate -label err_cnt1           -radix hex      /tb_axi_master_slave_comm/err_cnt1
add wave -noupdate -label err_cnt2           -radix hex      /tb_axi_master_slave_comm/err_cnt2
add wave -noupdate -label err_cnt3           -radix hex      /tb_axi_master_slave_comm/err_cnt3

# ----- 슬레이브 동기화 / 스케줄러 -----
add wave -divider "=== Slave Sync / Scheduler ==="
add wave -noupdate -label sync_pulse         /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/sync_pulse
add wave -noupdate -label rx_active          /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/rx_active
add wave -noupdate -label tx_active          /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/tx_active
add wave -noupdate -label schedule_active    /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/schedule_active
add wave -noupdate -label sync_tick_cnt      -radix unsigned /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/sync_tick_counter

# ----- 슬레이브 시퀀서 FSM -----
add wave -divider "=== Slave Sequencer ==="
add wave -noupdate -label seq_state          -radix unsigned /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/u_slave_slot_sequencer/state_ff
add wave -noupdate -label seq_slot_idx       -radix unsigned /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/u_slave_slot_sequencer/slot_index_ff
add wave -noupdate -label slot_time_match    -radix hex      /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/slot_time_match
add wave -noupdate -label seq_cycle_done     /tb_axi_master_slave_comm/u_slave/u_slave_ip_top/seq_slot_cycle_done

# ----- 슬레이브 TX 프레임 -----
add wave -divider "=== Slave TX Frame ==="
add wave -noupdate -label tx_frame_valid     /tb_axi_master_slave_comm/slv_tx_frame_valid
add wave -noupdate -label tx_frame_ready     /tb_axi_master_slave_comm/slv_tx_frame_ready
add wave -noupdate -label tx_frame_50b       -radix hex      /tb_axi_master_slave_comm/slv_tx_frame
add wave -noupdate -label tx_slot_id         -radix unsigned /tb_axi_master_slave_comm/slv_tx_slot_id
add wave -noupdate -label tx_payload         -radix hex      /tb_axi_master_slave_comm/slv_tx_payload

# ----- 마스터 AXI-Lite 레지스터 -----
add wave -divider "=== Master AXI Registers ==="
add wave -noupdate -label slv_reg0(cfg)   -radix hex /tb_axi_master_slave_comm/u_master_axi/slv_reg0
add wave -noupdate -label slv_reg1(DIV)   -radix hex /tb_axi_master_slave_comm/u_master_axi/slv_reg1
add wave -noupdate -label slv_reg2(th/irq) -radix hex /tb_axi_master_slave_comm/u_master_axi/slv_reg2
add wave -noupdate -label err_cnt4         -radix hex /tb_axi_master_slave_comm/u_master_axi/err_cnt4
add wave -noupdate -label err_cnt5         -radix hex /tb_axi_master_slave_comm/u_master_axi/err_cnt5
add wave -noupdate -label err_cnt6         -radix hex /tb_axi_master_slave_comm/u_master_axi/err_cnt6
add wave -noupdate -label err_cnt7         -radix hex /tb_axi_master_slave_comm/u_master_axi/err_cnt7
add wave -noupdate -label slot_out4        -radix hex /tb_axi_master_slave_comm/u_master_axi/slot_out4
add wave -noupdate -label slot_out5        -radix hex /tb_axi_master_slave_comm/u_master_axi/slot_out5
add wave -noupdate -label slot_out6        -radix hex /tb_axi_master_slave_comm/u_master_axi/slot_out6
add wave -noupdate -label slot_out7        -radix hex /tb_axi_master_slave_comm/u_master_axi/slot_out7
add wave -noupdate -label cycle_cnt64      -radix unsigned /tb_axi_master_slave_comm/u_master_axi/cycle_cnt
add wave -noupdate -label buffer_out       -radix hex /tb_axi_master_slave_comm/u_master_axi/buffer_out

# ----- AXI-Lite 채널 (PS 초기화 write만 발생) -----
add wave -divider "=== AXI-Lite Channel ==="
add wave -noupdate -label awaddr  -radix hex /tb_axi_master_slave_comm/axi_awaddr
add wave -noupdate -label awvalid /tb_axi_master_slave_comm/axi_awvalid
add wave -noupdate -label wdata   -radix hex /tb_axi_master_slave_comm/axi_wdata
add wave -noupdate -label wvalid  /tb_axi_master_slave_comm/axi_wvalid
add wave -noupdate -label bvalid  /tb_axi_master_slave_comm/axi_bvalid

# -----------------------------------------------------------------------
# 파형 창 정렬 후 실행
# -----------------------------------------------------------------------
configure wave -namecolwidth  200
configure wave -valuecolwidth 120
configure wave -justifyvalue  left
configure wave -signalnamewidth 1
configure wave -timelineunits ns

run -all

wave zoom full
