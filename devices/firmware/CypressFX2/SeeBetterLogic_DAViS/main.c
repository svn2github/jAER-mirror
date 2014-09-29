#pragma NOIV // Do not generate interrupt vectors

#include "portsFX2.h"

#include "xsvf_player/ports.h"
#include "xsvf_player/micro.h"

extern BOOL GotSUD;

// Device-specific vendor requests
#define VR_EEPROM 0xBD
#define VR_CPLD_UPLOAD 0xBE
#define VR_CPLD_CONFIG 0xBF
#define VR_CHIP_BIAS 0xC0
#define VR_CHIP_DIAG 0xC1

// Request direction
#define USB_DIRECTION_MASK (0x80)
#define USB_DIRECTION_IN   (0x00) /* Host-to-Device */
#define USB_DIRECTION_OUT  (0x80) /* Device-to-Host */

#define USB_REQ_DIR(request, direction) (((direction) << 8) | (request))

#define EP0BUFF_SIZE 64 // Endpoint 0 (Control) buffer size
#define	I2C_EEPROM_ADDRESS 0x51 // 0101_0001 is the address of the external serial EEPROM that holds FX2 program and static data
#define EEPROM_SIZE (32 * 1024)
#define SERIAL_NUMBER_LENGTH 8

// XSVF support.
#define XSVF_DATA_SIZE 512

static BYTE xdata doJTAGInit = TRUE;
static BYTE xdata xsvfReturn = 0;
static unsigned char xdata xsvfDataArray[XSVF_DATA_SIZE];

// Support arbitrary waits.
static BYTE waitCounter = 0;
#define WAIT_FOR(CYCLES) for (waitCounter = 0; waitCounter < CYCLES; waitCounter++) { _nop_(); }

// Private functions.
static void BiasWrite(BYTE byte);
static void SPIWrite(BYTE byte);
static BYTE SPIRead(void);
static void EEPROMWrite(WORD address, BYTE length, BYTE xdata *buf);
static void EEPROMRead(WORD address, BYTE length, BYTE xdata *buf);

void downloadSerialNumberFromEEPROM(void);

void TD_Init(void) // Called once at startup
{
	// set the CPU clock to 48MHz. CLKOUT is normal polarity, disabled.
	CPUCS = 0x10; // 0001_0000

	// set the slave FIFO interface to 30MHz, slave fifo mode.
	IFCONFIG = 0xA3; // 1010_0011

	// disable interrupts by the input pins and by timers and serial ports
	IE = 0x00; // 0000_0000

	// disable interrupt pins 4, 5 and 6, keep I2C/USB enabled
	EIE = 0xE3; // 1110_0011

	// Registers which require a synchronization delay, see section 15.14
	// FIFORESET        FIFOPINPOLAR
	// INPKTEND         OUTPKTEND
	// EPxBCH:L         REVCTL
	// GPIFTCB3         GPIFTCB2
	// GPIFTCB1         GPIFTCB0
	// EPxFIFOPFH:L     EPxAUTOINLENH:L
	// EPxFIFOCFG       EPxGPIFFLGSEL
	// PINFLAGSxx       EPxFIFOIRQ
	// EPxFIFOIE        GPIFIRQ
	// GPIFIE           GPIFADRH:L
	// UDMACRCH:L       EPxGPIFTRIG
	// GPIFTRIG

	SYNCDELAY;
	REVCTL = 0x03; // As recommended by Cypress.

	// Enable Ports A, C and E
	SYNCDELAY;
	PORTACFG = 0x00; // do not use INT 0 and 1, disable SLCS (use PA7 normally)

	SYNCDELAY;
	PORTCCFG = 0x00;

	SYNCDELAY;
	PORTECFG = 0x00;

	SYNCDELAY;
	IOA = 0x00; // Keep all off
	IOC = 0xB8; // JTAG disabled (TMS, TCK, TDI high), SPI SSN is active-low
	IOE = 0x23; // Bias Clock, Latch and Address_Select are active-low

	SYNCDELAY;
	OEA = 0x00; // 0000_0000, none are used
	OEC = 0x0E; // 0000_1110, JTAG (left floating) and SPI (but not SPI MISO)
	OEE = 0xF7; // 1111_0111, Reset, FXLED and BIAS (but not PE3)

	SYNCDELAY;
	EP6CFG = 0xE0; // EP6 enabled, IN, bulk, quad-buffered -> 1110_0000

	SYNCDELAY;
	EP1OUTCFG &= 0x7F; // EP1OUT disabled
	SYNCDELAY;
	EP1INCFG &= 0x7F; // EP1IN disabled

	SYNCDELAY;
	EP2CFG &= 0x7F; // EP2 disabled

	SYNCDELAY;
	EP4CFG &= 0x7F; // EP4 disabled

	SYNCDELAY;
	EP8CFG &= 0x7F; // EP8 disabled

	// Ensure FIFO is reset.
	SYNCDELAY;
	FIFORESET = 0x80;

	SYNCDELAY;
	FIFORESET = 0x86;

	SYNCDELAY;
	FIFORESET = 0x00;

	SYNCDELAY;
	EP6FIFOCFG = 0x09; // 0000_1001

	// FIFO flag configuration: FlagA: EP6 programmable, FlagB: EP6 full, FlagC and FlagD unused.
	SYNCDELAY;
	PINFLAGSAB = 0xE6; // 1110_01100
	SYNCDELAY;
	PINFLAGSCD = 0x00;

	SYNCDELAY;
	FIFOPINPOLAR = 0x03; // 0000_0011, keep full/empty flags active-high!

	// FIFO commits automatically after 512 bytes.
	SYNCDELAY;
	EP6AUTOINLENH = 0x02;
	SYNCDELAY;
	EP6AUTOINLENL = 0x00;

	// FlagA triggers when the content of the current, not yet committed packet
	// is at or greater than 498 bytes (of 512 per packet).
	SYNCDELAY;
	EP6FIFOPFH = 0xC1; // 1100_0001
	SYNCDELAY;
	EP6FIFOPFL = 0xF2; // 1111_0010

	EZUSB_InitI2C(); // initialize I2C to enable EEPROM read and write
	I2CTL |= 0x01;  // set I2C to 400kHz to speed up data transfers

	// Reset CPLD by pulsing reset line.
	setPE(CPLD_RESET, 1);
	WAIT_FOR(20);
	setPE(CPLD_RESET, 0);
}

static void BiasWrite(BYTE byte) {
	BYTE i;

	// Disable clock. Bias clock is active-low!
	setPE(BIAS_CLOCK, 1);

	// Step through the eight bits of the given byte, starting at the highest
	// (MSB) and going down to the lowest (LSB).
	for (i = 0; i < 8; i++) {
		// Set the current bit value, based on the highest bit.
		if (byte & 0x80) {
			setPE(BIAS_BIT, 1);
		}
		else {
			setPE(BIAS_BIT, 0);
		}

		// Pulse clock to signal value is ready to be read.
		setPE(BIAS_CLOCK, 0);
		setPE(BIAS_CLOCK, 1);

		// Shift left by one, making the second highest bit the highest.
		byte = (byte << 1);
	}
}

static void SPIWrite(BYTE byte) {
	BYTE i;

	// Disable clock.
	CPLD_SPI_CLOCK = 0;

	// Step through the eight bits of the given byte, starting at the highest
	// (MSB) and going down to the lowest (LSB).
	for (i = 0; i < 8; i++) {
		// Set the current bit value, based on the highest bit.
		if (byte & 0x80) {
			CPLD_SPI_MOSI = 1;
		}
		else {
			CPLD_SPI_MOSI = 0;
		}

		// Pulse clock to signal value is ready to be read.
		CPLD_SPI_CLOCK = 1;
		CPLD_SPI_CLOCK = 0;

		// Shift left by one, making the second highest bit the highest.
		byte = (byte << 1);
	}
}

static BYTE SPIRead(void) {
	BYTE byte = 0;
	BYTE i;

	// Disable clock.
	CPLD_SPI_CLOCK = 0;

	for (i = 0; i < 8; i++) {
		// Pulse clock to signal slave to output new value.
		CPLD_SPI_CLOCK = 1;

		// Get the current bit value, based on the GPIO value.
		if (CPLD_SPI_MISO) {
			byte |= 1;
		}
		else {
			byte |= 0;
		}

		CPLD_SPI_CLOCK = 0;

		// Shift left by one, progressively moving the first set bit to be the MSB.
		if (i != 7) {
			byte = (byte << 1);
		}
	}

	return (byte);
}

static void EEPROMWrite(WORD address, BYTE length, BYTE xdata *buf)
{
	BYTE i;
	BYTE xdata ee_str[3];

	setPE(FXLED, 1);

	for (i = 0; i < length; i++) {
		ee_str[0] = MSB(address);
		ee_str[1] = LSB(address);
		ee_str[2] = buf[i];

		EZUSB_WriteI2C(I2C_EEPROM_ADDRESS, 3, ee_str);
		EZUSB_WaitForEEPROMWrite(I2C_EEPROM_ADDRESS);

		address++;
	}

	setPE(FXLED, 0);
}

static void EEPROMRead(WORD address, BYTE length, BYTE xdata *buf)
{
	BYTE i;
	BYTE xdata ee_str[2];

	setPE(FXLED, 1);

	ee_str[0] = MSB(address);
	ee_str[1] = LSB(address);

	EZUSB_WriteI2C(I2C_EEPROM_ADDRESS, 2, ee_str);

	// Set read buffer to known value.
	for (i = 0; i < length; i++) {
		buf[i] = 0xCD;
	}

	EZUSB_ReadI2C(I2C_EEPROM_ADDRESS, length, buf);

	setPE(FXLED, 0);
}

// Get serial number from EEPROM.
void downloadSerialNumberFromEEPROM(void)
{
	char *sNumDscrPtr;
	BYTE xdata sNum[SERIAL_NUMBER_LENGTH];
	BYTE i;

	// Get pointer to string descriptor 3, jump first two bytes (size + type)
	sNumDscrPtr = ((char *)EZUSB_GetStringDscr(3)) + 2;

	// Read string description from EEPROM
	EEPROMRead(EEPROM_SIZE - SERIAL_NUMBER_LENGTH, SERIAL_NUMBER_LENGTH, sNum);

	// Write serial number string descriptor to RAM
	for (i = 0; i < SERIAL_NUMBER_LENGTH; i++)
	{
		if (sNum[i] >= 32 && sNum[i] <= 126) {
			sNumDscrPtr[i * 2] = sNum[i];
		}
	}
}

void TD_Poll(void) // Called repeatedly while the device is idle
{
}

BOOL TD_Suspend(void) // Called before the device goes into suspend mode
{
	// Put CPLD in reset, which disables everything.
	setPE(CPLD_RESET, 1);

	return (TRUE);
}

BOOL TD_Resume(void) // Called after the device resumes
{
	// Take CPLD out of reset, which permits usage again.
	setPE(CPLD_RESET, 0);

	return (TRUE);
}

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------

BOOL DR_GetConfiguration(void) // Called when a Get Configuration command is received
{
	EP0BUF[0] = 0x00; // Configuration is 0
	EP0BCH = 0;
	EP0BCL = 1;

	return (TRUE); // Handled by user code
}

BOOL DR_GetInterface(void) // Called when a Get Interface command is received
{
	EP0BUF[0] = 0x00; // AlternateSetting is 0
	EP0BCH = 0;
	EP0BCL = 1;

	return (TRUE); // Handled by user code
}

BOOL DR_VendorCmnd(void) {
	WORD wValue, wIndex, wLength, wRequest;
	WORD i, currByteCount, address;

	// the value bytes are the specific config command
	// the index bytes are the arguments
	// more data comes in the setupdat
	// data comes little endian
	SYNCDELAY;

	wValue = SETUPDAT[2]; // Get USB request value
	wValue |= SETUPDAT[3] << 8;
	wIndex = SETUPDAT[4]; // Get USB request index
	wIndex |= SETUPDAT[5] << 8;
	wLength = SETUPDAT[6]; // Length for data phase
	wLength |= SETUPDAT[7] << 8;

	// Ensure request is 16bit.
	wRequest = USB_REQ_DIR(SETUPDAT[1], (SETUPDAT[0] & USB_DIRECTION_MASK));

	switch (wRequest) {
		case USB_REQ_DIR(VR_CHIP_BIAS, USB_DIRECTION_IN):
			// Ensure we're not accessing the chip diagnostic shift register.
			setPE(BIAS_DIAG_SELECT, 0);

			// Select addressed bias mode (active-low).
			setPE(BIAS_ADDR_SELECT, 0);

			// Write a byte, containing the bias address (from wValue).
			BiasWrite(wValue);

			// Latch bias.
			setPE(BIAS_LATCH, 0);
			WAIT_FOR(50);
			setPE(BIAS_LATCH, 1);

			// Release address selection (active-low).
			setPE(BIAS_ADDR_SELECT, 1);

			// Write out all the data bytes for this bias.
			while (wLength) {
				// Get data from USB control endpoint.
				// Move new data through EP0OUT, one packet at a time,
				// eventually will get length down to zero by, for
				// example, currByteCount = 64, 64, 15
				// Clear bytecount to allow new data in, also stops NAKing
				EP0BCH = 0;
				EP0BCL = 0;
				SYNCDELAY;

				while (EP0CS & bmEPBUSY) {
					;
				} // Spin here until data arrives

				currByteCount = EP0BCL; // Get the new byte count

				for (i = 0; i < currByteCount; i++) {
					BiasWrite(EP0BUF[i]);
				}

				wLength -= currByteCount; // Decrement total byte count
			}

			// Latch bias.
			setPE(BIAS_LATCH, 0);
			WAIT_FOR(50);
			setPE(BIAS_LATCH, 1);

			EP0BCH = 0;
			EP0BCL = 0; // Re-arm end-point for OUT transfers.

			break;

		case USB_REQ_DIR(VR_CHIP_DIAG, USB_DIRECTION_IN):
			// Ensure we are accessing the chip diagnostic shift register.
			setPE(BIAS_DIAG_SELECT, 1);

			// Write out all configuration bytes to the shift register.
			while (wLength) {
				// Get data from USB control endpoint.
				// Move new data through EP0OUT, one packet at a time,
				// eventually will get length down to zero by, for
				// example, currByteCount = 64, 64, 15
				// Clear bytecount to allow new data in, also stops NAKing
				EP0BCH = 0;
				EP0BCL = 0;
				SYNCDELAY;

				while (EP0CS & bmEPBUSY) {
					;
				} // Spin here until data arrives

				currByteCount = EP0BCL; // Get the new byte count

				for (i = 0; i < currByteCount; i++) {
					BiasWrite(EP0BUF[i]);
				}

				wLength -= currByteCount; // Decrement total byte count
			}

			// Latch configuration.
			setPE(BIAS_LATCH, 0);
			WAIT_FOR(50);
			setPE(BIAS_LATCH, 1);

			// We're done and can deselect the chip diagnostic SR.
			setPE(BIAS_DIAG_SELECT, 0);

			EP0BCH = 0;
			EP0BCL = 0; // Re-arm end-point for OUT transfers.

			break;

		case USB_REQ_DIR(VR_CPLD_CONFIG, USB_DIRECTION_IN):
			// Write out all configuration bytes to the FPGA, using its SPI bus.
			CPLD_SPI_SSN = 0; // SSN is active-low.

			// Highest bit of first byte is zero to indicate write operation.
			SPIWrite(wValue & 0x7F);
			SPIWrite(wIndex);

			while (wLength) {
				// Get data from USB control endpoint.
				// Move new data through EP0OUT, one packet at a time,
				// eventually will get length down to zero by, for
				// example, currByteCount = 64, 64, 15
				// Clear bytecount to allow new data in, also stops NAKing
				EP0BCH = 0;
				EP0BCL = 0;
				SYNCDELAY;

				while (EP0CS & bmEPBUSY) {
					;
				} // Spin here until data arrives

				currByteCount = EP0BCL; // Get the new byte count

				for (i = 0; i < currByteCount; i++) {
					SPIWrite(EP0BUF[i]);
				}

				wLength -= currByteCount; // Decrement total byte count
			}

			CPLD_SPI_SSN = 1; // SSN is active-low.

			EP0BCH = 0;
			EP0BCL = 0; // Re-arm end-point for OUT transfers.

			break;

		case USB_REQ_DIR(VR_CPLD_CONFIG, USB_DIRECTION_OUT):
			// Read configuration bits from the FPGA, using its SPI bus.
			CPLD_SPI_SSN = 0; // SSN is active-low.

			// Highest bit of first byte is one to indicate read operation.
			SPIWrite(wValue | 0x80);
			SPIWrite(wIndex);

			while (wLength) {
				// Send data to USB control endpoint.
				// Move requested data through EP0IN
				// one packet at a time.
				while (EP0CS & bmEPBUSY) {
					;
				} // Spin here until ready to send

				if (wLength < EP0BUFF_SIZE) {
					currByteCount = wLength;
				} else {
					currByteCount = EP0BUFF_SIZE;
				}

				for (i = 0; i < currByteCount; i++) {
					EP0BUF[i] = SPIRead();
				}

				EP0BCH = 0;
				EP0BCL = currByteCount; // Arm endpoint with # bytes to transfer
				SYNCDELAY;

				wLength -= currByteCount; // Decrement total byte count
			}

			CPLD_SPI_SSN = 1; // SSN is active-low.

			break;

		case USB_REQ_DIR(VR_EEPROM, USB_DIRECTION_IN):
			while (wLength) {
				// Get data from USB control endpoint.
				// Move new data through EP0OUT, one packet at a time,
				// eventually will get length down to zero by, for
				// example, currByteCount = 64, 64, 15
				// Clear bytecount to allow new data in, also stops NAKing
				EP0BCH = 0;
				EP0BCL = 0;
				SYNCDELAY;

				while (EP0CS & bmEPBUSY) {
					;
				} // Spin here until data arrives

				currByteCount = EP0BCL; // Get the new byte count

				EEPROMWrite(wValue, currByteCount, EP0BUF);

				wValue += currByteCount;

				wLength -= currByteCount; // Decrement total byte count
			}

			EP0BCH = 0;
			EP0BCL = 0; // Re-arm end-point for OUT transfers.

			break;

		case USB_REQ_DIR(VR_EEPROM, USB_DIRECTION_OUT):
			while (wLength) {
				// Send data to USB control endpoint.
				// Move requested data through EP0IN
				// one packet at a time.
				while (EP0CS & bmEPBUSY) {
					;
				} // Spin here until ready to send

				if (wLength < EP0BUFF_SIZE) {
					currByteCount = wLength;
				} else {
					currByteCount = EP0BUFF_SIZE;
				}

				EEPROMRead(wValue, currByteCount, EP0BUF);

				wValue += currByteCount;

				EP0BCH = 0;
				EP0BCL = currByteCount; // Arm endpoint with # bytes to transfer
				SYNCDELAY;

				wLength -= currByteCount; // Decrement total byte count
			}

			break;

		case USB_REQ_DIR(VR_CPLD_UPLOAD, USB_DIRECTION_IN):
			if (doJTAGInit) {
				IOC |= 0xB0; // JTAG disabled (TMS, TCK, TDI high)
				OEC = 0xBE; // 1011_1110, JTAG (but not TDO) and SPI (but not SPI MISO)

				xsvfInitializeSTM();

				doJTAGInit = FALSE;
			}

			if (wLength > XSVF_DATA_SIZE) {
				// Return different error code for overlong command.
				xsvfReturn = 10;

				OEC = 0x0E; // 0000_1110, JTAG (left floating) and SPI (but not SPI MISO)
				doJTAGInit = TRUE;

				break;
			}

			address = 0;

			resetDataArray(xsvfDataArray);

			while (wLength) {
				// Get data from USB control endpoint.
				// Move new data through EP0OUT, one packet at a time,
				// eventually will get length down to zero by, for
				// example, currByteCount = 64, 64, 15
				// Clear bytecount to allow new data in, also stops NAKing
				EP0BCH = 0;
				EP0BCL = 0;
				SYNCDELAY;

				while (EP0CS & bmEPBUSY) {
					;
				} // Spin here until data arrives

				currByteCount = EP0BCL; // Get the new byte count

				for (i = 0; i < currByteCount; i++) {
					xsvfDataArray[address + i] = EP0BUF[i];
				}

				address += currByteCount;

				wLength -= currByteCount; // Decrement total byte count
			}

			if (wValue == 0x00) {
				OEC = 0x0E; // 0000_1110, JTAG (left floating) and SPI (but not SPI MISO)
				doJTAGInit = TRUE;
			}
			else {
				xsvfReturn = xsvfRunSTM();

				if (xsvfReturn > 0) {
					OEC = 0x0E; // 0000_1110, JTAG (left floating) and SPI (but not SPI MISO)
					doJTAGInit = TRUE;
				}
			}

			EP0BCH = 0;
			EP0BCL = 0; // Re-arm end-point for OUT transfers.

			break;

		case USB_REQ_DIR(VR_CPLD_UPLOAD, USB_DIRECTION_OUT):
			EP0BUF[0] = VR_CPLD_UPLOAD;
			EP0BUF[1]= xsvfReturn;
			EP0BCH = 0;
			EP0BCL = 2;

			break;

		default: // We received an invalid command, so stall!
			return (TRUE);
	}

	// This will automatically ACK in fw.c.
	return (FALSE);
}

//-----------------------------------------------------------------------------
// USB Interrupt Handlers
//   The following functions are called by the USB interrupt jump table.
//-----------------------------------------------------------------------------

// Setup Data Available Interrupt Handler
void ISR_Sudav(void)
interrupt 0
{
	GotSUD = TRUE; // Set notification flag

	EZUSB_IRQ_CLEAR();
	USBIRQ = bmSUDAV; // Clear SUDAV IRQ
}

// Setup Token Interrupt Handler
void ISR_Sutok(void)
interrupt 0
{
	EZUSB_IRQ_CLEAR();
	USBIRQ = bmSUTOK; // Clear SUTOK IRQ
}

void ISR_Sof(void)
interrupt 0
{
	EZUSB_IRQ_CLEAR();
	USBIRQ = bmSOF; // Clear SOF IRQ
}

void ISR_Ures(void)
interrupt 0
{
	if (EZUSB_HIGHSPEED()) {
		pConfigDscr = pHighSpeedConfigDscr;
		pOtherConfigDscr = pFullSpeedConfigDscr;
		// packetSize = 512;

	}
	else {
		pConfigDscr = pFullSpeedConfigDscr;
		pOtherConfigDscr = pHighSpeedConfigDscr;
		// packetSize = 64;
	}

	EZUSB_IRQ_CLEAR();
	USBIRQ = bmURES; // Clear URES IRQ
}

void ISR_Susp(void)
interrupt 0
{
}

void ISR_Highspeed(void)
interrupt 0
{
	if (EZUSB_HIGHSPEED()) {
		pConfigDscr = pHighSpeedConfigDscr;
		pOtherConfigDscr = pFullSpeedConfigDscr;
		// packetSize = 512;
	}
	else {
		pConfigDscr = pFullSpeedConfigDscr;
		pOtherConfigDscr = pHighSpeedConfigDscr;
		// packetSize = 64;
	}

	EZUSB_IRQ_CLEAR();
	USBIRQ = bmHSGRANT; // Clear HSGRANT IRQ
}

void ISR_Ep0ack(void)
interrupt 0
{
}
void ISR_Stub(void)
interrupt 0
{
}
void ISR_Ep0in(void)
interrupt 0
{
}
void ISR_Ep0out(void)
interrupt 0
{
}
void ISR_Ep1in(void)
interrupt 0
{
}
void ISR_Ep1out(void)
interrupt 0
{
}
void ISR_Ep2inout(void)
interrupt 0
{
}
void ISR_Ep4inout(void)
interrupt 0
{
}
void ISR_Ep6inout(void)
interrupt 0
{
}
void ISR_Ep8inout(void)
interrupt 0
{
}
void ISR_Ibn(void)
interrupt 0
{
}
void ISR_Ep0pingnak(void)
interrupt 0
{
}
void ISR_Ep1pingnak(void)
interrupt 0
{
}
void ISR_Ep2pingnak(void)
interrupt 0
{
}
void ISR_Ep4pingnak(void)
interrupt 0
{
}
void ISR_Ep6pingnak(void)
interrupt 0
{
}
void ISR_Ep8pingnak(void)
interrupt 0
{
}
void ISR_Errorlimit(void)
interrupt 0
{
}
void ISR_Ep2piderror(void)
interrupt 0
{
}
void ISR_Ep4piderror(void)
interrupt 0
{
}
void ISR_Ep6piderror(void)
interrupt 0
{
}
void ISR_Ep8piderror(void)
interrupt 0
{
}
void ISR_Ep2pflag(void)
interrupt 0
{
}
void ISR_Ep4pflag(void)
interrupt 0
{
}
void ISR_Ep6pflag(void)
interrupt 0
{
}
void ISR_Ep8pflag(void)
interrupt 0
{
}
void ISR_Ep2eflag(void)
interrupt 0
{
}
void ISR_Ep4eflag(void)
interrupt 0
{
}
void ISR_Ep6eflag(void)
interrupt 0
{
}
void ISR_Ep8eflag(void)
interrupt 0
{
}
void ISR_Ep2fflag(void)
interrupt 0
{
}
void ISR_Ep4fflag(void)
interrupt 0
{
}
void ISR_Ep6fflag(void)
interrupt 0
{
}
void ISR_Ep8fflag(void)
interrupt 0
{
}
void ISR_GpifComplete(void)
interrupt 0
{
}
void ISR_GpifWaveform(void)
interrupt 0
{
}
