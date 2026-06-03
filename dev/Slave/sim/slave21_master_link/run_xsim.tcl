set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ".." ".."]]
set run_dir [file normalize [file join $script_dir "xsim_run"]]

file mkdir $run_dir
cd $run_dir

set files [list \
    [file join $repo_root "Master_ip" "hamming_enc.v"] \
    [file join $repo_root "Master_ip" "hamming_dec.v"] \
    [file join $repo_root "Master_ip" "Master_tx.v"] \
    [file join $repo_root "Master_ip" "Master_rx.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "reuse" "slave2_line_sync.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "reuse" "slave_hamming_enc.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "reuse" "slave_hamming_dec.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "reuse" "slave_control.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "slave21_rx.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "slave21_fault_fsm.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "slave21_timebase.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "slave21_tx.v"] \
    [file join $repo_root "Slave_ip" "v2_1" "slave21_top.v"] \
    [file join $repo_root "tb" "tb_slave21_master_link.v"] \
]
set vivado_bin "C:/Xilinx/Vivado/2019.1/bin"

file delete -force xsim.dir
file delete -force .Xil
file delete -force xvlog.log
file delete -force xelab.log
file delete -force xsim.log
file delete -force tb_slave21_master_link_sim.wdb
file delete -force webtalk.jou
file delete -force webtalk.log

exec [file join $vivado_bin "xvlog.bat"] -log xvlog.log {*}$files
exec [file join $vivado_bin "xelab.bat"] tb_slave21_master_link -debug typical -s tb_slave21_master_link_sim -log xelab.log
exec [file join $vivado_bin "xsim.bat"] tb_slave21_master_link_sim -runall -log xsim.log
