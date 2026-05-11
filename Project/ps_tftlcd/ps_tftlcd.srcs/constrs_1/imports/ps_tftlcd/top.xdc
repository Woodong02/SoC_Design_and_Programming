set_property IOSTANDARD "LVCMOS33" [get_ports "clk_0"]
set_property PACKAGE_PIN "M19" [get_ports "clk_0"]

set_property IOSTANDARD "LVCMOS33" [get_ports "opclk_0"]
set_property PACKAGE_PIN "L17" [get_ports "opclk_0"]

set_property IOSTANDARD "LVCMOS33" [get_ports "Vsync_0"]
set_property PACKAGE_PIN "M17" [get_ports "Vsync_0"]

set_property IOSTANDARD "LVCMOS33" [get_ports "Hsync_0"]
set_property PACKAGE_PIN "N17" [get_ports "Hsync_0"]

set_property IOSTANDARD "LVCMOS33" [get_ports "R_0[*]"]
set_property PACKAGE_PIN "T22" [get_ports "R_0[4]"]
set_property PACKAGE_PIN "U21" [get_ports "R_0[3]"]
set_property PACKAGE_PIN "T21" [get_ports "R_0[2]"]
set_property PACKAGE_PIN "K20" [get_ports "R_0[1]"]
set_property PACKAGE_PIN "K19" [get_ports "R_0[0]"]

set_property IOSTANDARD "LVCMOS33" [get_ports "G_0[*]"]
set_property PACKAGE_PIN "L22" [get_ports "G_0[5]"]
set_property PACKAGE_PIN "L21" [get_ports "G_0[4]"]
set_property PACKAGE_PIN "K21" [get_ports "G_0[3]"]
set_property PACKAGE_PIN "J20" [get_ports "G_0[2]"]
set_property PACKAGE_PIN "J22" [get_ports "G_0[1]"]
set_property PACKAGE_PIN "J21" [get_ports "G_0[0]"]

set_property IOSTANDARD "LVCMOS33" [get_ports "B_0[*]"]
set_property PACKAGE_PIN "K18" [get_ports "B_0[4]"]
set_property PACKAGE_PIN "J18" [get_ports "B_0[3]"]
set_property PACKAGE_PIN "M16" [get_ports "B_0[2]"]
set_property PACKAGE_PIN "M15" [get_ports "B_0[1]"]
set_property PACKAGE_PIN "N18" [get_ports "B_0[0]"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_DE_out_0"]
set_property PACKAGE_PIN "U22" [get_ports "TFTLCD_DE_out_0"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_Tpower_0"]
set_property PACKAGE_PIN "W22" [get_ports "TFTLCD_Tpower_0"]

create_clock -period 40 -name clk -waveform {0.000 20} [get_ports clk_0]