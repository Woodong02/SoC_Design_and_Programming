set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $script_dir "../.."]]
set work_dir [file join $script_dir "xsim_work"]
set vivado_bin [file normalize [file join $::env(XILINX_VIVADO) "bin"]]
set xvlog_cmd [file join $vivado_bin "xvlog.bat"]
set xelab_cmd [file join $vivado_bin "xelab.bat"]
set xsim_cmd [file join $vivado_bin "xsim.bat"]

proc run_shell_command {cmd_list} {
    puts "CMD: $cmd_list"
    set status [catch {exec {*}$cmd_list 2>@1} result]
    puts $result
    if {$status != 0} {
        error $result
    }
}

file mkdir $work_dir
cd $work_dir

set src_files [list \
    [file join $root_dir "Slave_ip/v1_0/slave_hamming_enc.v"] \
    [file join $root_dir "Slave_ip/v1_0/slave_tx.v"] \
    [file join $root_dir "tb/tb_slave_tx.v"] \
]

foreach src_file $src_files {
    if {![file exists $src_file]} {
        error "Missing source file: $src_file"
    }
}

puts "INFO: slave_tx xsim compile"
run_shell_command [concat [list cmd /c [file nativename $xvlog_cmd]] $src_files]

puts "INFO: slave_tx xsim elaborate"
run_shell_command [list cmd /c [file nativename $xelab_cmd] tb_slave_tx -s tb_slave_tx_sim]

puts "INFO: slave_tx xsim run"
run_shell_command [list cmd /c [file nativename $xsim_cmd] tb_slave_tx_sim -runall]
