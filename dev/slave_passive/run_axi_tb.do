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

vsim -c work.tb_axi_master_slave_comm -do "run -all; quit"
