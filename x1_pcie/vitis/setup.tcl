# run at linux command line 
#       xsct setup.tcl
#       vitis --classic --workspace ./workspace
#
file delete -force ./workspace

set hw ../implement/results/top.xsa
set proc "microblaze_0"

setws ./workspace


platform create -name "standalone_plat" -hw $hw -proc $proc -os standalone
#bsp config stdout "usb_uartlite"
#bsp config stdin  "usb_uartlite"

app create -name qspi_flash_test -platform standalone_plat -domain standalone_domain -template "Empty Application(C)"
file link -symbolic ./workspace/qspi_flash_test/src/test.c               ../../../src/qspi_flash_test/test.c
file link -symbolic ./workspace/qspi_flash_test/src/qspi_flash.h         ../../../src/qspi_flash_test/qspi_flash.h
file link -symbolic ./workspace/qspi_flash_test/src/qspi_flash.c         ../../../src/qspi_flash_test/qspi_flash.c
file link -symbolic ./workspace/qspi_flash_test/src/fpga.h               ../../../src/fpga.h

#app create -name production -platform standalone_plat -domain standalone_domain -template "Empty Application(C)"
#file link -symbolic ./workspace/production/src/test.c               ../../../src/production/test.c
#file link -symbolic ./workspace/production/src/fpga.h               ../../../src/fpga.h

app build all

