# run.do — TDMA Slave IP 전체 시뮬레이션
# 실행 위치: C:\SoC_Design_and_Programming\dev\Slave\Verilog\
# 사용법:  vsim -c -do run.do
#
# TB 실행 순서 (bottom-up):
#   1. tb_hamming_enc   — 인코더 단위
#   2. tb_hamming_dec   — 복호기 단위
#   3. tb_master_rx     — Bus A 수신기 단위
#   4. tb_slave_tx      — Bus B 송신기 단위
#   5. tb_slot_timer    — 슬롯 타이머 단위
#   6. tb_fault_fsm     — 장애 FSM 단위
#   7. tb_irq_ctrl      — IRQ 컨트롤러 단위
#   8. tb_tdma_slave_top — 슬레이브 탑 레벨
#   9. tb_integration    — Master ↔ Slave 통합

quietly set VDIR  [pwd]
quietly set TB    $VDIR/tb
quietly set MMOD  $VDIR/master_module
# MMOD 경로 변경 이력: sim_Master_*.v 삭제, test용 폴더 통합, Master_dec_ham.v 이름 변경

vlib work
vmap work work

# ── 1. tb_hamming_enc ─────────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" \
     "$TB/tb_hamming_enc.v"
vsim -quiet -lib work tb_hamming_enc
onfinish stop
run -all
quit -sim

# ── 2. tb_hamming_dec ─────────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$TB/tb_hamming_dec.v"
vsim -quiet -lib work tb_hamming_dec
onfinish stop
run -all
quit -sim

# ── 3. tb_master_rx ───────────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$VDIR/master_rx.v" \
     "$TB/tb_master_rx.v"
vsim -quiet -lib work tb_master_rx
onfinish stop
run -all
quit -sim

# ── 4. tb_slave_tx ────────────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$VDIR/slave_tx.v" \
     "$TB/tb_slave_tx.v"
vsim -quiet -lib work tb_slave_tx
onfinish stop
run -all
quit -sim

# ── 5. tb_slot_timer ──────────────────────────────────────────────────────
vlib work
vlog "$VDIR/slot_timer.v" \
     "$TB/tb_slot_timer.v"
vsim -quiet -lib work tb_slot_timer
onfinish stop
run -all
quit -sim

# ── 6. tb_fault_fsm ───────────────────────────────────────────────────────
vlib work
vlog "$VDIR/fault_fsm.v" \
     "$TB/tb_fault_fsm.v"
vsim -quiet -lib work tb_fault_fsm
onfinish stop
run -all
quit -sim

# ── 7. tb_irq_ctrl ────────────────────────────────────────────────────────
vlib work
vlog "$VDIR/irq_ctrl.v" \
     "$TB/tb_irq_ctrl.v"
vsim -quiet -lib work tb_irq_ctrl
onfinish stop
run -all
quit -sim

# ── 8. tb_tdma_slave_top ──────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$VDIR/clk_div.v"     "$VDIR/master_rx.v"   \
     "$VDIR/slave_tx.v"    "$VDIR/slot_timer.v"  \
     "$VDIR/fault_fsm.v"   "$VDIR/irq_ctrl.v"    \
     "$VDIR/tdma_slave_top.v" \
     "$TB/tb_tdma_slave_top.v"
vsim -quiet -lib work tb_tdma_slave_top
onfinish stop
run -all
quit -sim

# ── 9. tb_integration (Master ↔ Slave 통합) ───────────────────────────────
# hamming_enc/dec는 slave 버전($VDIR)만 컴파일. Master 모듈도 같은 work 라이브러리를 공유함.
vlib work
vlog "$VDIR/hamming_enc.v"  "$VDIR/hamming_dec.v" \
     "$VDIR/master_rx.v"    "$VDIR/slave_tx.v"    \
     "$MMOD/Master_tx.v"    \
     "$MMOD/Master_rx.v"    \
     "$MMOD/Master_dec_ham.v" \
     "$TB/tb_integration.v"
vsim -quiet -lib work tb_integration
onfinish stop
run -all
quit -sim

quit -f
