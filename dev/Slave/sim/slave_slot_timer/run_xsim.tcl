set root [file normalize [file join [file dirname [info script]] .. ..]]
set src_dir [file join $root Slave_ip v1_0]
set tb_dir  [file join $root tb]
set log_dir [file join $root sim slave_slot_timer logs]
set work_dir [file join $root sim slave_slot_timer work]
file mkdir $log_dir
file mkdir $work_dir

create_project slave_slot_timer_sim $work_dir -part xc7z020clg484-1 -force

add_files -fileset sources_1 [file join $src_dir slave_slot_timer.v]
add_files -fileset sim_1 [file join $tb_dir tb_slave_slot_timer.v]

set_property top tb_slave_slot_timer [current_fileset]
set_property top tb_slave_slot_timer [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
run all
quit
