set root [file normalize [file join [file dirname [info script]] .. ..]]
set run_dir [file join $root sim slave21_comm_worst_case xsim_run]
file mkdir $run_dir
cd $run_dir

set vivado_bin "C:/Xilinx/Vivado/2019.1/bin"

set sources [list \
    [file join $root Master_ip hamming_enc.v] \
    [file join $root Master_ip hamming_dec.v] \
    [file join $root Master_ip Master_rx.v] \
    [file join $root Slave_ip v2_1 reuse slave2_line_sync.v] \
    [file join $root Slave_ip v2_1 reuse slave_hamming_enc.v] \
    [file join $root Slave_ip v2_1 reuse slave_hamming_dec.v] \
    [file join $root Slave_ip v2_1 reuse slave_control.v] \
    [file join $root Slave_ip v2_1 slave21_rx.v] \
    [file join $root Slave_ip v2_1 slave21_fault_fsm.v] \
    [file join $root Slave_ip v2_1 slave21_timebase.v] \
    [file join $root Slave_ip v2_1 slave21_tx.v] \
    [file join $root Slave_ip v2_1 slave21_top.v] \
    [file join $root tb tb_slave21_comm_worst_case.v] \
]

file delete -force xsim.dir
file delete -force .Xil
file delete -force xvlog.log
file delete -force xelab.log
file delete -force xsim.log
file delete -force tb_slave21_comm_worst_case_sim.wdb
file delete -force webtalk.jou
file delete -force webtalk.log

exec [file join $vivado_bin "xvlog.bat"] -log xvlog.log {*}$sources
exec [file join $vivado_bin "xelab.bat"] tb_slave21_comm_worst_case -debug typical -s tb_slave21_comm_worst_case_sim -log xelab.log
exec [file join $vivado_bin "xsim.bat"] tb_slave21_comm_worst_case_sim -runall -log xsim.log
