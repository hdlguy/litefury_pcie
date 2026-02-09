
set_property CFGBVS VCCO        [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

create_clock -period  5.000 -name sysclk_p         -waveform {0.000 2.500} [get_ports {sysclk_p}]
create_clock -period 10.000 -name pcie_clkin_clk_p -waveform {0.000 5.000} [get_ports pcie_clkin_clk_p]

#set_max_delay -to   [get_clocks sysclk_p] -from [get_ports {pcie_reset}] -datapath_only  20.0
#set_min_delay -to   [get_clocks sysclk_p] -from [get_ports {pcie_reset}]  20.0
#set_max_delay -from [get_clocks sysclk_p] -to   [get_ports {ledn[*]}] -datapath_only  20.0
#set_max_delay -from [get_clocks userclk1] -to   [get_ports {qspi_*}] -datapath_only  20.0
#set_max_delay -to   [get_clocks userclk1] -from [get_ports {qspi_*}] -datapath_only  20.0
#set_min_delay -to   [get_clocks userclk1] -from [get_ports {qspi_*}]  20.0

#################

set_property IOSTANDARD LVDS_25     [get_ports sysclk_*]
set_property PACKAGE_PIN J19        [get_ports sysclk_p]
set_property PACKAGE_PIN H19        [get_ports sysclk_n]

set_property PACKAGE_PIN F6         [get_ports pcie_clkin_clk_p]
set_property PACKAGE_PIN E6         [get_ports pcie_clkin_clk_n]
set_property PACKAGE_PIN G1         [get_ports pcie_clkreq_l]
set_property IOSTANDARD LVCMOS33    [get_ports pcie_clkreq_l]
set_property PACKAGE_PIN J1         [get_ports pcie_reset]
set_property IOSTANDARD LVCMOS33    [get_ports pcie_reset]


set_property IOSTANDARD LVCMOS33 [get_ports {ledn[*]}]
set_property PACKAGE_PIN G3 [get_ports {ledn[0]}]
set_property PACKAGE_PIN H3 [get_ports {ledn[1]}]
set_property PACKAGE_PIN G4 [get_ports {ledn[2]}]
set_property PACKAGE_PIN H4 [get_ports {ledn[3]}]

#set_property IOSTANDARD LVCMOS33    [get_ports {qspi_io*_io}]
#set_property PACKAGE_PIN P22        [get_ports {qspi_io0_io}]
#set_property PACKAGE_PIN R22        [get_ports {qspi_io1_io}]
#set_property PACKAGE_PIN P21        [get_ports {qspi_io2_io}]
#set_property PACKAGE_PIN R21        [get_ports {qspi_io3_io}]
#set_property IOSTANDARD LVCMOS33    [get_ports {qspi_ss_io}]
#set_property PACKAGE_PIN T19        [get_ports {qspi_ss_io}]

set_property PACKAGE_PIN B10 [get_ports {pcie_mgt_rxp[0]}]
set_property PACKAGE_PIN B8 [get_ports {pcie_mgt_rxp[1]}]
set_property PACKAGE_PIN D9 [get_ports {pcie_mgt_rxp[3]}]
