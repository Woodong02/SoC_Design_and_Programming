set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir "../.."]]
set sim_dir [file normalize $script_dir]

cd $sim_dir

set vivado_bin_dir [file dirname [info nameofexecutable]]
if {![file exists [file join $vivado_bin_dir "xvlog.bat"]]} {
    set vivado_bin_dir [file normalize [file join $vivado_bin_dir "../.."]]
}
set xvlog_cmd [file join $vivado_bin_dir "xvlog.bat"]
set xelab_cmd [file join $vivado_bin_dir "xelab.bat"]
set xsim_cmd  [file join $vivado_bin_dir "xsim.bat"]

proc run_cmd {cmd args} {
    puts ""
    puts "RUN: $cmd $args"
    set status [catch {exec $cmd {*}$args 2>@1} result]
    puts $result
    if {$status != 0} {
        puts "ERROR: command failed"
        exit 1
    }
}

set source_files [list \
    [file join $project_root "Master_ip/hamming_enc.v"] \
    [file join $project_root "Master_ip/hamming_dec.v"] \
    [file join $project_root "Slave_ip/v1_0/slave_hamming_dec.v"] \
    [file join $project_root "tb/tb_slave_hamming_dec.v"] \
]

file delete -force xsim.dir
file delete -force .Xil
file delete -force xvlog.log
file delete -force xelab.log
file delete -force xsim.log
file delete -force tb_slave_hamming_dec_sim.wdb
file delete -force webtalk.jou
file delete -force webtalk.log

run_cmd $xvlog_cmd {*}$source_files
run_cmd $xelab_cmd -debug typical tb_slave_hamming_dec -s tb_slave_hamming_dec_sim
run_cmd $xsim_cmd tb_slave_hamming_dec_sim -runall

puts ""
puts "slave_hamming_dec xsim flow completed"
