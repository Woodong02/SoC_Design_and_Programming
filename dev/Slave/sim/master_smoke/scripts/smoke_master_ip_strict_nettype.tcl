set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ".." ".." ".."]]
set work_dir [file normalize [file join $project_root "sim" "master_smoke" "work"]]
file mkdir $work_dir
cd $work_dir

set src_dir [file normalize [file join $project_root "Master_ip"]]
set part_name "xc7z020clg484-1"

puts "STRICT_NETTYPE_CHECK: Creating default_nettype none guard"
set guard_file [file normalize [file join $work_dir "smoke_default_nettype_none.v"]]
set fh [open $guard_file "w"]
puts $fh "`default_nettype none"
close $fh

read_verilog $guard_file

puts "STRICT_NETTYPE_CHECK: Reading Master_ip Verilog files"
set files [lsort [glob -nocomplain [file join $src_dir "*.v"]]]
foreach f $files {
    puts "STRICT_NETTYPE_CHECK: read_verilog $f"
    read_verilog $f
}

set_property top Master_v1_0 [current_fileset]
update_compile_order -fileset sources_1

puts "STRICT_NETTYPE_CHECK: Elaborating/synth RTL for Master_v1_0"
synth_design -rtl -top Master_v1_0 -part $part_name

puts "STRICT_NETTYPE_CHECK: Completed"
