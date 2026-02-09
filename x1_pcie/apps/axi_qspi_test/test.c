// This program just demonstrates polled access to the AXI QSPI interface accross PCIe.

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <time.h>
#include "fpga.h"

void spi_transfer(uint32_t* qspi_ptr, uint8_t* txbuf, uint8_t* rxbuf, int nx);
void print_qspi_regs(uint32_t* qspi_ptr);

int main(int argc,char** argv)
{
    //int nx;
    //uint8_t txbuf[512], rxbuf[512];

    char devstr[] = "/dev/xdma0_bypass";

    // get pointer to the FPGA logic.
    void* base_addr;
    int fd = open(devstr, O_RDWR|O_SYNC);
    if(fd < 0) {
        fprintf(stderr,"Can't open %s, you must be root!\n", devstr);
    } else {
        base_addr = mmap(0,FPGA_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
        if(base_addr == NULL) fprintf(stderr,"Can't mmap\n");
    }

    uint32_t *reg_ptr  = base_addr + FPGA_REG_OFFSET;
    printf("FPGA_ID = 0x%08x, FPGA_VERSION = 0x%08x\n", reg_ptr[FPGA_ID], reg_ptr[FPGA_VERSION]);

    // access some AXI QSPI registers
    uint32_t * qspi_ptr = base_addr + QSPI_OFFSET;

    // reset the AXI QSPI interface
    qspi_ptr[QSPI_SSR/4] = 0xff;
    qspi_ptr[QSPI_SRR/4] = 0x0000000a;

    // configure the AXI QSPI
    qspi_ptr[QSPI_CR/4] = QSPI_SPICR_MANUAL_SS | QSPI_SPICR_MASTER_INHIBIT | QSPI_SPICR_RX_FIFO_RESET | QSPI_SPICR_TX_FIFO_RESET | QSPI_SPICR_MASTER_ENABLE | QSPI_SPICR_SPI_ENABLE;
    qspi_ptr[QSPI_SSR/4] = 0xff;

    print_qspi_regs(qspi_ptr);

    munmap(base_addr,FPGA_SIZE);

    return 0;
}

void spi_transfer(uint32_t* qspi_ptr, uint8_t* txbuf, uint8_t* rxbuf, int nx){
    // 1. Disable the master transaction by asserting the master inhibit bit of SPICR (60h), and reset the RX and TX FIFOs through SPICR.  Example: write 0x1E6 to SPICR
    printf("asserting master inhibit\n");
    qspi_ptr[QSPI_CR/4] = QSPI_SPICR_MANUAL_SS | QSPI_SPICR_MASTER_INHIBIT | QSPI_SPICR_RX_FIFO_RESET | QSPI_SPICR_TX_FIFO_RESET | QSPI_SPICR_MASTER_ENABLE | QSPI_SPICR_SPI_ENABLE;

    // 2. Write data into DTR.
    printf("writing to DTR\n");
    for (int i=0; i<nx; i++) qspi_ptr[QSPI_DTR/4] = txbuf[i];
    //for (int i=0; i<nx; i++) { printf("%02x ", txbuf[i]); } printf("\n");

    // 3. Issue chip select by writing 0x00 to SSR(70h).
    printf("asserting chip select\n");
    qspi_ptr[QSPI_SSR/4] = 0x00;

    // 4. Enable master transaction by deasserting the CR master inhibit bit.
    printf("deasserting master inhibit\n");
    qspi_ptr[QSPI_CR/4] = QSPI_SPICR_MANUAL_SS | QSPI_SPICR_MASTER_ENABLE | QSPI_SPICR_SPI_ENABLE;

    printf("\nQSPI_SR = 0x%08x\n", qspi_ptr[QSPI_SR/4]);

    // wait for tx fifo empty
    printf("waiting for tx fifo empty\n");
    while (((qspi_ptr[QSPI_SR/4]) & 0x04) == 0);
    //usleep(10);

    printf("\nQSPI_SR = 0x%08x\n", qspi_ptr[QSPI_SR/4]);

    // 5. Deassert chip select by writing 0x01 to SPISSR.
    printf("deasserting chip select\n");
    qspi_ptr[QSPI_SSR/4] = 0xff;

    // 6. Disable master transaction by asserting the SPICR master inhibit bit.
    printf("asserting master inhibit\n");
    qspi_ptr[QSPI_CR/4] = QSPI_SPICR_MANUAL_SS | QSPI_SPICR_MASTER_INHIBIT | QSPI_SPICR_MASTER_ENABLE | QSPI_SPICR_SPI_ENABLE;

    // read the rxdata from SPIDRX
    printf("reading rxbuf\n");
    printf("\nQSPI_SR = 0x%08x\n", qspi_ptr[QSPI_SR/4]);
    int index = 0;
    while (((qspi_ptr[QSPI_SR/4]) & 0x01) == 0) {
        rxbuf[index] = (uint8_t)((qspi_ptr[QSPI_DRR/4]) & 0x00ff);
        index++;
    }
    printf("\nQSPI_SR = 0x%08x\n", qspi_ptr[QSPI_SR/4]);
    
}


void print_qspi_regs(uint32_t* qspi_ptr) {
    printf("QSPI_SRR = 0x%08x\n", qspi_ptr[QSPI_SRR/4]);
    printf("QSPI_CR = 0x%08x\n", qspi_ptr[QSPI_CR/4]);
    printf("QSPI_SR = 0x%08x\n", qspi_ptr[QSPI_SR/4]);
    printf("QSPI_DRR = 0x%08x\n", qspi_ptr[QSPI_DRR/4]);
    printf("QSPI_SSR = 0x%08x\n", qspi_ptr[QSPI_SSR/4]);
    printf("QSPI_TX_OCCUPANCY = 0x%08x\n", qspi_ptr[QSPI_TX_OCCUPANCY/4]);
    printf("QSPI_RX_OCCUPANCY = 0x%08x\n", qspi_ptr[QSPI_RX_OCCUPANCY/4]);
    printf("QSPI_DGIER = 0x%08x\n", qspi_ptr[QSPI_DGIER/4]);
    printf("QSPI_IPISR = 0x%08x\n", qspi_ptr[QSPI_IPISR/4]);
    printf("QSPI_IPEIR = 0x%08x\n", qspi_ptr[QSPI_IPEIR/4]);
}

/*
#define     QSPI_SRR                0x40    // 40h SRR Write N/A Software reset register
#define     QSPI_SPICR              0x60    // 60h SPICR R/W 0x180 SPI control register
#define     QSPI_SPISR              0x64    // 64h SPISR Read 0x0a5 SPI status register
#define     QSPI_DTR                0x68    // 68h SPI DTR Write 0x0 SPI data transmit register. A single register or a FIFO
#define     QSPI_DRR                0x6C    // 6Ch SPI DRR Read N/A(1) SPI data receive register. A single register or a FIFO
#define     QSPI_SPISSR             0x70    // 70h SPISSR R/W No slave is selected 0xFFFF SPI Slave select register
#define     QSPI_TX_OCCUPANCY       0x74    // 74h SPI Transmit FIFO Occupancy Register(2) Read 0x0 Transmit FIFO occupancy register
#define     QSPI_RX_OCCUPANCY       0x78    // 78h SPI Receive FIFO Occupancy Register(2) Read 0x0 Receive FIFO occupancy register
#define     QSPI_DGIER              0x1C    // 1Ch DGIER R/W 0x0 Device global interrupt enable register
#define     QSPI_IPISR              0x20    // 20h IPISR R/TOW(3) 0x0 IP interrupt status register
#define     QSPI_IPEIR              0x28    // 28h IPIER R/W 0x0 IP interrupt enable register
*/
