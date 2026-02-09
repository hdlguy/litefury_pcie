#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

#include "fpga.h"
#include "flash_control.h"

int ram_test(uint32_t* bram_ptr, uint32_t size);

int main(int argc,char** argv)
{
    char devstr[] = "/dev/xdma0_bypass";

    // get pointers to the FPGA logic.
    void* base_addr;
    int fd = open(devstr, O_RDWR|O_SYNC);
    if(fd < 0) {
        fprintf(stderr,"Can't open %s, you must be root!\n", devstr);
    } else {
        base_addr = mmap(0,FPGA_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
        if(base_addr == NULL) fprintf(stderr,"Can't mmap\n");
    }
    //printf("FPGA_BASE_ADDRESS = 0x%10lx, virtual base_addr = %p\n", (uint64_t)FPGA_BASE_ADDRESS, base_addr);
    uint32_t *reg_ptr  = base_addr + FPGA_REG_OFFSET;
    printf("FPGA_ID = 0x%08x, FPGA_VERSION = 0x%08x\n", reg_ptr[FPGA_ID], reg_ptr[FPGA_VERSION]);

    reg_ptr[FPGA_LED] += 2;

    munmap(base_addr, FPGA_SIZE);

    return 0;
}

