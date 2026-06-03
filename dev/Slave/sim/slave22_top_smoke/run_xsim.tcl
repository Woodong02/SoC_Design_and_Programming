set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ".." ".."]]
set run_dir [file normalize [file join $script_dir "xsim_run"]]

file mkdir $run_dir
cd $run_dir

set files [list \
    [file join $repo_root "Slave_ip" "v2_2" "reuse" "slave2_line_sync.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "reuse" "slave_hamming_enc.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "reuse" "slave_hamming_dec.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "reuse" "slave_control.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "reuse" "slave21_rx.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "reuse" "slave21_fault_fsm.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "reuse" "slave21_tx.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "slave22_timebase.v"] \
    [file join $repo_root "Slave_ip" "v2_2" "slave22_top.v"] \
    [file join $repo_root "tb" "tb_slave22_top_smoke.v"] \
]
set vivado_bin "C:/Xilinx/Vivado/2019.1/bin"

exec [file join $vivado_bin "xvlog.bat"] -log xvlog.log {*}$files
exec [file join $vivado_bin "xelab.bat"] tb_slave22_top_smoke -debug typical -s tb_slave22_top_smoke_sim -log xelab.log
exec [file join $vivado_bin "xsim.bat"] tb_slave22_top_smoke_sim -runall -log xsim.log
