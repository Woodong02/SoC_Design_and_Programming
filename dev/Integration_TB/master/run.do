# sim.do — Master 모듈 단위 TB
# 실행 위치: Integration_TB/master/
# 사용법:  vsim -c -do sim.do
# 참고: hamming_enc/dec는 slave 버전($SDIR)으로 컴파일 (중복 방지)

quietly set SDIR [file normalize [file join [pwd] .. ..]]
quietly set MMOD "$SDIR/master_module"
quietly set TB   [pwd]

vlib work
vmap work work

# ── 1. tb_Master_tx ────────────────────────────────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v" "$SDIR/hamming_dec.v" \
     "$MMOD/Master_tx.v" \
     "$TB/tb_Master_tx.v"
vsim -quiet -lib work tb_Master_tx
onfinish stop
run -all
quit -sim

# ── 2. tb_Master_rx ────────────────────────────────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v" "$SDIR/hamming_dec.v" \
     "$MMOD/Master_rx.v" \
     "$TB/tb_Master_rx.v"
vsim -quiet -lib work tb_Master_rx
onfinish stop
run -all
quit -sim

# ── 3. tb_Master_slot ──────────────────────────────────────────────────────
vlib work
vlog "$MMOD/Master_slot.v" \
     "$TB/tb_Master_slot.v"
vsim -quiet -lib work tb_Master_slot
onfinish stop
run -all
quit -sim

# ── 4. tb_Master_dec_ham ───────────────────────────────────────────────────
vlib work
vlog "$SDIR/hamming_enc.v" "$SDIR/hamming_dec.v" \
     "$MMOD/Master_dec_ham.v" \
     "$TB/tb_Master_dec_ham.v"
vsim -quiet -lib work tb_Master_dec_ham
onfinish stop
run -all
quit -sim

quit -f
