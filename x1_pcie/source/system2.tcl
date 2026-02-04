
################################################################
# This is a generated script based on design: system2
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system2_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a100tfgg484-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name system2

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:axi_quad_spi:3.2\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:axi_hwicap:3.0\
xilinx.com:inline_hdl:ilconcat:1.0\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $dlmb_bram_if_cntlr


  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $ilmb_bram_if_cntlr


  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.use_bram_block {BRAM_Controller} \
  ] $lmb_bram


  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_1_dlmb [get_bd_intf_pins dlmb_v10/LMB_M] [get_bd_intf_pins DLMB]
  connect_bd_intf_net -intf_net microblaze_1_dlmb_bus [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_1_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_1_ilmb [get_bd_intf_pins ilmb_v10/LMB_M] [get_bd_intf_pins ILMB]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1  [get_bd_pins SYS_Rst] \
  [get_bd_pins dlmb_v10/SYS_Rst] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] \
  [get_bd_pins ilmb_v10/SYS_Rst] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]
  connect_bd_net -net microblaze_1_Clk  [get_bd_pins LMB_Clk] \
  [get_bd_pins dlmb_v10/LMB_Clk] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] \
  [get_bd_pins ilmb_v10/LMB_Clk] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set qspi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 qspi ]

  set startup [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_startup_io:startup_io_rtl:1.0 startup ]

  set flash_bram [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 flash_bram ]
  set_property -dict [ list \
   CONFIG.MASTER_TYPE {BRAM_CTRL} \
   ] $flash_bram

  set led [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led ]


  # Create ports
  set clkin [ create_bd_port -dir I -type clk -freq_hz 62500000 clkin ]
  set resetn [ create_bd_port -dir I -type rst resetn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $resetn

  # Create instance: rst_clk_wiz_0_100M, and set properties
  set rst_clk_wiz_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_0_100M ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0 ]
  set_property -dict [list \
    CONFIG.C_ADDR_TAG_BITS {0} \
    CONFIG.C_AREA_OPTIMIZED {1} \
    CONFIG.C_DCACHE_ADDR_TAG {0} \
    CONFIG.C_DEBUG_ENABLED {1} \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_D_LMB {1} \
    CONFIG.C_ENABLE_CONVERSION {0} \
    CONFIG.C_ILL_OPCODE_EXCEPTION {0} \
    CONFIG.C_I_LMB {1} \
    CONFIG.C_M_AXI_D_BUS_EXCEPTION {0} \
    CONFIG.C_PVR {0} \
    CONFIG.C_UNALIGNED_EXCEPTIONS {0} \
    CONFIG.C_USE_BARREL {0} \
    CONFIG.C_USE_DCACHE {0} \
    CONFIG.C_USE_DIV {0} \
    CONFIG.C_USE_HW_MUL {0} \
    CONFIG.C_USE_ICACHE {0} \
    CONFIG.C_USE_MSR_INSTR {0} \
    CONFIG.C_USE_PCMP_INSTR {0} \
    CONFIG.C_USE_REORDER_INSTR {0} \
    CONFIG.C_USE_STACK_PROTECTION {1} \
    CONFIG.G_TEMPLATE_LIST {1} \
    CONFIG.G_USE_EXCEPTIONS {0} \
  ] $microblaze_0


  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [list \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {1} \
  ] $microblaze_0_axi_periph


  # Create instance: axi_intc_1, and set properties
  set axi_intc_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_1 ]

  # Create instance: axi_quad_spi_1, and set properties
  set axi_quad_spi_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 axi_quad_spi_1 ]
  set_property -dict [list \
    CONFIG.C_SPI_MEMORY {3} \
    CONFIG.C_SPI_MODE {2} \
  ] $axi_quad_spi_1


  # Create instance: mdm_2, and set properties
  set mdm_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_2 ]
  set_property -dict [list \
    CONFIG.C_ADDR_SIZE {32} \
    CONFIG.C_MB_DBG_PORTS {1} \
    CONFIG.C_M_AXI_ADDR_WIDTH {32} \
    CONFIG.C_USE_UART {1} \
  ] $mdm_2


  # Create instance: axi_hwicap_0, and set properties
  set axi_hwicap_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_hwicap:3.0 axi_hwicap_0 ]

  # Create instance: ilconcat_0, and set properties
  set ilconcat_0 [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:1.0 ilconcat_0 ]
  set_property CONFIG.NUM_PORTS {3} $ilconcat_0


  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_0


  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_0_bram ]
  set_property CONFIG.Memory_Type {True_Dual_Port_RAM} $axi_bram_ctrl_0_bram


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {1} \
  ] $axi_gpio_0


  # Create interface connections
  connect_bd_intf_net -intf_net BRAM_PORTB_0_1 [get_bd_intf_ports flash_bram] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI] [get_bd_intf_pins microblaze_0/M_AXI_DP]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_intc_1_interrupt [get_bd_intf_pins axi_intc_1/interrupt] [get_bd_intf_pins microblaze_0/INTERRUPT]
  connect_bd_intf_net -intf_net axi_quad_spi_1_SPI_0 [get_bd_intf_ports qspi] [get_bd_intf_pins axi_quad_spi_1/SPI_0]
  connect_bd_intf_net -intf_net axi_quad_spi_1_STARTUP_IO [get_bd_intf_ports startup] [get_bd_intf_pins axi_quad_spi_1/STARTUP_IO]
  connect_bd_intf_net -intf_net mdm_2_MBDEBUG_0 [get_bd_intf_pins mdm_2/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph1_M00_AXI [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI] [get_bd_intf_pins axi_intc_1/s_axi]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph1_M01_AXI [get_bd_intf_pins mdm_2/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph1_M02_AXI [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI] [get_bd_intf_pins axi_quad_spi_1/AXI_LITE]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_1_axi_periph_M03_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_1_axi_periph_M04_AXI [get_bd_intf_pins axi_hwicap_0/S_AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_1_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_1_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]

  # Create port connections
  connect_bd_net -net axi_hwicap_0_ip2intc_irpt  [get_bd_pins axi_hwicap_0/ip2intc_irpt] \
  [get_bd_pins ilconcat_0/In2]
  connect_bd_net -net axi_quad_spi_1_eos  [get_bd_pins axi_quad_spi_1/eos] \
  [get_bd_pins axi_hwicap_0/eos_in]
  connect_bd_net -net axi_quad_spi_1_ip2intc_irpt  [get_bd_pins axi_quad_spi_1/ip2intc_irpt] \
  [get_bd_pins ilconcat_0/In1]
  connect_bd_net -net ilconcat_0_dout  [get_bd_pins ilconcat_0/dout] \
  [get_bd_pins axi_intc_1/intr]
  connect_bd_net -net mdm_2_Debug_SYS_Rst  [get_bd_pins mdm_2/Debug_SYS_Rst] \
  [get_bd_pins rst_clk_wiz_0_100M/mb_debug_sys_rst]
  connect_bd_net -net mdm_2_Interrupt  [get_bd_pins mdm_2/Interrupt] \
  [get_bd_pins ilconcat_0/In0]
  connect_bd_net -net microblaze_1_Clk  [get_bd_ports clkin] \
  [get_bd_pins rst_clk_wiz_0_100M/slowest_sync_clk] \
  [get_bd_pins microblaze_0/Clk] \
  [get_bd_pins microblaze_0_local_memory/LMB_Clk] \
  [get_bd_pins axi_intc_1/s_axi_aclk] \
  [get_bd_pins microblaze_0_axi_periph/ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S00_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M02_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M01_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M00_ACLK] \
  [get_bd_pins axi_quad_spi_1/ext_spi_clk] \
  [get_bd_pins axi_quad_spi_1/s_axi_aclk] \
  [get_bd_pins mdm_2/S_AXI_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M03_ACLK] \
  [get_bd_pins axi_hwicap_0/s_axi_aclk] \
  [get_bd_pins axi_hwicap_0/icap_clk] \
  [get_bd_pins microblaze_0_axi_periph/M04_ACLK] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins microblaze_0_axi_periph/M05_ACLK]
  connect_bd_net -net reset_1  [get_bd_ports resetn] \
  [get_bd_pins rst_clk_wiz_0_100M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_0_100M_bus_struct_reset  [get_bd_pins rst_clk_wiz_0_100M/bus_struct_reset] \
  [get_bd_pins microblaze_0_local_memory/SYS_Rst]
  connect_bd_net -net rst_clk_wiz_0_100M_mb_reset  [get_bd_pins rst_clk_wiz_0_100M/mb_reset] \
  [get_bd_pins microblaze_0/Reset]
  connect_bd_net -net rst_clk_wiz_0_100M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_0_100M/peripheral_aresetn] \
  [get_bd_pins axi_intc_1/s_axi_aresetn] \
  [get_bd_pins microblaze_0_axi_periph/ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] \
  [get_bd_pins axi_quad_spi_1/s_axi_aresetn] \
  [get_bd_pins mdm_2/S_AXI_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] \
  [get_bd_pins axi_hwicap_0/s_axi_aresetn] \
  [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins microblaze_0_axi_periph/M05_ARESETN]

  # Create address segments
  assign_bd_address -offset 0xC0000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_hwicap_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_intc_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_quad_spi_1/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x41400000 -range 0x00001000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs mdm_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


