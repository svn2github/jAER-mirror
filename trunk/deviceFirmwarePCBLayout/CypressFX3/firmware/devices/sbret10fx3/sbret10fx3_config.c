#include "fx3.h"
#include "features/spi_support.h"

#if SBRET10FX3 == 1

i2cConfig_DeviceSpecific_Type i2cConfig_DeviceSpecific[] = {
	{ 0x68, 1, 128, 118, 400 * KILOHERTZ }, /* InvenSense MPU-6050 Motion Tracker (highest register 117, 400Khz) */
};
const uint8_t i2cConfig_DeviceSpecific_Length = (sizeof(i2cConfig_DeviceSpecific) / sizeof(i2cConfig_DeviceSpecific[0]));

spiConfig_DeviceSpecific_Type spiConfig_DeviceSpecific[] = {
	{ 0, 3, 256, 1 * MEGABYTE, 50 * MEGAHERTZ, CyFalse }, /* Winbond W25Q80BW Flash Memory (1MB, 50Mhz, SS: default line, active-low) */
	{ 57, 0, 0, 0, 33 * MEGAHERTZ, CyFalse }, /* Lattice ECP3-17 FPGA (no standard read/write support, 33Mhz, SS: GPIO 57, active-low) */
};
const uint8_t spiConfig_DeviceSpecific_Length = (sizeof(spiConfig_DeviceSpecific) / sizeof(spiConfig_DeviceSpecific[0]));

gpioConfig_DeviceSpecific_Type gpioConfig_DeviceSpecific[] = {
	{ 26, 'P' }, /* GPIO 26: Interrupt from Inertial Measurement Unit */
	// { 27, 'O' }, /* GPIO 27: Clock for Inertial Measurement Unit */
	{ 33, 'O' }, /* GPIO 33: Reset FPGA */
	{ 34, 'O' }, /* GPIO 34: FXLED */
	{ 35, 'O' }, /* GPIO 35: Px0 */
	{ 36, 'O' }, /* GPIO 36: Px1 */
	{ 37, 'O' }, /* GPIO 37: Px2 */
	{ 38, 'O' }, /* GPIO 38: Px3 */
	{ 39, 'O' }, /* GPIO 39: Px4 */
	{ 40, 'O' }, /* GPIO 40: Px5 */
	{ 41, 'O' }, /* GPIO 41: Px6 */
	{ 42, 'O' }, /* GPIO 42: Px7 */
	{ 43, 'O' }, /* GPIO 43: Px8 */
	{ 44, 'O' }, /* GPIO 44: Px9 */
	// { 45, 'O' }, /* GPIO 45: Spare1 */
	// { 46, 'O' }, /* GPIO 46: Spare2 */
	// { 47, 'O' }, /* GPIO 47: Spare3 */
	// { 48, 'O' }, /* GPIO 48: Spare4 */
	{ 49, 'O' }, /* GPIO 49: biasAddrSelect */
	{ 50, 'O' }, /* GPIO 50: Clock_Bias */
	{ 51, 'O' }, /* GPIO 51: Latch_Bias */
	{ 52, 'O' }, /* GPIO 52: BitIn_Bias */
};
const uint8_t gpioConfig_DeviceSpecific_Length = (sizeof(gpioConfig_DeviceSpecific) / sizeof(gpioConfig_DeviceSpecific[0]));

void CyFxHandleCustomGPIO_DeviceSpecific(uint8_t gpioId) {
	CyFxErrorHandler(LOG_DEBUG, "GPIO was toggled.", gpioId);
}

extern uint8_t CyFxUSBSerialNumberDscr[];
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

	return (status);
}

#define SNUM_MEMORY_ADDRESS 0x0C0000
#define FPGA_MEMORY_ADDRESS 0x030000
#define FPGA_SPI_ADDRESS 57

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

#endif /* SBRET10FX3 */
