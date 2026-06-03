# run_slave_sys.do — tb_slave_sys 단독 실행
# 사용법: vsim -c -do run_slave_sys.do
#         (Verilog/ 폴더에서 실행)

quietly set VDIR [pwd]

vlib work
vmap work work

vlog "$VDIR/hamming_enc.v"    \
     "$VDIR/hamming_dec.v"    \
     "$VDIR/clk_div.v"        \
     "$VDIR/master_rx.v"      \
     "$VDIR/slave_tx.v"       \
     "$VDIR/slot_timer.v"     \
     "$VDIR/fault_fsm.v"      \
     "$VDIR/irq_ctrl.v"       \
     "$VDIR/tdma_slave_top.v" \
     "$VDIR/tx_data_gen.v"    \
     "$VDIR/tdma_slave_sys.v" \
     "$VDIR/tb_slave_sys.v"

vsim -quiet -lib work tb_slave_sys
onfinish stop
run -all
quit -sim
quit -f
