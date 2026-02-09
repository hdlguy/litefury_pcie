#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

#include "fpga.h"

// get_xadc.c

int main(int argc, char** argv)
{
    if (argc != 2) {
        printf("Usage: ./get_sysmon [arg]\n\t arg: 1 = temperature, 2 = VccInt, 3 = VccAUX\n");
        return 0;
    }

    // get pointers to the FPGA logic.
    char devstr[] = "/dev/xdma0_bypass";
    void* base_addr;
    int fd = open(devstr, O_RDWR|O_SYNC);
    if(fd < 0) {
        fprintf(stderr,"Can't open %s, you must be root!\n", devstr);
    } else {
        base_addr = mmap(0,FPGA_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
        if(base_addr == NULL) fprintf(stderr,"Can't mmap\n");
    }

    uint32_t *xadcptr = base_addr + XADC_OFFSET;

    //fprintf(stdout, "%08x\n", xadcptr[XADC_TEMP/4]);
    //fprintf(stdout, "%08x\n", xadcptr[XADC_VCCINT/4]);
    //fprintf(stdout, "%08x\n", xadcptr[XADC_VCCAUX/4]);
    //fprintf(stdout, "%08x\n", xadcptr[XADC_VBRAM/4]);

    uint32_t rval;

    rval = xadcptr[XADC_TEMP/4];
    float temp = rval*503.975/65536.0 - 273.15;
    //fprintf(stdout, "fpga temperature = %f C\n", temp); 

    rval = xadcptr[XADC_VCCINT/4];
    float vccint = rval*3.0/65536.0;
    //fprintf(stdout, "fpga VCCint = %f C\n", vccint); 

    rval = xadcptr[XADC_VCCAUX/4];
    float vccaux = rval*3.0/65536.0;
    //fprintf(stdout, "fpga VCCaux = %f C\n", vccaux); 

    rval = xadcptr[XADC_VBRAM/4];
    float vccbram = rval*3.0/65536.0;
    //fprintf(stdout, "fpga VCCbram = %f C\n", vccbram); 

    int select = atoi(argv[1]);
    if (select == 1) fprintf(stdout, "%3.2f\n", temp);
    if (select == 2) fprintf(stdout, "%2.3f\n", vccint);
    if (select == 3) fprintf(stdout, "%2.3f\n", vccaux);
    if (select == 4) fprintf(stdout, "%2.3f\n", vccbram);

    munmap(base_addr,FPGA_SIZE);

    return 0;
}


