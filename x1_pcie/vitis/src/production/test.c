#include "xparameters.h"
#include "xil_printf.h"
#include "math.h"
#include "fpga.h"

int main(void)
{

	uint32_t* regptr = (uint32_t *)XPAR_M_AXI_BASEADDR;
	xil_printf("\n\rFPGA_ID = 0x%08x, FPGA_VERSION = 0x%08x\n\r", regptr[FPGA_ID], regptr[FPGA_VERSION]);

	uint32_t whilecount = 0;
	while(1) {

		xil_printf("%d: \n\r", whilecount);
		
		for (int i=0; i<10000000; i++); // wait
		
		whilecount++;
	}
	
	return(0);

}

