set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ".." ".."]]
set run_dir [file normalize [file join $script_dir "xsim_run"]]

file mkdir $run_dir
cd $run_dir

set source_file [file join $repo_root "Slave_ip" "v1_0" "slave_control.v"]
set tb_file [file join $repo_root "tb" "tb_slave_control.v"]
set vivado_bin "C:/Xilinx/Vivado/2019.1/bin"

exec [file join $vivado_bin "xvlog.bat"] -log xvlog.log $source_file $tb_file
exec [file join $vivado_bin "xelab.bat"] tb_slave_control -debug typical -s tb_slave_control_sim -log xelab.log
exec [file join $vivado_bin "xsim.bat"] tb_slave_control_sim -runall -log xsim.log
