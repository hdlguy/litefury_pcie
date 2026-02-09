#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

#include "fpga.h"

// capture_waveform.c
// uses the capture control logic of the vinstru to collect virtual instrument data.
// The pulse generator must be running in advance of this command to trigger the capture.
// usage: sudo ./capture_waveform
// The results are returned in the vinstru block ram to be read by the read_vinstru_bram command.
int main(int argc,char** argv)
{
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

    regptr[VINSTRU_CAPTURE_CONTROL] = (1<<8); // reset capture logic
    regptr[VINSTRU_CAPTURE_CONTROL] = 0; 

    regptr[VINSTRU_CAPTURE_CONTROL] = 0; // clear capture run
    //printf("waiting for done to clear\n");
    while((0x10 & regptr[VINSTRU_CAPTURE_CONTROL]) != 0); // wait for capture done to clear

    regptr[VINSTRU_CAPTURE_CONTROL] = 1; // set capture run
    //printf("waiting for done to assert\n");
    while((0x10 & regptr[VINSTRU_CAPTURE_CONTROL]) != 0x10); // wait for capture done to assert

    regptr[VINSTRU_CAPTURE_CONTROL] = 0; // clear capture run
    //printf("waiting for done to clear\n");
    while((0x10 & regptr[VINSTRU_CAPTURE_CONTROL]) != 0); // wait for capture done to clear

    munmap(base_addr,FPGA_SIZE);

    return 0;
}

