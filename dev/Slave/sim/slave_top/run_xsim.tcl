set root [file normalize [file join [file dirname [info script]] .. ..]]
set run_dir [file join $root sim slave_top xsim_run]
file mkdir $run_dir
cd $run_dir

set vivado_bin "C:/Xilinx/Vivado/2019.1/bin"

set sources [list \
    [file join $root Slave_ip v1_0 slave_hamming_enc.v] \
    [file join $root Slave_ip v1_0 slave_hamming_dec.v] \
    [file join $root Slave_ip v1_0 slave_rx.v] \
    [file join $root Slave_ip v1_0 slave_control.v] \
    [file join $root Slave_ip v1_0 slave_slot_timer.v] \
    [file join $root Slave_ip v1_0 slave_tx.v] \
    [file join $root Slave_ip v1_0 slave_top.v] \
    [file join $root tb tb_slave_top.v] \
]

file delete -force xsim.dir
file delete -force .Xil
file delete -force xvlog.log
file delete -force xelab.log
file delete -force xsim.log
file delete -force tb_slave_top_sim.wdb
file delete -force webtalk.jou
file delete -force webtalk.log

exec [file join $vivado_bin "xvlog.bat"] -log xvlog.log {*}$sources
exec [file join $vivado_bin "xelab.bat"] tb_slave_top -debug typical -s tb_slave_top_sim -log xelab.log
exec [file join $vivado_bin "xsim.bat"] tb_slave_top_sim -runall -log xsim.log

