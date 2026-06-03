set script_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $script_dir ../..]]
set sim_dir [file normalize $script_dir]

cd $sim_dir

create_project slave_hamming_enc_sim ./vivado_slave_hamming_enc_sim -part xc7z020clg484-1 -force

add_files -fileset sim_1 [file join $project_root Slave_ip v1_0 slave_hamming_enc.v]
add_files -fileset sim_1 [file join $project_root Master_ip hamming_enc.v]
add_files -fileset sim_1 [file join $project_root tb tb_slave_hamming_enc.v]

set_property top tb_slave_hamming_enc [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

quit
