#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

#include "fpga.h"

// set_register.c
// sudo ./set_register <regnum(0..15)> <regval(decimal)>
// writes the regval to the register specified by renum.
int main(int argc,char** argv)
{
    int32_t regnum = atoi(argv[1]);
    int32_t regval = atoi(argv[2]);

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

    uint32_t *regptr = base_addr + FPGA_REG_OFFSET;

    regptr[regnum] = regval;

    munmap(base_addr,FPGA_SIZE);

    return 0;
}


