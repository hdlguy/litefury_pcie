#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

#include "fpga.h"

// set_pulse_params.c
// sets the pulse parameters period, width, pulse amplitude and noise amplitude.
// usage: sudo ./set_pulse_params <period> <width> <pulse amplitude> <noise amplitude>
// Period and width are in units of samples. Amplitude is in units of counts.
// Period and with can be 0 to 65535. Amplitude is on the range -32768 to +32767.
int main(int argc,char** argv)
{
    uint32_t pulse_period = atoi(argv[1]);
    uint32_t pulse_width = atoi(argv[2]);
    int32_t pulse_amplitude = atoi(argv[3]);
    uint32_t noise_amplitude = atoi(argv[4]);

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

    regptr[VINSTRU_PULSE_PERIOD] = pulse_period;
    regptr[VINSTRU_PULSE_WIDTH] = pulse_width;
    regptr[VINSTRU_PULSE_AMPLITUDE] = pulse_amplitude;
    regptr[VINSTRU_NOISE_AMPLITUDE] = noise_amplitude;

    munmap(base_addr,FPGA_SIZE);

    return 0;
}


//#define     VINSTRU_PULSE_ENABLE    4
//#define     VINSTRU_PULSE_PERIOD    5
//#define     VINSTRU_PULSE_WIDTH     6
//#define     VINSTRU_PULSE_AMPLITUDE 7
//#define     VINSTRU_NOISE_AMPLITUDE 8
