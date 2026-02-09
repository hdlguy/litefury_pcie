//
#define     FPGA_BASE_ADDRESS       0xa0000000
#define     FPGA_SIZE               0x00100000

#define     FPGA_REG_OFFSET         0x00000000

// register numbers
#define     FPGA_ID                 0
#define     FPGA_VERSION            1
#define     FPGA_LED                2 // [3:0] = PL LED value, read/write

#define     VINSTRU_PULSE_ENABLE    3 // [0] = pulse enable (rw), starts the pulse generator
#define     VINSTRU_CAPTURE_CONTROL 4 // [0] = capture run (rw), [4] = capture done (ro), [8] = reset (rw), 
#define     VINSTRU_PULSE_PERIOD    5 // [15:0] = period between pulses in samples (rw)
#define     VINSTRU_PULSE_WIDTH     6 // [15:0] = pulse width in samples (rw)
#define     VINSTRU_PULSE_AMPLITUDE 7 // [15:0] = pulse amplitide in counts (rw)
#define     VINSTRU_NOISE_AMPLITUDE 8 // [15:0] = noise amplitude (standard deviation) in counts (rw)


// Test Bram (rw)
#define     TEST_RAM_OFFSET         0x00010000
#define     TEST_RAM_SIZE           0x00001000 // 4KB

// Vinstru Bram that gets the capture output (rw)
#define     VINSTRU_RAM_OFFSET      0x00020000
#define     VINSTRU_RAM_SIZE        0x00004000 // 16KB = 4K 32-bit words

// QSPI Flash Bram for passing data to/from the Microblaze QSPI Flash controller.
#define     FLASH_RAM_OFFSET        0x00040000
#define     FLASH_RAM_SIZE          0x00001000 // 4K bytes

// XADC for temperature and voltage monitoring in the FPGA
#define     XADC_OFFSET             0x00030000
// XADC register offsets
#define     XADC_TEMP               0x200
#define     XADC_VCCINT             0x204
#define     XADC_VCCAUX             0x208
#define     XADC_VBRAM              0x218

// AXI QSPI Controller connected to configuration flash
#define     QSPI_OFFSET             0x00040000

#define     QSPI_SRR                0x40    // 40h SRR Write N/A Software reset register
#define     QSPI_CR                 0x60    // 60h SPICR R/W 0x180 SPI control register
#define     QSPI_SR                 0x64    // 64h SPISR Read 0x0a5 SPI status register
#define     QSPI_DTR                0x68    // 68h SPI DTR Write 0x0 SPI data transmit register. A single register or a FIFO
#define     QSPI_DRR                0x6C    // 6Ch SPI DRR Read N/A(1) SPI data receive register. A single register or a FIFO
#define     QSPI_SSR                0x70    // 70h SPISSR R/W No slave is selected 0xFFFF SPI Slave select register
#define     QSPI_TX_OCCUPANCY       0x74    // 74h SPI Transmit FIFO Occupancy Register(2) Read 0x0 Transmit FIFO occupancy register
#define     QSPI_RX_OCCUPANCY       0x78    // 78h SPI Receive FIFO Occupancy Register(2) Read 0x0 Receive FIFO occupancy register
#define     QSPI_DGIER              0x1C    // 1Ch DGIER R/W 0x0 Device global interrupt enable register
#define     QSPI_IPISR              0x20    // 20h IPISR R/TOW(3) 0x0 IP interrupt status register
#define     QSPI_IPEIR              0x28    // 28h IPIER R/W 0x0 IP interrupt enable register

// CR mask bits
#define     QSPI_SPICR_LOOPBACK       0x001
#define     QSPI_SPICR_SPI_ENABLE     0x002
#define     QSPI_SPICR_MASTER_ENABLE  0x004
#define     QSPI_SPICR_CPOL           0x008
#define     QSPI_SPICR_CPHA           0x010
#define     QSPI_SPICR_TX_FIFO_RESET  0x020
#define     QSPI_SPICR_RX_FIFO_RESET  0x040
#define     QSPI_SPICR_MANUAL_SS      0x080
#define     QSPI_SPICR_MASTER_INHIBIT 0x100
#define     QSPI_SPICR_LSB_FIRST      0x200

