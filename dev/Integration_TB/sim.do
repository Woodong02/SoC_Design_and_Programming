# sim.do — Slave + Master 혼합 통합 TB
# 실행 위치: Integration_TB/
# 사용법:  vsim -c -do sim.do

quietly set SDIR [file normalize [file join [pwd] ..]]
quietly set MMOD "$SDIR/master_module"
quietly set TB   [pwd]

vlib work
vmap work work

# ── 1. tb_integration (Slave Top + Master 통신 모듈) ───────────────────────
vlib work
vlog "$SDIR/hamming_enc.v"  "$SDIR/hamming_dec.v" \
     "$SDIR/master_rx.v"    "$SDIR/slave_tx.v"    \
     "$MMOD/Master_tx.v"    "$MMOD/Master_rx.v"   \
     "$MMOD/Master_dec_ham.v" \
     "$TB/tb_integration.v"
vsim -quiet -lib work tb_integration
onfinish stop
run -all
quit -sim

# ── 2. tb_master_top (Master Top + Slave 통신 모듈) ───────────────────────
vlib work
vlog "$SDIR/hamming_enc.v"   "$SDIR/hamming_dec.v"  \
     "$SDIR/master_rx.v"     "$SDIR/slave_tx.v"     \
     "$MMOD/Master_tx.v"     "$MMOD/Master_rx.v"    \
     "$MMOD/Master_slot.v"   "$MMOD/Master_dec_ham.v" \
     "$MMOD/seven_seg.v"     "$MMOD/bin2seg.v"      \
     "$MMOD/Master_top.v"    \
     "$TB/tb_master_top.v"
vsim -quiet -lib work tb_master_top
onfinish stop
run -all
quit -sim

# ── 3. tb_sys_integration (전체 시스템, N=1~6) ─────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v"   "$SDIR/hamming_dec.v"  \
     "$SDIR/master_rx.v"     "$SDIR/slave_tx.v"     \
     "$SDIR/clk_div.v"       "$SDIR/slot_timer.v"   \
     "$SDIR/fault_fsm.v"     "$SDIR/irq_ctrl.v"     \
     "$SDIR/tdma_slave_top.v"                        \
     "$MMOD/Master_tx.v"     "$MMOD/Master_rx.v"    \
     "$MMOD/Master_slot.v"   "$MMOD/Master_dec_ham.v" \
     "$MMOD/seven_seg.v"     "$MMOD/bin2seg.v"      \
     "$MMOD/Master_top.v"    \
     "$TB/tb_sys_integration.v"
vsim -quiet -lib work tb_sys_integration
onfinish stop
run -all
quit -sim

# ── 4. tbfix_n7 (전체 시스템, N=7 오버플로우 수정 검증) ────────────────────
vlib work
vlog "$SDIR/hamming_enc.v"   "$SDIR/hamming_dec.v"  \
     "$SDIR/master_rx.v"     "$SDIR/slave_tx.v"     \
     "$SDIR/clk_div.v"       "$SDIR/slot_timer.v"   \
     "$SDIR/fault_fsm.v"     "$SDIR/irq_ctrl.v"     \
     "$SDIR/tdma_slave_top.v"                        \
     "$MMOD/Master_tx.v"     "$MMOD/Master_rx.v"    \
     "$MMOD/Master_slot.v"   "$MMOD/Master_dec_ham.v" \
     "$MMOD/seven_seg.v"     "$MMOD/bin2seg.v"      \
     "$MMOD/Master_top.v"    \
     "$TB/tbfix_n7.v"
vsim -quiet -lib work tbfix_n7
onfinish stop
run -all
quit -sim

quit -f
