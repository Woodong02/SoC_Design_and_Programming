# sim.do — Slave 모듈 단위 TB
# 실행 위치: Integration_TB/slave/
# 사용법:  vsim -c -do sim.do

quietly set SDIR [file normalize [file join [pwd] .. ..]]
quietly set TB   [pwd]

vlib work
vmap work work

# ── 1. tb_hamming_enc ──────────────────────────────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v" \
     "$TB/tb_hamming_enc.v"
vsim -quiet -lib work tb_hamming_enc
onfinish stop
run -all
quit -sim

# ── 2. tb_hamming_dec ──────────────────────────────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v" "$SDIR/hamming_dec.v" \
     "$TB/tb_hamming_dec.v"
vsim -quiet -lib work tb_hamming_dec
onfinish stop
run -all
quit -sim

# ── 3. tb_slave_tx ─────────────────────────────────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v" "$SDIR/hamming_dec.v" \
     "$SDIR/slave_tx.v" \
     "$TB/tb_slave_tx.v"
vsim -quiet -lib work tb_slave_tx
onfinish stop
run -all
quit -sim

# ── 4. tb_slot_timer ───────────────────────────────────────────────────────
vlib work
vlog "$SDIR/slot_timer.v" \
     "$TB/tb_slot_timer.v"
vsim -quiet -lib work tb_slot_timer
onfinish stop
run -all
quit -sim

# ── 5. tb_fault_fsm ────────────────────────────────────────────────────────
vlib work
vlog "$SDIR/fault_fsm.v" \
     "$TB/tb_fault_fsm.v"
vsim -quiet -lib work tb_fault_fsm
onfinish stop
run -all
quit -sim

# ── 6. tb_irq_ctrl ─────────────────────────────────────────────────────────
vlib work
vlog "$SDIR/irq_ctrl.v" \
     "$TB/tb_irq_ctrl.v"
vsim -quiet -lib work tb_irq_ctrl
onfinish stop
run -all
quit -sim

# ── 7. tb_tdma_slave_top ───────────────────────────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v" "$SDIR/hamming_dec.v" \
     "$SDIR/clk_div.v"     "$SDIR/master_rx.v"   \
     "$SDIR/slave_tx.v"    "$SDIR/slot_timer.v"  \
     "$SDIR/fault_fsm.v"   "$SDIR/irq_ctrl.v"    \
     "$SDIR/tdma_slave_top.v" \
     "$TB/tb_tdma_slave_top.v"
vsim -quiet -lib work tb_tdma_slave_top
onfinish stop
run -all
quit -sim

quit -f
