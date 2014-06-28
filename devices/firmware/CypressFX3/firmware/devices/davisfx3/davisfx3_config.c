#include "fx3.h"
#include "features/gpio_support.h"
#include "features/spi_support.h"
#include "features/i2c_support.h"

#if DAVISFX3 == 1

spiConfig_DeviceSpecific_Type spiConfig_DeviceSpecific[] = {
	{ 0, 3, 256, 1 * MEGABYTE, 50 * MEGAHERTZ, CyFalse }, /* Winbond W25Q80BW Flash Memory (1MB, 50Mhz, SS: default line, active-low) */
	{ 57, 0, 0, 0, 33 * MEGAHERTZ, CyFalse }, /* Lattice ECP3-17 FPGA (no standard read/write support, 33Mhz, SS: GPIO 57, active-low) */
};
const uint8_t spiConfig_DeviceSpecific_Length = (sizeof(spiConfig_DeviceSpecific) / sizeof(spiConfig_DeviceSpecific[0]));

gpioConfig_DeviceSpecific_Type gpioConfig_DeviceSpecific[] = {
	// { 26, 'P' }, /* GPIO 26: Interrupt from Inertial Measurement Unit */
	// { 27, 'O' }, /* GPIO 27: Clock for Inertial Measurement Unit */
	{ 33, 'O' }, /* GPIO 33: FPGA_Reset */
	{ 34, 'O' }, /* GPIO 34: FX3_LED */
	{ 35, 'O' }, /* GPIO 35 (Px0): FPGA_Run */
	{ 36, 'O' }, /* GPIO 36 (Px1): DVS_Run */
	{ 37, 'O' }, /* GPIO 37 (Px2): APS_Run */
	{ 38, 'O' }, /* GPIO 38 (Px3): IMU_Run */
	{ 39, 'o' }, /* GPIO 39 (Px4): FPGA_SPI_SSN (active-low) */
	{ 40, 'O' }, /* GPIO 40 (Px5): FPGA_SPI_Clock */
	{ 41, 'O' }, /* GPIO 41 (Px6): FPGA_SPI_MOSI */
	{ 42, 'O' }, /* GPIO 42 (Px7): FPGA_SPI_MISO */
	// { 43, 'O' }, /* GPIO 43 (Px8): */
	// { 44, 'O' }, /* GPIO 44 (Px9): */
	// { 45, 'O' }, /* GPIO 45: */
	// { 46, 'O' }, /* GPIO 46: */
	{ 47, 'O' }, /* GPIO 47: Bias_Enable */
	{ 48, 'O' }, /* GPIO 48: Bias_Diag_Select */
	{ 49, 'o' }, /* GPIO 49: Bias_Addr_Select (active-low) */
	{ 50, 'o' }, /* GPIO 50: Bias_Clock (active-low) */
	{ 51, 'o' }, /* GPIO 51: Bias_Latch (active-low) */
	{ 52, 'O' }, /* GPIO 52: Bias_Bit */
};
const uint8_t gpioConfig_DeviceSpecific_Length = (sizeof(gpioConfig_DeviceSpecific) / sizeof(gpioConfig_DeviceSpecific[0]));

// Define GPIO to function mappings.
#define FPGA_RESET 33
#define FPGA_RUN 35
#define DVS_RUN 36
#define APS_RUN 37
#define IMU_RUN 38
#define FPGA_SPI_SSN 39
#define FPGA_SPI_CLOCK 40
#define FPGA_SPI_MOSI 41
#define FPGA_SPI_MISO 42
#define BIAS_ENABLE 47
#define BIAS_DIAG_SELECT 48
#define BIAS_ADDR_SELECT 49
#define BIAS_CLOCK 50
#define BIAS_LATCH 51
#define BIAS_BIT 52

// Memory and device addresses.
#define SNUM_MEMORY_ADDRESS 0x0C0000
#define FPGA_MEMORY_ADDRESS 0x030000
#define FPGA_SPI_ADDRESS 57

void CyFxHandleCustomGPIO_DeviceSpecific(uint8_t gpioId) {
	CyFxErrorHandler(LOG_DEBUG, "GPIO was toggled.", gpioId);
}

extern uint8_t CyFxUSBSerialNumberDscr[];
static inline void CyFxWriteByteToShiftReg(uint8_t byte, uint8_t clockID, uint8_t bitID);
static inline CyU3PReturnStatus_t CyFxCustomInit_LoadSerialNumber(void);
static inline CyU3PReturnStatus_t CyFxCustomInit_LoadFPGABitstream(void);

CyU3PReturnStatus_t CyFxHandleCustomINIT_DeviceSpecific(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Set Serial Number to vale read from SPI Flash.
	status = CyFxCustomInit_LoadSerialNumber();
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// Load bitstream from SPI Flash to FPGA in 4KB chunks.
	status = CyFxCustomInit_LoadFPGABitstream();
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// Reset FPGA logic (pulse reset).
	CyFxGpioTurnOn(FPGA_RESET);
	CyU3PBusyWait(2);
	CyFxGpioTurnOff(FPGA_RESET);

	return (status);
}

// FPGA commands
#define FPGA_CMD_READ_ID 0x07
#define FPGA_CMD_READ_STATUS 0x09
#define FPGA_CMD_REFRESH 0x71
#define FPGA_CMD_WRITE_INC 0x41
#define FPGA_CMD_WRITE_EN 0x4A
#define FPGA_CMD_WRITE_DIS 0x4F

// USB FPGA configuration phases
#define FPGA_CONFIG_PHASE_INIT 0 /* Check FPGA model, do refresh, clear memory */
#define FPGA_CONFIG_PHASE_DATA_FIRST 1 /* Enable configuration and send first chunk */
#define FPGA_CONFIG_PHASE_DATA 2 /* Send extra chunks */
#define FPGA_CONFIG_PHASE_DATA_LAST 3 /* Send last chunk and disable configuration */

// Device-specific vendor requests
#define VR_FPGA_CONFIG 0xBE
#define VR_DATA_ENABLE 0xBF
#define VR_CHIP_BIAS 0xC0
#define VR_CHIP_DIAG 0xC1
#define VR_FPGA_CONFIG 0xC2

CyBool_t CyFxHandleCustomVR_DeviceSpecific(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength) {
	(void) wIndex; // UNUSED

	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	switch (FX3_REQ_DIR(bRequest, bDirection)) {
		case FX3_REQ_DIR(VR_FPGA_CONFIG, FX3_USB_DIRECTION_IN): {
			uint8_t cmd[4] = { 0 };

			switch (wValue) {
				case FPGA_CONFIG_PHASE_INIT:
					if (wLength != 0) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG INIT: no payload allowed", status);
						break;
					}

					// Clock in REFRESH command to reset FPGA and wait 50 ms as per documentation.
					cmd[0] = FPGA_CMD_REFRESH;
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG INIT: failed to reset FPGA", status);
						break;
					}

					CyU3PThreadSleep(50);

					// Clock in READ ID command
					cmd[0] = FPGA_CMD_READ_ID;
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, glEP0Buffer, 4, SPI_READ,
						SPI_ASSERT | SPI_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG INIT: failed to read FPGA ID", status);
						break;
					}

					// Verify that returned ID matches the expected one. The Lattice ECP3-17EA FPGA has a JTAG IDCODE
					// of 0x01010043. It is returned bit-inverted, so it becomes 0xC2008080 for comparison. Further
					// the FX3 is a little-endian system, so we have to reverse the bytes: 0x808000C2.
					if ((*(uint32_t *) glEP0Buffer) != 0x808000C2) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG INIT: unsupported FPGA ID", status);
						break;
					}

					// Clock in REFRESH command
					cmd[0] = FPGA_CMD_REFRESH;
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG INIT: failed to refresh FPGA", status);
						break;
					}

					CyU3PUsbAckSetup();

					break;

				case FPGA_CONFIG_PHASE_DATA_FIRST:
					if (wLength == 0) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG FIRST: zero byte transfer invalid", status);
						break;
					}

					// Clock in WRITE ENABLE command
					cmd[0] = FPGA_CMD_WRITE_EN;
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG FIRST: failed to enable writing", status);
						break;
					}

					// Read first bitstream chunk from USB
					status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG FIRST: CyU3PUsbGetEP0Data failed", status);
						break;
					}

					// Write first bitstream chunk to FPGA and send WRITE CONFIG command
					cmd[0] = FPGA_CMD_WRITE_INC;
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, glEP0Buffer, wLength, SPI_WRITE,
						SPI_ASSERT | SPI_NO_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						// CyFxSpiCommand() takes care to deassert the SS line on failure.
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG FIRST: writing first data chunk failed", status);
						break;
					}

					// Turn on SPI Flash SlaveSelect line, which also turns on the HOLD pin on the FPGA
					CyFxSpiSSLineAssert(0);

					break;

				case FPGA_CONFIG_PHASE_DATA:
					if (wLength == 0) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG DATA: zero byte transfer invalid", status);
						break;
					}

					// Read bitstream chunk from USB
					status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
					if (status != CY_U3P_SUCCESS) {
						CyFxSpiSSLineDeassert(0); // Ensure reset to default state on error.
						CyFxSpiSSLineDeassert(FPGA_SPI_ADDRESS); // Ensure reset to default state on error for FPGA.
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG DATA: CyU3PUsbGetEP0Data failed", status);
						break;
					}

					// Turn off SPI Flash SlaveSelect line, which also turns off the HOLD pin on the FPGA
					CyFxSpiSSLineDeassert(0);

					// Write bitstream chunk to FPGA
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, NULL, 0, glEP0Buffer, wLength, SPI_WRITE,
						SPI_NO_ASSERT | SPI_NO_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						// CyFxSpiCommand() takes care to deassert the SS line on failure.
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG DATA: writing data chunk failed", status);
						break;
					}

					// Turn on SPI Flash SlaveSelect line, which also turns on the HOLD pin on the FPGA
					CyFxSpiSSLineAssert(0);

					break;

				case FPGA_CONFIG_PHASE_DATA_LAST:
					// Read last bitstream chunk from USB. Might be zero if exact multiple of 4KB.
					if (wLength != 0) {
						status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
						if (status != CY_U3P_SUCCESS) {
							CyFxSpiSSLineDeassert(0); // Ensure reset to default state on error.
							CyFxSpiSSLineDeassert(FPGA_SPI_ADDRESS); // Ensure reset to default state on error for FPGA.
							CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG LAST: CyU3PUsbGetEP0Data failed", status);
							break;
						}
					}
					else {
						CyU3PUsbAckSetup();
					}

					// Turn off SPI Flash SlaveSelect line, which also turns off the HOLD pin on the FPGA
					CyFxSpiSSLineDeassert(0);

					// Write last bitstream chunk to FPGA and deassert SlaveSelect line
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, NULL, 0, (wLength == 0) ? (NULL) : (glEP0Buffer), wLength,
						SPI_WRITE, SPI_NO_ASSERT | SPI_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						// CyFxSpiCommand() takes care to deassert the SS line on failure.
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG LAST: writing last data chunk failed", status);
						break;
					}

					// Clock in READ STATUS command
					cmd[0] = FPGA_CMD_READ_STATUS;
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, glEP0Buffer, 4, SPI_READ,
						SPI_ASSERT | SPI_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG LAST: failed to read FPGA status", status);
						break;
					}

					// Verify status: valid bitstream, no encryption, standard preamble, memory cleared, device
					// not secured and DONE. That's a value of 0x00814000. We also need to first make sure only
					// the values we're interested in are considered, not also the ones reserved by Lattice.
					// That means applying a mask of 0xAF81C000 to the value, in FX3 little-endian: 0x00C081AF.
					// And the status value to compare to becomse 0x00408100 in FX3 little-endian.
					if (((*(uint32_t *) glEP0Buffer) & 0x00C081AF) != 0x00408100) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG LAST: status not DONE", status);
						break;
					}

					// Clock in WRITE DISABLE command
					cmd[0] = FPGA_CMD_WRITE_DIS;
					status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG LAST: failed to disable writing", status);
						break;
					}

					break;

				default:
					status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
					CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG: invalid config phase", status);

					break;
			}

			break;
		}

		case FX3_REQ_DIR(VR_DATA_ENABLE, FX3_USB_DIRECTION_IN):
			if (wLength != 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_DATA_ENABLE: no payload allowed", status);
				break;
			}

			if (wValue == 0) {
				// Disable data output.
				CyFxGpioTurnOff(FPGA_RUN);

				CyFxGpioTurnOff(DVS_RUN);
				CyFxGpioTurnOff(APS_RUN);
				CyFxGpioTurnOff(IMU_RUN);

				// Shut off bias generator, and thus the whole chip.
				CyFxGpioTurnOff(BIAS_ENABLE);
			}
			else {
				// Enable bias generator (power to chip).
				CyFxGpioTurnOn(BIAS_ENABLE);

				// Enable all data producers.
				CyFxGpioTurnOn(DVS_RUN);
				CyFxGpioTurnOn(APS_RUN);
				CyFxGpioTurnOn(IMU_RUN);

				// Enable data output on FPGA.
				CyFxGpioTurnOn(FPGA_RUN);
			}

			CyU3PUsbAckSetup();

			break;

		case FX3_REQ_DIR(VR_CHIP_BIAS, FX3_USB_DIRECTION_IN):
			if (wLength == 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_CHIP_BIAS: zero byte transfer invalid", status);
				break;
			}

			// Get data from USB control endpoint.
			status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_CHIP_BIAS: CyU3PUsbGetEP0Data failed", status);
				break;
			}

			// Ensure we're not accessing the chip diagnostic shift register.
			CyFxGpioTurnOff(BIAS_DIAG_SELECT);

			// Select addressed bias mode.
			CyFxGpioTurnOn(BIAS_ADDR_SELECT);

			// Write a byte, containing the bias address (from wValue).
			CyFxWriteByteToShiftReg((uint8_t) wValue, BIAS_CLOCK, BIAS_BIT);

			// Latch bias.
			CyFxGpioTurnOn(BIAS_LATCH);
			CyU3PBusyWait(10);
			CyFxGpioTurnOff(BIAS_LATCH);

			// Release address selection.
			CyFxGpioTurnOff(BIAS_ADDR_SELECT);

			// Write out all the data bytes for this bias.
			for (size_t i = 0; i < wLength; i++) {
				CyFxWriteByteToShiftReg(glEP0Buffer[i], BIAS_CLOCK, BIAS_BIT);
			}

			// Latch bias.
			CyFxGpioTurnOn(BIAS_LATCH);
			CyU3PBusyWait(10);
			CyFxGpioTurnOff(BIAS_LATCH);

			break;

		case FX3_REQ_DIR(VR_CHIP_DIAG, FX3_USB_DIRECTION_IN):
			if (wLength == 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_CHIP_DIAG: zero byte transfer invalid", status);
				break;
			}

			// Get data from USB control endpoint.
			status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_CHIP_DIAG: CyU3PUsbGetEP0Data failed", status);
				break;
			}

			// Ensure we are accessing the chip diagnostic shift register.
			CyFxGpioTurnOn(BIAS_DIAG_SELECT);

			// Write out all configuration bytes to the shift register.
			for (size_t i = 0; i < wLength; i++) {
				CyFxWriteByteToShiftReg(glEP0Buffer[i], BIAS_CLOCK, BIAS_BIT);
			}

			// Latch configuration.
			CyFxGpioTurnOn(BIAS_LATCH);
			CyU3PBusyWait(10);
			CyFxGpioTurnOff(BIAS_LATCH);

			// We're done and can deselect the chip diagnostic SR.
			CyFxGpioTurnOff(BIAS_DIAG_SELECT);

			break;

		case FX3_REQ_DIR(VR_FPGA_CONFIG, FX3_USB_DIRECTION_IN): {
			if (wLength == 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG: zero byte transfer invalid", status);
				break;
			}

			// Get data from USB control endpoint.
			status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_FPGA_CONFIG: CyU3PUsbGetEP0Data failed", status);
				break;
			}

			// Write out all configuration bytes to the FPGA, using its SPI bus.
			// Only writing is supported for now via bit-banging the SPI interface.
			// Newer boards will migrate this to the embedded SPI controller for full-duplex.
			CyFxGpioTurnOn(FPGA_SPI_SSN);

			for (size_t i = 0; i < wLength; i++) {
				CyFxWriteByteToShiftReg(glEP0Buffer[i], FPGA_SPI_CLOCK, FPGA_SPI_MOSI);
			}

			CyFxGpioTurnOff(FPGA_SPI_SSN);

			break;
		}

		default:
			// Not handled in this module
			return (CyFalse);

			break;
	}

	// If status is success, it means we handled the vendor request and did so without encountering an error.
	// Else, some error occurred while handling the request, so we stall the endpoint ourselves.
	if (status != CY_U3P_SUCCESS) {
		CyU3PUsbStall(0, CyTrue, CyTrue);
	}

	// In any case, we handled the request!
	return (CyTrue);
}

static inline void CyFxWriteByteToShiftReg(uint8_t byte, uint8_t clockID, uint8_t bitID) {
	// Disable clock.
	CyFxGpioTurnOff(clockID);

	// Step through the eight bits of the given byte, starting at the highest
	// (MSB) and going down to the lowest (LSB).
	for (size_t i = 0; i < 8; i++) {
		// Set the current bit value, based on the highest bit.
		if (byte & 0x80) {
			CyFxGpioTurnOn(bitID);
		}
		else {
			CyFxGpioTurnOff(bitID);
		}

		// Pulse clock to signal value is ready to be read.
		CyFxGpioTurnOn(clockID);
		CyFxGpioTurnOff(clockID);

		// Shift left by one, making the second highest bit the highest.
		byte = (uint8_t) (byte << 1);
	}
}

static inline CyU3PReturnStatus_t CyFxCustomInit_LoadSerialNumber(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	uint32_t serialNumberHeader[2];

	status = CyFxSpiTransfer(0, SNUM_MEMORY_ADDRESS, (uint8_t *) serialNumberHeader, 8, SPI_READ);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	if (!memcmp(serialNumberHeader, "SNUM", 4)) {
		// Found valid Serial Number identifier!
		uint32_t serialNumberLength = serialNumberHeader[1];

		if (serialNumberLength == 0) {
			return (status);
		}

		uint8_t serialNumber[8];

		if (serialNumberLength > 8) {
			serialNumberLength = 8; // Maximum length is 8!
		}

		status = CyFxSpiTransfer(0, (SNUM_MEMORY_ADDRESS + 8), serialNumber, (uint16_t) serialNumberLength, SPI_READ);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		uint32_t maxSerialNumberLength = STRING_SERIALNUMBER_LEN / 2;

		if (serialNumberLength > maxSerialNumberLength) {
			serialNumberLength = maxSerialNumberLength;
		}

		size_t pos = 2;

		// Zero out unused bytes
		for (size_t i = 0; i < (maxSerialNumberLength - serialNumberLength); i++) {
			CyFxUSBSerialNumberDscr[pos++] = '0';
			CyFxUSBSerialNumberDscr[pos++] = 0x00;
		}

		// Copy Serial Number
		for (size_t i = 0; i < serialNumberLength; i++) {
			CyFxUSBSerialNumberDscr[pos++] = serialNumber[i];
			CyFxUSBSerialNumberDscr[pos++] = 0x00;
		}
	}

	return (status);
}

static inline CyU3PReturnStatus_t CyFxCustomInit_LoadFPGABitstream(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	uint32_t fpgaBitstreamHeader[2];

	status = CyFxSpiTransfer(0, FPGA_MEMORY_ADDRESS, (uint8_t *) fpgaBitstreamHeader, 8, SPI_READ);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	if (!memcmp(fpgaBitstreamHeader, "FPGA", 4)) {
		// Found valid FPGA bitstream identifier!
		uint32_t fpgaBitstreamLength = fpgaBitstreamHeader[1];

		if (fpgaBitstreamLength < FX3_MAX_TRANSFER_SIZE_CONTROL) {
			return (status);
		}

		uint8_t cmd[4] = { 0 };

		// Delay for 50 ms according to documentation to ensure FPGA initialization.
		CyU3PThreadSleep(50);

		// Clock in READ ID command
		cmd[0] = FPGA_CMD_READ_ID;
		status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, glEP0Buffer, 4, SPI_READ, SPI_ASSERT | SPI_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		// Verify that returned ID matches the expected one. The Lattice ECP3-17EA FPGA has a JTAG IDCODE
		// of 0x01010043. It is returned bit-inverted, so it becomes 0xC2008080 for comparison. Further
		// the FX3 is a little-endian system, so we have to reverse the bytes: 0x808000C2.
		if ((*(uint32_t *) glEP0Buffer) != 0x808000C2) {
			return (CY_U3P_ERROR_NOT_SUPPORTED);
		}

		// Clock in REFRESH command
		cmd[0] = FPGA_CMD_REFRESH;
		status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		// Clock in WRITE ENABLE command
		cmd[0] = FPGA_CMD_WRITE_EN;
		status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		uint32_t memAddress = (FPGA_MEMORY_ADDRESS + 8);

		// Read first bitstream chunk from SPI Flash (first read slightly shorter to align to page size)
		status = CyFxSpiTransfer(0, memAddress, glEP0Buffer, (FX3_MAX_TRANSFER_SIZE_CONTROL - 8), SPI_READ);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		// Write first bitstream chunk to FPGA and send WRITE CONFIG command
		cmd[0] = FPGA_CMD_WRITE_INC;
		status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, glEP0Buffer, (FX3_MAX_TRANSFER_SIZE_CONTROL - 8), SPI_WRITE,
			SPI_ASSERT | SPI_NO_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		// Update involved counters
		memAddress += (FX3_MAX_TRANSFER_SIZE_CONTROL - 8);
		fpgaBitstreamLength -= (FX3_MAX_TRANSFER_SIZE_CONTROL - 8);

		while (fpgaBitstreamLength > FX3_MAX_TRANSFER_SIZE_CONTROL) {
			// Read bitstream chunk from SPI Flash
			status = CyFxSpiTransfer(0, memAddress, glEP0Buffer, FX3_MAX_TRANSFER_SIZE_CONTROL, SPI_READ);
			if (status != CY_U3P_SUCCESS) {
				return (status);
			}

			// Write bitstream chunk to FPGA
			status = CyFxSpiCommand(FPGA_SPI_ADDRESS, NULL, 0, glEP0Buffer, FX3_MAX_TRANSFER_SIZE_CONTROL, SPI_WRITE,
				SPI_NO_ASSERT | SPI_NO_DEASSERT);
			if (status != CY_U3P_SUCCESS) {
				return (status);
			}

			// Update involved counters
			memAddress += FX3_MAX_TRANSFER_SIZE_CONTROL;
			fpgaBitstreamLength -= FX3_MAX_TRANSFER_SIZE_CONTROL;
		}

		// Read last bitstream chunk from SPI Flash
		if (fpgaBitstreamLength != 0) {
			status = CyFxSpiTransfer(0, memAddress, glEP0Buffer, (uint16_t) fpgaBitstreamLength, SPI_READ);
			if (status != CY_U3P_SUCCESS) {
				return (status);
			}
		}

		// Write last bitstream chunk to FPGA and deassert SlaveSelect line
		status = CyFxSpiCommand(FPGA_SPI_ADDRESS, NULL, 0, (fpgaBitstreamLength == 0) ? (NULL) : (glEP0Buffer),
			(uint16_t) fpgaBitstreamLength, SPI_WRITE, SPI_NO_ASSERT | SPI_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		// Clock in READ STATUS command
		cmd[0] = FPGA_CMD_READ_STATUS;
		status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, glEP0Buffer, 4, SPI_READ, SPI_ASSERT | SPI_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}

		// Verify status: valid bitstream, no encryption, standard preamble, memory cleared, device
		// not secured and DONE. That's a value of 0x00814000. We also need to first make sure only
		// the values we're interested in are considered, not also the ones reserved by Lattice.
		// That means applying a mask of 0xAF81C000 to the value, in FX3 little-endian: 0x00C081AF.
		// And the status value to compare to becomse 0x00408100 in FX3 little-endian.
		if (((*(uint32_t *) glEP0Buffer) & 0x00C081AF) != 0x00408100) {
			return (CY_U3P_ERROR_NOT_STARTED);
		}

		// Clock in WRITE DISABLE command
		cmd[0] = FPGA_CMD_WRITE_DIS;
		status = CyFxSpiCommand(FPGA_SPI_ADDRESS, cmd, 4, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}
	}

	return (status);
}

#endif /* DAVISFX3 */
