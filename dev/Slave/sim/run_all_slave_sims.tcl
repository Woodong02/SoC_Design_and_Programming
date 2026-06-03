set root [file normalize [file join [file dirname [info script]] ..]]
set vivado "C:/Xilinx/Vivado/2019.1/bin/vivado.bat"

set scripts [list \
    [file join $root sim slave_hamming_enc run_xsim.tcl] \
    [file join $root sim slave_hamming_dec run_xsim.tcl] \
    [file join $root sim slave_control run_xsim.tcl] \
    [file join $root sim slave_slot_timer run_xsim.tcl] \
    [file join $root sim slave_tx run_xsim.tcl] \
    [file join $root sim slave_rx run_xsim.tcl] \
    [file join $root sim slave_top run_xsim.tcl] \
    [file join $root sim slave_master_link run_xsim.tcl] \
    [file join $root sim slave_master_harsh_link run_xsim.tcl] \
]

foreach script $scripts {
    puts ""
    puts "============================================================"
    puts "RUN $script"
    puts "============================================================"
    set status [catch {exec $vivado -mode batch -source $script 2>@1} result]
    puts $result
    if {$status != 0} {
        puts "FAIL: $script"
        exit 1
    }
}

puts ""
puts "PASS: run_all_slave_sims completed"
