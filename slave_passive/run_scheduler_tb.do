vlib work
vmap work work

vlog -work work rtl/slave_timing_scheduler.v

vlog -work work tb/tb_slave_timing_scheduler.v

vsim -c work.tb_slave_timing_scheduler -do "run -all; quit"
