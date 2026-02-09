#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

#include "fpga.h"

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
    printf("FPGA_BASE_ADDRESS = 0x%10lx, virtual base_addr = %p\n", (uint64_t)FPGA_BASE_ADDRESS, base_addr);
    uint32_t *reg_ptr  = base_addr + FPGA_REG_OFFSET;
    uint32_t* bram_ptr;
    printf("FPGA_ID = 0x%08x, FPGA_VERSION = 0x%08x\n", reg_ptr[FPGA_ID], reg_ptr[FPGA_VERSION]);

    int errors;

    // Test the scratch bram.
    bram_ptr = base_addr + TEST_RAM_OFFSET;
    errors = ram_test(bram_ptr, TEST_RAM_SIZE);
    printf("TEST_RAM: bram_ptr = %p, errors = %d\n", bram_ptr, errors);

    // Test the VINSTRU bram.
    bram_ptr = base_addr + VINSTRU_RAM_OFFSET;
    errors = ram_test(bram_ptr, VINSTRU_RAM_SIZE);
    printf("VINSTRU_RAM: bram_ptr = %p, errors = %d\n", bram_ptr, errors);

    // Test the VINSTRU bram.
    bram_ptr = base_addr + FLASH_RAM_OFFSET;
    errors = ram_test(bram_ptr, FLASH_RAM_SIZE);
    printf("FLASH_RAM: bram_ptr = %p, errors = %d\n", bram_ptr, errors);

    reg_ptr[FPGA_LED] += 2;

    munmap(base_addr, FPGA_SIZE);

    return 0;
}

int ram_test(uint32_t* bram_ptr, uint32_t size)
{
    uint32_t* write_data;
    uint32_t* read_data;

    // create test data.
    write_data = malloc(size);
    read_data  = malloc(size);
    for (int i=0; i<size/4; i++) write_data[i] = rand();

    // write bram
    for (int i=0; i<size/4; i++) bram_ptr[i] = write_data[i];

    // read bram
    for (int i=0; i<size/4; i++) read_data[i] = bram_ptr[i];

    // check bram results
    int errors = 0;
    for (int i=0; i<TEST_RAM_SIZE/4; i++) {
        if (read_data[i] != write_data[i]) errors++;
    }

    free(write_data);
    free(read_data);

    return(errors);
}
