// This program demonstrates access to the QSPI configuration flash.
// It is derived from the Xilinx Vitis example code for Micron QSPI flash access.
// Code has been added to read the JEDIC ID of the part and adjust the 
// number of dummy bytes on read to make it work for Micron, Spansion and ISSI flash.
//
#include "xparameters.h"
#include "xspi.h"
#include "xil_exception.h"
#include "xintc.h"
#include <xil_printf.h>
#include <stdlib.h>
#include "fpga.h"

#define SPI_DEVICE_ID	XPAR_SPI_0_DEVICE_ID
#define INTC_DEVICE_ID	XPAR_INTC_0_DEVICE_ID
#define SPI_INTR_ID		XPAR_INTC_0_SPI_0_VEC_ID

#define INTC		    static XIntc
#define INTC_HANDLER	XIntc_InterruptHandler

#define SPI_SELECT 			0x01

#define COMMAND_READ_JEDIC_ID	0x9F // read jedic ID
#define COMMAND_PAGE_PROGRAM	0x02 /* Page Program command */
#define COMMAND_QUAD_WRITE		0x32 /* Quad Input Fast Program */
#define COMMAND_RANDOM_READ		0x03 /* Random read command */
#define COMMAND_DUAL_READ		0x3B /* Dual Output Fast Read */
#define COMMAND_DUAL_IO_READ	0xBB /* Dual IO Fast Read */
#define COMMAND_QUAD_READ		0x6B /* Quad Output Fast Read */
#define COMMAND_QUAD_IO_READ	0xEB /* Quad IO Fast Read */
#define	COMMAND_WRITE_ENABLE	0x06 /* Write Enable command */
#define COMMAND_SECTOR_ERASE	0xD8 /* Sector Erase command (64KB) */
#define COMMAND_BULK_ERASE		0xC7 /* Bulk Erase command */
#define COMMAND_STATUSREG_READ	0x05 /* Status read command */

#define READ_WRITE_EXTRA_BYTES	4 /* Read/Write extra bytes */
#define	WRITE_ENABLE_BYTES		1 /* Write Enable bytes */
#define SECTOR_ERASE_BYTES		4 /* Sector erase extra bytes */
#define BULK_ERASE_BYTES		1 /* Bulk erase extra bytes */
#define STATUS_READ_BYTES		2 /* Status read bytes count */
#define STATUS_WRITE_BYTES		2 /* Status write bytes count */

#define FLASH_SR_IS_READY_MASK		0x01 /* Ready mask */

#define PAGE_SIZE			256	// fixed by flash chip
#define IMAGE_SIZE			0x400000
#define NUM_PAGES			(IMAGE_SIZE/PAGE_SIZE)
#define SECTOR_SIZE			0x10000
#define NUM_SECTORS			(IMAGE_SIZE/SECTOR_SIZE)

#define FLASH_TEST_ADDRESS		0x400000

#define BYTE1				0 /* Byte 1 position */
#define BYTE2				1 /* Byte 2 position */
#define BYTE3				2 /* Byte 3 position */
#define BYTE4				3 /* Byte 4 position */
#define BYTE5				4 /* Byte 5 position */
#define BYTE6				5 /* Byte 6 position */
#define BYTE7				6 /* Byte 7 position */
#define BYTE8				7 /* Byte 8 position */

#define DUAL_READ_DUMMY_BYTES		2
#define QUAD_READ_DUMMY_BYTES		4

int SpiReadID(XSpi *SpiPtr, int n);
int SpiFlashWriteEnable(XSpi *SpiPtr);
int SpiFlashWrite(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 WriteCmd);
int SpiFlashRead(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 ReadCmd, u32 dummy_bytes);
int SpiFlashBulkErase(XSpi *SpiPtr);
int SpiFlashSectorErase(XSpi *SpiPtr, u32 Addr);
int SpiFlashGetStatus(XSpi *SpiPtr);
int SpiFlashQuadEnable(XSpi *SpiPtr);
int SpiFlashEnableHPM(XSpi *SpiPtr);
static int SpiFlashWaitForFlashReady(void);
void SpiHandler(void *CallBackRef, u32 StatusEvent, unsigned int ByteCount);
static int SetupInterruptSystem(XSpi *SpiPtr);



static XSpi Spi;
INTC InterruptController;

volatile static int TransferInProgress;

static int ErrorCount;

static u8 ReadBuffer[PAGE_SIZE + READ_WRITE_EXTRA_BYTES + 4];
static u8 WriteBuffer[PAGE_SIZE + READ_WRITE_EXTRA_BYTES];

int main(void)
{
	int Status;
	u32 Index;
	u32 Address;
	XSpi_Config *ConfigPtr;	/* Pointer to Configuration data */

	/////////////////////// Setup ///////////////////////////////

	// Initialize the SPI driver so that it's ready to use, specify the device ID that is generated in xparameters.h.
	ConfigPtr = XSpi_LookupConfig(SPI_DEVICE_ID);
	if (ConfigPtr == NULL) {
		return XST_DEVICE_NOT_FOUND;
	}
	Status = XSpi_CfgInitialize(&Spi, ConfigPtr, ConfigPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Connect the SPI driver to the interrupt subsystem such that interrupts can occur. This function is application specific.
	Status = SetupInterruptSystem(&Spi);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Setup the handler for the SPI that will be called from the interrupt context when an SPI status occurs, specify a pointer to the SPI driver instance as the callback reference so the handler is able to access the instance data.
	XSpi_SetStatusHandler(&Spi, &Spi, (XSpi_StatusHandler)SpiHandler);

	/* Set the SPI device as a master and in manual slave select mode such
	 * that the slave select signal does not toggle for every byte of a
	 * transfer, this must be done before the slave select is set. */
	Status = XSpi_SetOptions(&Spi, XSP_MASTER_OPTION | XSP_MANUAL_SSELECT_OPTION);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Select the quad flash device on the SPI bus, so that it can be read and written using the SPI bus.
	Status = XSpi_SetSlaveSelect(&Spi, SPI_SELECT);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Start the SPI driver so that interrupts and the device are enabled.
	XSpi_Start(&Spi);

	// Specify address in the Quad Serial Flash for the Erase/Write/Read operations.
	Address = FLASH_TEST_ADDRESS;
	
	uint32_t* regptr = (uint32_t *)REG_BASEADDR;

	xil_printf("\r\n**** qspi_flash_test ****\r\n");
	xil_printf("FPGA_ID = 0x%08x, FPGA_VERSION = 0x%08x\r\n", regptr[FPGA_VERSION], regptr[FPGA_VERSION]);

	///////////////////////// Read ID /////////////////////

	xil_printf("** ID Bytes\r\n");

	int num_id_bytes = 24;

	/* Clear the read Buffer. */
	for (Index = 0; Index < num_id_bytes; Index++) ReadBuffer[Index] = 0x0;

	Status = SpiReadID(&Spi, num_id_bytes);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	for (int i=0; i<num_id_bytes; i++) { xil_printf("%02x ", ReadBuffer[i]); } xil_printf("\r\n");
	u32 flashtype = 0;
    if (ReadBuffer[1] == 0x20) { xil_printf("flash = Micron\r\n"); flashtype=1; }
    if (ReadBuffer[1] == 0x01) { xil_printf("flash = Spansion\r\n"); flashtype=2; }
    if (ReadBuffer[1] == 0x9D) { xil_printf("flash = ISSI\r\n"); flashtype=3; }
    u32 quad_io_read_dummy_bytes;
    switch (flashtype) {
      case 1: quad_io_read_dummy_bytes=5; break;
      case 2: quad_io_read_dummy_bytes=3; break;
      case 3: quad_io_read_dummy_bytes=5; break;
      default: quad_io_read_dummy_bytes=5; break;
    }

	////////////////////////// Erase ///////////////////////

	xil_printf("**** Erase ****\r\n");

	for (int i=0; i<NUM_SECTORS; i++) {

		xil_printf("Sector %d/%d\r", i+1, NUM_SECTORS);
		regptr[LED_CONTROL] = i/4;

		Address = FLASH_TEST_ADDRESS + i * SECTOR_SIZE;

		// Perform the Write Enable operation.
		Status = SpiFlashWriteEnable(&Spi);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		/* Perform the Sector Erase operation. */
		Status = SpiFlashSectorErase(&Spi, Address);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

	}
	xil_printf("Sector %d/%d\r\n", NUM_SECTORS, NUM_SECTORS);
	
	/////////// Blank Check ///////////////////
	
	xil_printf("**** Blank Check ****\r\n");

	for (int i=0; i<NUM_PAGES; i++){

		if ((i%1024)==0) {
			xil_printf("Page %d/%d\r", i+1, NUM_PAGES);
			regptr[LED_CONTROL] = i/1024;
		}

		Address = FLASH_TEST_ADDRESS + i * PAGE_SIZE;

		/* Wait while the Flash is busy. */
		Status = SpiFlashWaitForFlashReady();
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		/* Clear the read Buffer. */
		for (Index = 0; Index < PAGE_SIZE + READ_WRITE_EXTRA_BYTES + quad_io_read_dummy_bytes; Index++) {
			ReadBuffer[Index] = 0x0;
		}

		/* Read the data from the Page using Quad IO Fast Read command. */
		Status = SpiFlashRead(&Spi, Address, PAGE_SIZE, COMMAND_QUAD_IO_READ, quad_io_read_dummy_bytes);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		// check that page is erased
		u8 rval;
		for (Index = 0; Index < PAGE_SIZE; Index++) {
			rval = ReadBuffer[Index + READ_WRITE_EXTRA_BYTES + quad_io_read_dummy_bytes];
			if (rval != 0xff) {
				xil_printf("error: %d 0x%02x  \r\n", Index, rval);
				return XST_FAILURE;
			}
		}

	}
	xil_printf("Page %d/%d\r\n", NUM_PAGES, NUM_PAGES);
	

	///////////////////////// Write //////////////////////////////

	xil_printf("**** Write ****\r\n");

	for (int i=0; i<NUM_PAGES; i++){

		if ((i%1024)==0) {
			xil_printf("Page %d/%d\r", i+1, NUM_PAGES);
			regptr[LED_CONTROL] = i/1024;
		}

		Address = FLASH_TEST_ADDRESS + i * PAGE_SIZE;

		// Fill WriteBuffer
		srand(Address);
		for (int j=4; j<(PAGE_SIZE+READ_WRITE_EXTRA_BYTES); j++) {
			WriteBuffer[j] = (u8)rand();
		}

		// Enable writes
		Status = SpiFlashWriteEnable(&Spi);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		// Write the data using Quad Fast Write command.
		Status = SpiFlashWrite(&Spi, Address, PAGE_SIZE, COMMAND_QUAD_WRITE);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

	}
	xil_printf("Page %d/%d\r\n", NUM_PAGES, NUM_PAGES);


	//////////////////////////// read and check///////////////////////////

	xil_printf("** Verify\r\n");

	for (int i=0; i<NUM_PAGES; i++){

		if ((i%1024)==0) {
			xil_printf("Page %d/%d\r", i+1, NUM_PAGES);
			regptr[LED_CONTROL] = i/1024;
		}

		Address = FLASH_TEST_ADDRESS + i * PAGE_SIZE;

		/* Wait while the Flash is busy. */
		Status = SpiFlashWaitForFlashReady();
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		/* Clear the read Buffer. */
		//for (Index = 0; Index < PAGE_SIZE + READ_WRITE_EXTRA_BYTES + QUAD_IO_READ_DUMMY_BYTES; Index++) {
		for (Index = 0; Index < PAGE_SIZE + READ_WRITE_EXTRA_BYTES + quad_io_read_dummy_bytes; Index++) {
			ReadBuffer[Index] = 0x0;
		}

		/* Read the data from the Page using Quad IO Fast Read command. */
		Status = SpiFlashRead(&Spi, Address, PAGE_SIZE, COMMAND_QUAD_IO_READ, quad_io_read_dummy_bytes);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		// Fill WriteBuffer
		srand(Address);
		for (int j=4; j<(PAGE_SIZE+READ_WRITE_EXTRA_BYTES); j++) {
			WriteBuffer[j] = (u8)rand();
		}
		
		/* Compare the data read against the data written. */
		u8 wval, rval;
		uint32_t errors = 0;
		for (Index = 0; Index < PAGE_SIZE; Index++) {
			//rval = ReadBuffer[Index + READ_WRITE_EXTRA_BYTES + QUAD_IO_READ_DUMMY_BYTES];
			rval = ReadBuffer[Index + READ_WRITE_EXTRA_BYTES + quad_io_read_dummy_bytes];
			wval = WriteBuffer[Index + READ_WRITE_EXTRA_BYTES];
			if (rval != wval) {
				errors ++;
				if (errors < 20) xil_printf("error: %d 0x%02x  0x%02x\r\n", Index, rval, wval);
			}
		}
		if (errors != 0) return XST_FAILURE;

	}
	xil_printf("Page %d/%d\r\n", NUM_PAGES, NUM_PAGES);


	xil_printf("********** Success! ***********\r\n");

	while(1);

	return XST_SUCCESS;
}



int SpiFlashWriteEnable(XSpi *SpiPtr)
{
	int Status;

	/* Wait while the Flash is busy. */
	Status = SpiFlashWaitForFlashReady();
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Prepare the WriteBuffer.
	WriteBuffer[BYTE1] = COMMAND_WRITE_ENABLE;

	// Initiate the Transfer.
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, WRITE_ENABLE_BYTES);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	// Wait until the transfer is complete and check if there are any errors in the transaction.
	while (TransferInProgress);
	if (ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


/* This function writes the data to the specified locations in the Numonyx Serial Flash memory.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
* @param	Addr is the address in the Buffer, where to write the data.
* @param	ByteCount is the number of bytes to be written.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		None */
int SpiFlashWrite(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 WriteCmd)
{
	int Status;

	Status = SpiFlashWaitForFlashReady();
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Prepare the WriteBuffer. */
	WriteBuffer[BYTE1] = WriteCmd;
	WriteBuffer[BYTE2] = (u8) (Addr >> 16);
	WriteBuffer[BYTE3] = (u8) (Addr >> 8);
	WriteBuffer[BYTE4] = (u8) Addr;


//	/* Fill in the TEST data that is to be written into the Numonyx Serial Flash device. */
//	for (u32 Index = 4; Index < ByteCount + READ_WRITE_EXTRA_BYTES; Index++) {
//		WriteBuffer[Index] = (u8)((Index - 4)%64 +32 );
//	}

	/* Initiate the Transfer. */
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, (ByteCount + READ_WRITE_EXTRA_BYTES));
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	 // Wait till the Transfer is complete and check if there are any errors in the transaction.
	while (TransferInProgress);
	if (ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


int SpiReadID(XSpi *SpiPtr, int n)
{
	int Status;

	Status = SpiFlashWaitForFlashReady();
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	WriteBuffer[BYTE1] = COMMAND_READ_JEDIC_ID;

	TransferInProgress = TRUE;
	Status = XSpi_Transfer( SpiPtr, WriteBuffer, ReadBuffer, n);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	while (TransferInProgress);
	if (ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


/**
*
* This function reads the data from the Numonyx Serial Flash Memory
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
* @param	Addr is the starting address in the Flash Memory from which the data is to be read.
* @param	ByteCount is the number of bytes to be read.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		None
*/
int SpiFlashRead(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 ReadCmd, u32 dummy_bytes)
{
	int Status;

	/* Wait while the Flash is busy. */
	Status = SpiFlashWaitForFlashReady();
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Prepare the WriteBuffer.
	 */
	WriteBuffer[BYTE1] = ReadCmd;
	WriteBuffer[BYTE2] = (u8) (Addr >> 16);
	WriteBuffer[BYTE3] = (u8) (Addr >> 8);
	WriteBuffer[BYTE4] = (u8) Addr;

	if (ReadCmd == COMMAND_DUAL_READ) {
		ByteCount += DUAL_READ_DUMMY_BYTES;
	} else if (ReadCmd == COMMAND_DUAL_IO_READ) {
		ByteCount += DUAL_READ_DUMMY_BYTES;
	} else if (ReadCmd == COMMAND_QUAD_IO_READ) {
		//ByteCount += QUAD_IO_READ_DUMMY_BYTES;
		ByteCount += dummy_bytes;
	} else if (ReadCmd == COMMAND_QUAD_READ) {
		ByteCount += QUAD_READ_DUMMY_BYTES;
	}

	/*
	 * Initiate the Transfer.
	 */
	TransferInProgress = TRUE;
	Status = XSpi_Transfer( SpiPtr, WriteBuffer, ReadBuffer, (ByteCount + READ_WRITE_EXTRA_BYTES));
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait till the Transfer is complete and check if there are any errors
	 * in the transaction.
	 */
	while (TransferInProgress);
	if (ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


/* This function erases the entire contents of the Numonyx Serial Flash device.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		The erased bytes will read as 0xFF. */
int SpiFlashBulkErase(XSpi *SpiPtr)
{
	int Status;

	/* Wait while the Flash is busy. */
	Status = SpiFlashWaitForFlashReady();
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Prepare the WriteBuffer. */
	WriteBuffer[BYTE1] = COMMAND_BULK_ERASE;

	/* Initiate the Transfer. */
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, BULK_ERASE_BYTES);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Wait until the Transfer is complete and check if there are any errors in the transaction. */
	while (TransferInProgress);
	if (ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/* 
* This function erases the contents of the specified Sector in the Numonyx Serial Flash device.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
* @param	Addr is the address within a sector of the Buffer, which is to be erased.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		The erased bytes will be read back as 0xFF. */
int SpiFlashSectorErase(XSpi *SpiPtr, u32 Addr)
{
	int Status;

	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady();
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Prepare the WriteBuffer.
	WriteBuffer[BYTE1] = COMMAND_SECTOR_ERASE;
	WriteBuffer[BYTE2] = (u8) (Addr >> 16);
	WriteBuffer[BYTE3] = (u8) (Addr >> 8);
	WriteBuffer[BYTE4] = (u8) (Addr);

	/*
	 * Initiate the Transfer.
	 */
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, SECTOR_ERASE_BYTES);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Wait till the Transfer is complete and check if there are any errors in the transaction.. */
	while (TransferInProgress);
	if (ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function reads the Status register of the Numonyx Flash.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		The status register content is stored at the second byte
*		pointed by the ReadBuffer.
*
******************************************************************************/
int SpiFlashGetStatus(XSpi *SpiPtr)
{
	int Status;

	/*
	 * Prepare the Write Buffer.
	 */
	WriteBuffer[BYTE1] = COMMAND_STATUSREG_READ;

	/*
	 * Initiate the Transfer.
	 */
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, ReadBuffer, STATUS_READ_BYTES);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait till the Transfer is complete and check if there are any errors
	 * in the transaction..
	 */
	while (TransferInProgress);
	if (ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}



/*****************************************************************************/
/**
*
* This function waits till the Numonyx serial Flash is ready to accept next
* command.
*
* @param	None
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		This function reads the status register of the Buffer and waits
*.		till the WIP bit of the status register becomes 0.
*
******************************************************************************/
int SpiFlashWaitForFlashReady(void)
{
	int Status;
	u8 StatusReg;

	while (1) {

		/*
		 * Get the Status Register. The status register content is
		 * stored at the second byte pointed by the ReadBuffer.
		 */
		Status = SpiFlashGetStatus(&Spi);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		/*
		 * Check if the flash is ready to accept the next command.
		 * If so break.
		 */
		StatusReg = ReadBuffer[1];
		if ((StatusReg & FLASH_SR_IS_READY_MASK) == 0) {
			break;
		}
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function is the handler which performs processing for the SPI driver.
* It is called from an interrupt context such that the amount of processing
* performed should be minimized. It is called when a transfer of SPI data
* completes or an error occurs.
*
* This handler provides an example of how to handle SPI interrupts and
* is application specific.
*
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
* @param	StatusEvent is the event that just occurred.
* @param	ByteCount is the number of bytes transferred up until the event
*		occurred.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void SpiHandler(void *CallBackRef, u32 StatusEvent, unsigned int ByteCount)
{
	/*
	 * Indicate the transfer on the SPI bus is no longer in progress
	 * regardless of the status event.
	 */
	TransferInProgress = FALSE;

	/*
	 * If the event was not transfer done, then track it as an error.
	 */
	if (StatusEvent != XST_SPI_TRANSFER_DONE) {
		ErrorCount++;
	}
}

/*****************************************************************************/
/**
*
* This function setups the interrupt system such that interrupts can occur
* for the Spi device. This function is application specific since the actual
* system may or may not have an interrupt controller. The Spi device could be
* directly connected to a processor without an interrupt controller.  The
* user should modify this function to fit the application.
*
* @param	SpiPtr is a pointer to the instance of the Spi device.
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None
*
******************************************************************************/

static int SetupInterruptSystem(XSpi *SpiPtr)
{

	int Status;

	/*
	 * Initialize the interrupt controller driver so that
	 * it's ready to use, specify the device ID that is generated in
	 * xparameters.h
	 */
	Status = XIntc_Initialize(&InterruptController, INTC_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect a device driver handler that will be called when an
	 * interrupt for the device occurs, the device driver handler
	 * performs the specific interrupt processing for the device
	 */
	Status = XIntc_Connect(&InterruptController,
			       SPI_INTR_ID,
			       (XInterruptHandler)XSpi_InterruptHandler,
			       (void *)SpiPtr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Start the interrupt controller such that interrupts are enabled for
	 * all devices that cause interrupts, specific real mode so that
	 * the SPI can cause interrupts through the interrupt controller.
	 */
	Status = XIntc_Start(&InterruptController, XIN_REAL_MODE);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Enable the interrupt for the SPI.
	 */
	XIntc_Enable(&InterruptController, SPI_INTR_ID);



	/*
	 * Initialize the exception table.
	 */
	Xil_ExceptionInit();

	/*
	 * Register the interrupt controller handler with the exception table.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				     (Xil_ExceptionHandler)INTC_HANDLER,
				     &InterruptController);

	/*
	 * Enable non-critical exceptions.
	 */
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}
