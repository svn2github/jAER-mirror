#include "cyu3i2c.h"
#include "fx3.h"
#include "i2c_support.h"

// Map for fast configuration lookup (the highest address possible is 127, as an I2C address has 7 bits).
static i2cConfig_DeviceSpecific_Type *i2cIdConfigMap[128] = { NULL }; // NULL is always an invalid pointer.

// Frequency at which the I2C block operates.
static uint32_t currentI2cFrequency = I2C_MAX_CLOCK;

// Address of device currently used via USB VRs.
static uint8_t currentI2cDeviceAddress = 0xFF; // 0xFF is always invalid (7 bits at the most).

static int CyFxI2cConfigComparator_I2CCONFIG_DEVICESPECIFIC_TYPE(const void *a, const void *b) {
	const i2cConfig_DeviceSpecific_Type *aa = a;
	const i2cConfig_DeviceSpecific_Type *bb = b;

	if (aa->deviceAddress > bb->deviceAddress) {
		return (1); // Greater than
	}

	if (aa->deviceAddress < bb->deviceAddress) {
		return (-1); // Less than
	}

	return (0); // Equal
}

CyU3PReturnStatus_t CyFxI2cConfigParse(void) {
	// Enabling the I2C block without any devices defined? Nope!
	if (i2cConfig_DeviceSpecific_Length == 0) {
		return (CY_U3P_ERROR_NOT_CONFIGURED);
	}

	// Make sure i2cConfig is sorted for duplicate ID detection.
	qsort(i2cConfig_DeviceSpecific, i2cConfig_DeviceSpecific_Length, sizeof(i2cConfig_DeviceSpecific_Type),
		&CyFxI2cConfigComparator_I2CCONFIG_DEVICESPECIFIC_TYPE);

	// Detect duplicates (which of course are forbidden!) (NOTE: there can be none if only one is used!)
	if (i2cConfig_DeviceSpecific_Length > 1) {
		for (size_t i = 1; i < i2cConfig_DeviceSpecific_Length; i++) {
			if (!CyFxI2cConfigComparator_I2CCONFIG_DEVICESPECIFIC_TYPE(&i2cConfig_DeviceSpecific[i],
				&i2cConfig_DeviceSpecific[i - 1])) {
				return (CY_U3P_ERROR_INVALID_CONFIGURATION);
			}
		}
	}

	for (size_t i = 0; i < i2cConfig_DeviceSpecific_Length; i++) {
		// Verify that the MSB of every device address is always 0, as I2C addresses are 7 bits only.
		if (i2cConfig_DeviceSpecific[i].deviceAddress & 0x80) {
			return (CY_U3P_ERROR_BAD_INDEX);
		}

		// Check address length and page size maximum values.
		if (i2cConfig_DeviceSpecific[i].addressLength > 4) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		if (i2cConfig_DeviceSpecific[i].pageSize > FX3_MAX_TRANSFER_SIZE_CONTROL) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		// Make sure the pageSize is either 0 or a power of two.
		if ((i2cConfig_DeviceSpecific[i].pageSize != 0)
			&& (i2cConfig_DeviceSpecific[i].pageSize & (i2cConfig_DeviceSpecific[i].pageSize - 1))) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		// Verify that maxFrequency is never 0 and update the global I2C frequency.
		if (i2cConfig_DeviceSpecific[i].maxFrequency == 0) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		if (i2cConfig_DeviceSpecific[i].maxFrequency < currentI2cFrequency) {
			currentI2cFrequency = i2cConfig_DeviceSpecific[i].maxFrequency;
		}

		// Update direct map for fast lookup of device configuration based on address.
		i2cIdConfigMap[i2cConfig_DeviceSpecific[i].deviceAddress] = &i2cConfig_DeviceSpecific[i];
	}

	// Set current device for USB requests to something valid, like the first one in the config array.
	currentI2cDeviceAddress = i2cConfig_DeviceSpecific[0].deviceAddress;

	return (CY_U3P_SUCCESS);
}

CyU3PReturnStatus_t CyFxI2cInit(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Initialize and configure the I2C master module.
	status = CyU3PI2cInit();
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// Start the I2C master block.
	CyU3PI2cConfig_t i2cConfig;

	i2cConfig.bitRate = currentI2cFrequency;
	i2cConfig.isDma = CyFalse;
	i2cConfig.busTimeout = 0xFFFFFFFF; // No timeout, register mode is fully blocking according to documentation.
	i2cConfig.dmaTimeout = 0xFFFF; // No timeout, DMA is not used.

	status = CyU3PI2cSetConfig(&i2cConfig, NULL);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	return (status);
}

static CyU3PReturnStatus_t CyFxI2cTransferConfig(uint8_t deviceAddress, uint8_t addressLength, uint16_t pageSize) {
	// Check for invalid input values.
	if ((deviceAddress & 0x80) || (i2cIdConfigMap[deviceAddress] == NULL) || (addressLength > 4)
		|| (pageSize > FX3_MAX_TRANSFER_SIZE_CONTROL) || ((pageSize != 0) && (pageSize & (pageSize - 1)))) {

		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// Update current device configuration for subsequent transfers.
	if (addressLength != 0) {
		i2cIdConfigMap[deviceAddress]->addressLength = addressLength;
	}

	if (pageSize != 0) {
		i2cIdConfigMap[deviceAddress]->pageSize = pageSize;
	}

	// Update device address for subsequent USB requests.
	currentI2cDeviceAddress = deviceAddress;

	return (CY_U3P_SUCCESS);
}

// 'data' must be defined, and 'dataLenght' cannot be zero! Calling this without the
// intention of doing a transfer makes no sense.
CyU3PReturnStatus_t CyFxI2cTransfer(uint8_t deviceAddress, uint32_t address, uint8_t *data, uint16_t dataLength,
	CyBool_t isRead) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Verify the device address for later lookups.
	if ((deviceAddress & 0x80) || (i2cIdConfigMap[deviceAddress] == NULL)) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// When using the standard transfer function, address length, page size and device size MUST be defined!
	if ((i2cIdConfigMap[deviceAddress]->addressLength == 0) || (i2cIdConfigMap[deviceAddress]->pageSize == 0)
		|| (i2cIdConfigMap[deviceAddress]->deviceSize == 0)) {
		return (CY_U3P_ERROR_INVALID_CONFIGURATION);
	}

	// Check for invalid input values, especially command can't have any bits set above its command length
	if ((i2cIdConfigMap[deviceAddress]->addressLength != 4
		&& address >= ((uint32_t) 0x01 << (i2cIdConfigMap[deviceAddress]->addressLength * 8))) || (data == NULL)
		|| (dataLength == 0) || (dataLength > i2cIdConfigMap[deviceAddress]->deviceSize)
		|| (address > (i2cIdConfigMap[deviceAddress]->deviceSize - dataLength))) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	uint16_t commandCount, commandDataLength;

	// Is the address page-aligned or in the middle of one?
	if (address & (uint16_t) (i2cIdConfigMap[deviceAddress]->pageSize - 1)) {
		// NOT ALIGNED TO PAGE

		// Find out how much bytes we can still write in the same page, based on the start address
		const uint16_t dataInPage = (uint16_t) (i2cIdConfigMap[deviceAddress]->pageSize
			- (uint16_t) (address & (uint16_t) (i2cIdConfigMap[deviceAddress]->pageSize - 1)));

		// Now calculate how many times to call the command and how much data to pass the first time based on it
		commandDataLength = (dataLength >= dataInPage) ? (dataInPage) : (dataLength);
		commandCount = (uint16_t) (((uint16_t) (dataLength - commandDataLength)
			/ i2cIdConfigMap[deviceAddress]->pageSize) + 1); // + 1: the first call

		// Check if there is outstanding data in the transfer, in which case we need to send the command once more
		if (((dataLength - commandDataLength) % i2cIdConfigMap[deviceAddress]->pageSize) != 0) {
			commandCount++;
		}
	}
	else {
		// ALIGNED TO PAGE

		// Calculate how many times to call the command and how much data to pass the first time
		commandDataLength =
			(dataLength >= i2cIdConfigMap[deviceAddress]->pageSize) ?
				(i2cIdConfigMap[deviceAddress]->pageSize) : (dataLength);
		commandCount = (dataLength / i2cIdConfigMap[deviceAddress]->pageSize);

		// Check if there is outstanding data in the transfer, in which case we need to send the command once more
		if ((dataLength % i2cIdConfigMap[deviceAddress]->pageSize) != 0) {
			commandCount++;
		}
	}

	// Create the preamble (command part)
	CyU3PI2cPreamble_t preamble;

	preamble.buffer[0] = (uint8_t) (deviceAddress << 1); // Always a write, LSB=0, so shift by 1.

	if (isRead) {
		preamble.buffer[i2cIdConfigMap[deviceAddress]->addressLength + 1] = ((uint8_t) (deviceAddress << 1) | 0x01); // Read, LSB=1, enabled here
		preamble.length = (uint8_t) (i2cIdConfigMap[deviceAddress]->addressLength + 2); // Add the deviceAddress twice, second time to initiate the read
		preamble.ctrlMask = (uint16_t) (0x01 << i2cIdConfigMap[deviceAddress]->addressLength); // An extra START signal after the command (before the 2nd deviceAddress)
	}
	else {
		preamble.length = (uint8_t) (i2cIdConfigMap[deviceAddress]->addressLength + 1); // Add the deviceAddress byte
		preamble.ctrlMask = 0x0000; // No extra START signals
	}

	while (commandCount--) {
		// Update the address (the command is usually an address which gets bigger on multiple commands!)
		switch (i2cIdConfigMap[deviceAddress]->addressLength) {
			case 4:
				preamble.buffer[1] = (uint8_t) ((address >> 24) & 0xFF);
				preamble.buffer[2] = (uint8_t) ((address >> 16) & 0xFF);
				preamble.buffer[3] = (uint8_t) ((address >> 8) & 0xFF);
				preamble.buffer[4] = (uint8_t) (address & 0xFF);

				break;

			case 3:
				preamble.buffer[1] = (uint8_t) ((address >> 16) & 0xFF);
				preamble.buffer[2] = (uint8_t) ((address >> 8) & 0xFF);
				preamble.buffer[3] = (uint8_t) (address & 0xFF);

				break;

			case 2:
				preamble.buffer[1] = (uint8_t) ((address >> 8) & 0xFF);
				preamble.buffer[2] = (uint8_t) (address & 0xFF);

				break;

			case 1:
				preamble.buffer[1] = (uint8_t) (address & 0xFF);

				break;
		}

		if (isRead) {
			status = CyU3PI2cReceiveBytes(&preamble, data, commandDataLength, 0);
			if (status != CY_U3P_SUCCESS) {
				if (status == CY_U3P_ERROR_FAILURE) {
					// ERROR_FAILURE is special and means you can get a more precise error from the API.
					CyU3PI2cError_t error;
					CyU3PI2cGetErrorCode(&error);
					CyFxErrorHandler(LOG_ERROR, "CyFxI2cTransfer.ReceiveBytes() failure", error);
				}

				return (status);
			}
		}
		else {
			status = CyU3PI2cTransmitBytes(&preamble, data, commandDataLength, 0);
			if (status != CY_U3P_SUCCESS) {
				if (status == CY_U3P_ERROR_FAILURE) {
					// ERROR_FAILURE is special and means you can get a more precise error from the API.
					CyU3PI2cError_t error;
					CyU3PI2cGetErrorCode(&error);
					CyFxErrorHandler(LOG_ERROR, "CyFxI2cTransfer.TransmitBytes() failure", error);
				}

				return (status);
			}

			// Wait until the device is ready again after every write operation
			preamble.length = 1;

			status = CyU3PI2cWaitForAck(&preamble, 200);
			if (status != CY_U3P_SUCCESS) {
				if (status == CY_U3P_ERROR_FAILURE) {
					// ERROR_FAILURE is special and means you can get a more precise error from the API.
					CyU3PI2cError_t error;
					CyU3PI2cGetErrorCode(&error);
					CyFxErrorHandler(LOG_ERROR, "CyFxI2cTransfer.WaitForAck() failure", error);
				}

				return (status);
			}

			preamble.length = (uint8_t) (i2cIdConfigMap[deviceAddress]->addressLength + 1); // Reset to original value for writes
		}

		// An additional delay seems to be required, after receiving an ACK
		CyU3PThreadSleep(1); // TODO: test this!

		// Update the counters
		address += commandDataLength;
		data += commandDataLength;
		dataLength = (uint16_t) (dataLength - commandDataLength);
		commandDataLength =
			(dataLength >= i2cIdConfigMap[deviceAddress]->pageSize) ?
				(i2cIdConfigMap[deviceAddress]->pageSize) : (dataLength);
	}

	return (status);
}

CyBool_t CyFxHandleCustomVR_I2C(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	switch (FX3_REQ_DIR(bRequest, bDirection)) {
		case FX3_REQ_DIR(VR_I2C_CONFIG, FX3_USB_DIRECTION_IN):
			if (wLength != 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_CONFIG: no payload allowed", status);
				break;
			}

			status = CyFxI2cTransferConfig((uint8_t) (wValue & 0xFF), (uint8_t) ((wValue >> 8) & 0xFF), wIndex);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_CONFIG: configuration error", status);
				break;
			}

			CyU3PUsbAckSetup();

			break;

		case FX3_REQ_DIR(VR_I2C_TRANSFER, FX3_USB_DIRECTION_OUT):
			if (wLength == 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_TRANSFER READ: zero byte transfer invalid", status);
				break;
			}

			status = CyFxI2cTransfer(currentI2cDeviceAddress, (((uint32_t) wValue << 16) | wIndex), glEP0Buffer,
				wLength, I2C_READ);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_TRANSFER READ: transfer error", status);
				break;
			}

			status = CyU3PUsbSendEP0Data(wLength, glEP0Buffer);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_TRANSFER READ: CyU3PUsbSendEP0Data failed", status);
				break;
			}

			break;

		case FX3_REQ_DIR(VR_I2C_TRANSFER, FX3_USB_DIRECTION_IN):
			if (wLength == 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_TRANSFER WRITE: zero byte transfer invalid", status);
				break;
			}

			status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_TRANSFER WRITE: CyU3PUsbGetEP0Data failed", status);
				break;
			}

			status = CyFxI2cTransfer(currentI2cDeviceAddress, (((uint32_t) wValue << 16) | wIndex), glEP0Buffer,
				wLength, I2C_WRITE);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_I2C_TRANSFER WRITE: transfer error", status);
				break;
			}

			break;

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
