
create_clock -period 10.000 -name pcie_clkin_clk_p -waveform {0.000 5.000} [get_ports {pcie_clkin_clk_p}]
set_max_delay -from [get_clocks sysclk_p] -to [get_ports {ledn[*]}] -datapath_only  20.0

#################


set_property PACKAGE_PIN F6     [get_ports pcie_clkin_clk_p]
set_property PACKAGE_PIN E6     [get_ports pcie_clkin_clk_n]
set_property PACKAGE_PIN G1         [get_ports pcie_clkreq_l]
set_property IOSTANDARD LVCMOS33    [get_ports pcie_clkreq_l]
set_property PACKAGE_PIN J1         [get_ports pcie_reset]
set_property IOSTANDARD LVCMOS33    [get_ports pcie_reset]

set_property IOSTANDARD LVCMOS33 [get_ports {ledn[*]}]
set_property PACKAGE_PIN G3 [get_ports {ledn[0]}]
set_property PACKAGE_PIN H3 [get_ports {ledn[1]}]
set_property PACKAGE_PIN G4 [get_ports {ledn[2]}]
set_property PACKAGE_PIN H4 [get_ports {ledn[3]}]



