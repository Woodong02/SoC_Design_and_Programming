set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ".." ".." ".."]]
set work_dir [file normalize [file join $project_root "sim" "master_smoke" "work"]]
file mkdir $work_dir
cd $work_dir

set src_dir [file normalize [file join $project_root "Master_ip"]]
set part_name "xc7z020clg484-1"

puts "SMOKE_CHECK: Vivado version"
version

puts "SMOKE_CHECK: Reading Master_ip Verilog files"
set files [lsort [glob -nocomplain [file join $src_dir "*.v"]]]
foreach f $files {
    puts "SMOKE_CHECK: read_verilog $f"
    read_verilog $f
}

puts "SMOKE_CHECK: Fileset compile order"
set_property top Master_v1_0 [current_fileset]
update_compile_order -fileset sources_1
report_compile_order -fileset sources_1

puts "SMOKE_CHECK: Elaborating/synth RTL for Master_v1_0"
synth_design -rtl -top Master_v1_0 -part $part_name

puts "SMOKE_CHECK: Completed"
