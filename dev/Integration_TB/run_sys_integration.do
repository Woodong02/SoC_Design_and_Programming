# run_sys_integration.do — Master_top ↔ tdma_slave_top 3-slave 통합 시뮬레이션
# 실행 위치: Integration_TB/
# 사용법:  vsim -c -do run_sys_integration.do

quietly set VDIR [pwd]
quietly set SDIR $VDIR/Slave
quietly set MDIR $VDIR/Master

vlib work
vmap work work

# Slave RTL (hamming_enc/dec는 slave 버전만; Master_tx도 동일 모듈 참조)
vlog "$SDIR/hamming_enc.v"    \
     "$SDIR/hamming_dec.v"    \
     "$SDIR/clk_div.v"        \
     "$SDIR/master_rx.v"      \
     "$SDIR/slave_tx.v"       \
     "$SDIR/slot_timer.v"     \
     "$SDIR/fault_fsm.v"      \
     "$SDIR/irq_ctrl.v"       \
     "$SDIR/tdma_slave_top.v"

# Master RTL (error_with_hamming.v = Master_dec_ham 모듈)
vlog "$MDIR/bin2seg.v"              \
     "$MDIR/seven_seg.v"            \
     "$MDIR/Master_slot.v"          \
     "$MDIR/Master_tx.v"            \
     "$MDIR/Master_rx.v"            \
     "$MDIR/error_with_hamming.v"   \
     "$MDIR/Master_top.v"

# Integration TB
vlog "$VDIR/tb_sys_integration.v"

vsim -quiet -lib work tb_sys_integration
onfinish stop
run -all
quit -sim
quit -f
