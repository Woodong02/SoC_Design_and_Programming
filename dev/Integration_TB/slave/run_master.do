# run_master.do — Master 모듈 TB 시뮬레이션
# 실행 위치: C:\SoC_Design_and_Programming\dev\Slave\Verilog\
# 사용법:  vsim -c -do run_master.do
#
# TB 실행 순서 (bottom-up):
#   1. tb_Master_tx      — Master NRZ 송신기
#   2. tb_Master_rx      — Master NRZ 수신기
#   3. tb_Master_slot    — 슬롯 타이머
#   4. tb_Master_dec_ham — 슬롯별 수신 복호기
#
# 참고:
#   - hamming_enc/dec는 slave 버전($VDIR)만 컴파일 (master_module 버전과 동일, 중복 방지)
#   - seven_seg, bin2seg, Master_top은 이 do 파일에서 사용 안 함

quietly set VDIR  [pwd]
quietly set TB    $VDIR/tb
quietly set MMOD  $VDIR/master_module

vlib work
vmap work work

# ── 1. tb_Master_tx ──────────────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$MMOD/Master_tx.v" \
     "$TB/tb_Master_tx.v"
vsim -quiet -lib work tb_Master_tx
onfinish stop
run -all
quit -sim

# ── 2. tb_Master_rx ──────────────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$MMOD/Master_rx.v" \
     "$TB/tb_Master_rx.v"
vsim -quiet -lib work tb_Master_rx
onfinish stop
run -all
quit -sim

# ── 3. tb_Master_slot ────────────────────────────────────────────────────────
vlib work
vlog "$MMOD/Master_slot.v" \
     "$TB/tb_Master_slot.v"
vsim -quiet -lib work tb_Master_slot
onfinish stop
run -all
quit -sim

# ── 4. tb_Master_dec_ham ─────────────────────────────────────────────────────
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$MMOD/Master_dec_ham.v" \
     "$TB/tb_Master_dec_ham.v"
vsim -quiet -lib work tb_Master_dec_ham
onfinish stop
run -all
quit -sim

# ── 5. tb_master_top ─────────────────────────────────────────────────────────
# slave 통신 모듈(master_rx, slave_tx)과 master_top 통합 검증
# seven_seg, bin2seg는 master_top 내부에서 인스턴스화되므로 함께 컴파일
vlib work
vlog "$VDIR/hamming_enc.v" "$VDIR/hamming_dec.v" \
     "$VDIR/master_rx.v"   "$VDIR/slave_tx.v"    \
     "$MMOD/Master_tx.v"   "$MMOD/Master_rx.v"   \
     "$MMOD/Master_slot.v" "$MMOD/Master_dec_ham.v" \
     "$MMOD/seven_seg.v"   "$MMOD/bin2seg.v"     \
     "$MMOD/Master_top.v"  \
     "$TB/tb_master_top.v"
vsim -quiet -lib work tb_master_top
onfinish stop
run -all
quit -sim


# ── 6. tb_sys_integration ────────────────────────────────────────────────────
# master_top ↔ tdma_slave_top (6개) 전체 시스템 통합
# GUARD_TICKS=200: slot_ticks=600clk, slave N 응답이 슬롯 N 내 완료 보장
# Bus B tristate: Verilog wire 다중 드라이버 → ModelSim 자동 해석
vlib work
vlog "$VDIR/hamming_enc.v"   "$VDIR/hamming_dec.v"   \
     "$VDIR/master_rx.v"     "$VDIR/slave_tx.v"      \
     "$VDIR/clk_div.v"       "$VDIR/slot_timer.v"    \
     "$VDIR/fault_fsm.v"     "$VDIR/irq_ctrl.v"      \
     "$VDIR/tdma_slave_top.v"                         \
     "$MMOD/Master_tx.v"     "$MMOD/Master_rx.v"     \
     "$MMOD/Master_slot.v"   "$MMOD/Master_dec_ham.v" \
     "$MMOD/seven_seg.v"     "$MMOD/bin2seg.v"       \
     "$MMOD/Master_top.v"    \
     "$TB/tb_sys_integration.v"
vsim -quiet -lib work tb_sys_integration
onfinish stop
run -all
quit -sim


# ── 7. tbfix_n7 ──────────────────────────────────────────────────────────────
# NODE_CNT=7 (7슬레이브) 동작 검증
# 수정 내용: Master_slot.slot/NODE_CNT를 4비트로 확장 → NODE_CNT_p1=8 오버플로우 해결
vlib work
vlog "$VDIR/hamming_enc.v"   "$VDIR/hamming_dec.v"   \
     "$VDIR/master_rx.v"     "$VDIR/slave_tx.v"      \
     "$VDIR/clk_div.v"       "$VDIR/slot_timer.v"    \
     "$VDIR/fault_fsm.v"     "$VDIR/irq_ctrl.v"      \
     "$VDIR/tdma_slave_top.v"                         \
     "$MMOD/Master_tx.v"     "$MMOD/Master_rx.v"     \
     "$MMOD/Master_slot.v"   "$MMOD/Master_dec_ham.v" \
     "$MMOD/seven_seg.v"     "$MMOD/bin2seg.v"       \
     "$MMOD/Master_top.v"    \
     "$TB/tbfix_n7.v"
vsim -quiet -lib work tbfix_n7
onfinish stop
run -all
quit -sim

quit -f
