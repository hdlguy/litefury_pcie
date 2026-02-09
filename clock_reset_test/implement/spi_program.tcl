# Script to burn configuration flash
# In Linux:
#   vivado -mode batch -source spi_program.tcl
# In windows use xtcl shell
#   source spi_program.tcl
write_cfgmem -force -format MCS -size 128 -interface SPIx4 -loadbit "up 0x0 ./results/top.bit" -verbose ./results/top.mcs

disconnect_hw_server -quiet
open_hw_manager
connect_hw_server
open_hw_target 
current_hw_device [get_hw_devices]
refresh_hw_device [current_hw_device]

create_hw_bitstream -hw_device [get_hw_devices] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]];

create_hw_cfgmem -hw_device [current_hw_device] -mem_dev [lindex [get_cfgmem_parts {s25fl256sxxxxxx0-spi-x1_x2_x4}] 0]

set_property PROGRAM.ADDRESS_RANGE  {use_file}              [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.FILES [list "./results/top.mcs" ]      [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.PRM_FILE {}                            [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none}     [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.BLANK_CHECK    0                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.ERASE          1                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.CFG_PROGRAM    1                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.VERIFY         1                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.CHECKSUM       0                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]

program_hw_devices  [current_hw_device]; 
refresh_hw_device   [current_hw_device];

set status [catch {program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]}]

if {$status != 0} {
    create_hw_cfgmem -hw_device [current_hw_device] -mem_dev [lindex [get_cfgmem_parts {mt25ql128-spi-x1_x2_x4}] 0]
    set_property PROGRAM.ADDRESS_RANGE  {use_file}              [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.FILES [list "./results/top.mcs" ]      [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.PRM_FILE {}                            [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none}     [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.BLANK_CHECK    0                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.ERASE          1                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.CFG_PROGRAM    1                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.VERIFY         1                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
    set_property PROGRAM.CHECKSUM       0                       [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]

    program_hw_devices  [current_hw_device]; 
    refresh_hw_device   [current_hw_device];

    program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [current_hw_device]]
}

boot_hw_device  [current_hw_device]
close_hw_manager


