#include "cyu3spi.h"
#include "cyu3gpio.h"
#include "gpio_regs.h"
#include "fx3.h"
#include "spi_support.h"
#include "gpio_support.h"

// Common SPI Flash commands
#define READ_CMD (const uint8_t) { 0x03 }
#define READ_STATUS_CMD (const uint8_t) { 0x05 }
#define WRITE_CMD (const uint8_t) { 0x02 }
#define WRITE_ENABLE_CMD (const uint8_t) { 0x06 }
#define ERASE_BLOCK64K_CMD (const uint8_t) { 0xD8 }

// Define GPIOs for SPI emulation (32-bit mode).
#define GPIO_SCK 53
#define GPIO_SSN 54
#define GPIO_MISO 55
#define GPIO_MOSI 56

// Map for fast configuration lookup (the highest address possible is GPIO 57).
static spiConfig_DeviceSpecific_Type *spiIdConfigMap[GPIO_MAX_IDENTIFIER] = { NULL }; // NULL is always an invalid pointer.

// Address of device currently used via USB VRs.
static uint8_t currentSpiDeviceAddress = 0; // Device 0, the default device, always exists.

// Currently saved command from USB requests.
static uint8_t currentSpiCommand[255] = { 0 };
static uint8_t currentSpiCommandLength = 0;

#if GPIF_32BIT_SUPPORT_ENABLED == 0
// Current configuration for the SPI block, to allow frequency adjustments as needed.
static CyU3PSpiConfig_t currentSpiConfig;

static uint32_t CyFxSpiClockValueForDevice(uint8_t deviceAddress) {
	uint32_t clockValue = SPI_MAX_CLOCK;

	// If the maxFrequency is lower than what the SPI block supports, use the smaller value.
	if (spiIdConfigMap[deviceAddress] != NULL && spiIdConfigMap[deviceAddress]->maxFrequency < SPI_MAX_CLOCK) {
		clockValue = spiIdConfigMap[deviceAddress]->maxFrequency;
	}

	return (clockValue);
}
#endif

static int CyFxSpiConfigComparator_SPICONFIG_DEVICESPECIFIC_TYPE(const void *a, const void *b) {
	const spiConfig_DeviceSpecific_Type *aa = a;
	const spiConfig_DeviceSpecific_Type *bb = b;

	if (aa->deviceAddress > bb->deviceAddress) {
		return (1); // Greater than
	}

	if (aa->deviceAddress < bb->deviceAddress) {
		return (-1); // Less than
	}

	return (0); // Equal
}

CyU3PReturnStatus_t CyFxSpiConfigParse(uint32_t *gpioSimpleEn0, uint32_t *gpioSimpleEn1) {
	// Enabling the SPI block without any devices defined? Nope!
	if (spiConfig_DeviceSpecific_Length == 0) {
		return (CY_U3P_ERROR_NOT_CONFIGURED);
	}

	// Make sure spiConfig is sorted for duplicate ID detection.
	qsort(spiConfig_DeviceSpecific, spiConfig_DeviceSpecific_Length, sizeof(spiConfig_DeviceSpecific_Type),
		&CyFxSpiConfigComparator_SPICONFIG_DEVICESPECIFIC_TYPE);

	// Detect duplicates (which of course are forbidden!) (NOTE: there can be none if only one is used!)
	if (spiConfig_DeviceSpecific_Length > 1) {
		for (size_t i = 1; i < spiConfig_DeviceSpecific_Length; i++) {
			if (!CyFxSpiConfigComparator_SPICONFIG_DEVICESPECIFIC_TYPE(&spiConfig_DeviceSpecific[i],
				&spiConfig_DeviceSpecific[i - 1])) {
				return (CY_U3P_ERROR_INVALID_CONFIGURATION);
			}
		}
	}

	// A default device shall always exist, else we're wasting a precious GPIO port!
	if (spiConfig_DeviceSpecific[0].deviceAddress != 0) {
		return (CY_U3P_ERROR_INVALID_SEQUENCE);
	}

	for (size_t i = 0; i < spiConfig_DeviceSpecific_Length; i++) {
		const uint8_t devAddr = spiConfig_DeviceSpecific[i].deviceAddress;

		// Address 0 is special, as the default SS0 line, it is always okay, so we don't check it or enable it separately.
		if (devAddr != 0) {
			// Verify deviceAddress (GPIO) validity.
			if (!CyFxGpioVerifyId(devAddr)) {
				return (CY_U3P_ERROR_BAD_INDEX);
			}

			// Check that it was not used by another interface before SPI.
			if ((devAddr < 32 && ((*gpioSimpleEn0) & ((uint32_t) 1 << devAddr)))
				|| ((*gpioSimpleEn1) & ((uint32_t) 1 << (devAddr - 32)))) {
				return (CY_U3P_ERROR_ALREADY_STARTED);
			}

			// gpioSimpleEn is used by IOMatrix and contains all valid GPIOs.
			if (devAddr < 32) {
				(*gpioSimpleEn0) |= ((uint32_t) 1 << devAddr);
			}
			else {
				(*gpioSimpleEn1) |= ((uint32_t) 1 << (devAddr - 32));
			}
		}

		// Check address length and page size maximum values.
		if (spiConfig_DeviceSpecific[i].addressLength > 4) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		if (spiConfig_DeviceSpecific[i].pageSize > FX3_MAX_TRANSFER_SIZE_CONTROL) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		// Make sure the pageSize is either 0 or a power of two.
		if ((spiConfig_DeviceSpecific[i].pageSize != 0)
			&& (spiConfig_DeviceSpecific[i].pageSize & (spiConfig_DeviceSpecific[i].pageSize - 1))) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		// Verify that maxFrequency is never 0.
		if (spiConfig_DeviceSpecific[i].maxFrequency == 0) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		// Update direct map for fast lookup of device configuration based on address.
		spiIdConfigMap[devAddr] = &spiConfig_DeviceSpecific[i];
	}

#if GPIF_32BIT_SUPPORT_ENABLED == 1
	// When 32bit support is enabled, we must emulate SPI with normal GPIOs.
	// So we enable those four GPIOs (53, 54, 55, 56) here (for IOMatrix).
	(*gpioSimpleEn1) |= ((uint32_t) 1 << (GPIO_SCK - 32));
	(*gpioSimpleEn1) |= ((uint32_t) 1 << (GPIO_SSN - 32));
	(*gpioSimpleEn1) |= ((uint32_t) 1 << (GPIO_MISO - 32));
	(*gpioSimpleEn1) |= ((uint32_t) 1 << (GPIO_MOSI - 32));
#endif

	return (CY_U3P_SUCCESS);
}

CyU3PReturnStatus_t CyFxSpiInit(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

#if GPIF_32BIT_SUPPORT_ENABLED == 0
	// Initialize and configure the SPI master module.
	status = CyU3PSpiInit();
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// Start the SPI master block and set the parameters for the default device (devAddr 0).
	currentSpiConfig.isLsbFirst = CyFalse;
	currentSpiConfig.cpol = CyFalse; // Clock Polarity 0 and Clock Phase 0 are called SPI Mode 0 (0, 0).
	currentSpiConfig.cpha = CyFalse; // Another option is SPI Mode 3 (1, 1), setting both to 1.
	currentSpiConfig.ssnPol = spiConfig_DeviceSpecific[0].SSPolarity; // Default SS0 polarity
	currentSpiConfig.ssnCtrl = CY_U3P_SPI_SSN_CTRL_FW; // SS0 controlled by firmware
	currentSpiConfig.leadTime = CY_U3P_SPI_SSN_LAG_LEAD_HALF_CLK;
	currentSpiConfig.lagTime = CY_U3P_SPI_SSN_LAG_LEAD_HALF_CLK;
	currentSpiConfig.clock = CyFxSpiClockValueForDevice(0);
	currentSpiConfig.wordLen = 8; // 8 bits = 1 byte word-length

	status = CyU3PSpiSetConfig(&currentSpiConfig, NULL);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// SerialIO contains SPI, I2S and UART blocks. We don't support I2S and UART, so we use this
	// to set the SPI drive strength only.
	status = CyU3PSetSerialIoDriveStrength(FX3_DRIVE_STRENGTH_SPI);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}
#else
	// In 32-bit mode, the SPI block is unavailable. We have to emulate it with GPIOs manually.

	// First verify that the GPIO block itself is enabled. It can be disabled, as GPIO_SUPPORT_ENABLED == 0 and
	// SPI_SUPPORT_ENABLED == 1 is a perfectly valid configuration, so we might need to initialize it ourselves.
#if GPIO_SUPPORT_ENABLED == 0
	// Initialize the minimal GPIO module.
	status = CyFxGpioInit();
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}
#endif

	// Now that we know GPIO works, we can configure the needed SPI emulation lines.
	CyU3PGpioSimpleConfig_t gpioSimpleConfigSPI;

	// SPI SCK (output).
	gpioSimpleConfigSPI.outValue = CyFalse;
	gpioSimpleConfigSPI.driveLowEn = CyTrue;
	gpioSimpleConfigSPI.driveHighEn = CyTrue;
	gpioSimpleConfigSPI.inputEn = CyFalse;
	gpioSimpleConfigSPI.intrMode = CY_U3P_GPIO_NO_INTR;

	status = CyU3PGpioSetSimpleConfig(GPIO_SCK, &gpioSimpleConfigSPI);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// SPI SSN (output).
	gpioSimpleConfigSPI.outValue = (spiConfig_DeviceSpecific[0].SSPolarity) ? (CyFalse) : (CyTrue);
	gpioSimpleConfigSPI.driveLowEn = CyTrue;
	gpioSimpleConfigSPI.driveHighEn = CyTrue;
	gpioSimpleConfigSPI.inputEn = CyFalse;
	gpioSimpleConfigSPI.intrMode = CY_U3P_GPIO_NO_INTR;

	status = CyU3PGpioSetSimpleConfig(GPIO_SSN, &gpioSimpleConfigSPI);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// SPI MISO (input).
	gpioSimpleConfigSPI.outValue = CyFalse;
	gpioSimpleConfigSPI.driveLowEn = CyFalse;
	gpioSimpleConfigSPI.driveHighEn = CyFalse;
	gpioSimpleConfigSPI.inputEn = CyTrue;
	gpioSimpleConfigSPI.intrMode = CY_U3P_GPIO_NO_INTR;

	status = CyU3PGpioSetSimpleConfig(GPIO_MISO, &gpioSimpleConfigSPI);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// SPI MOSI (output).
	gpioSimpleConfigSPI.outValue = CyFalse;
	gpioSimpleConfigSPI.driveLowEn = CyTrue;
	gpioSimpleConfigSPI.driveHighEn = CyTrue;
	gpioSimpleConfigSPI.inputEn = CyFalse;
	gpioSimpleConfigSPI.intrMode = CY_U3P_GPIO_NO_INTR;

	status = CyU3PGpioSetSimpleConfig(GPIO_MOSI, &gpioSimpleConfigSPI);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}
#endif

	// If more than one device (the default one) is present, let's initialize its SS line.
	if (spiConfig_DeviceSpecific_Length > 1) {
		// First verify that the GPIO block itself is enabled. It can be disabled, as GPIO_SUPPORT_ENABLED == 0 and
		// SPI_SUPPORT_ENABLED == 1 is a perfectly valid configuration, so we might need to initialize it ourselves.
		// In 32-bit mode, this was already done above in the initialization code for SPI emulation.
#if GPIO_SUPPORT_ENABLED == 0 && GPIF_32BIT_SUPPORT_ENABLED == 0
		// Initialize the minimal GPIO module.
		status = CyFxGpioInit();
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}
#endif

		// Now that we know GPIO works, we can configure the needed SS lines (simple GPIOs).
		CyU3PGpioSimpleConfig_t gpioSimpleConfigSSN;

		for (size_t i = 1; i < spiConfig_DeviceSpecific_Length; i++) {
			// Output configuration, since SS lines are always outputs.
			gpioSimpleConfigSSN.outValue = (spiConfig_DeviceSpecific[i].SSPolarity) ? (CyFalse) : (CyTrue); // Default to OFF.
			gpioSimpleConfigSSN.driveLowEn = CyTrue;
			gpioSimpleConfigSSN.driveHighEn = CyTrue;
			gpioSimpleConfigSSN.inputEn = CyFalse;
			gpioSimpleConfigSSN.intrMode = CY_U3P_GPIO_NO_INTR;

			status = CyU3PGpioSetSimpleConfig(spiConfig_DeviceSpecific[i].deviceAddress, &gpioSimpleConfigSSN);
			if (status != CY_U3P_SUCCESS) {
				return (status);
			}
		}
	}

	return (status);
}

static CyU3PReturnStatus_t CyFxSpiTransferConfig(uint8_t deviceAddress, uint8_t addressLength, uint16_t pageSize,
	const uint8_t *cmd, uint8_t cmdLength) {
	// Check for invalid input values.
	if ((deviceAddress >= GPIO_MAX_IDENTIFIER) || (spiIdConfigMap[deviceAddress] == NULL) || (addressLength > 4)
		|| (pageSize > FX3_MAX_TRANSFER_SIZE_CONTROL) || ((pageSize != 0) && (pageSize & (pageSize - 1)))
		|| ((cmdLength == 0) && (cmd != NULL)) || ((cmdLength != 0) && (cmd == NULL))) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// Update current device configuration for subsequent transfers.
	if (addressLength != 0) {
		spiIdConfigMap[deviceAddress]->addressLength = addressLength;
	}

	if (pageSize != 0) {
		spiIdConfigMap[deviceAddress]->pageSize = pageSize;
	}

	// Update command to execute for subsequent USB command requests.
	if (cmd != NULL) {
		memcpy(currentSpiCommand, cmd, cmdLength);
	}
	currentSpiCommandLength = cmdLength;

	// Update device address for subsequent USB requests.
	currentSpiDeviceAddress = deviceAddress;

	// Update SPI block clock setting for maximum performance.
	CyU3PReturnStatus_t status = CyFxSpiClockUpdateForDevice(deviceAddress);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	return (CY_U3P_SUCCESS);
}

CyU3PReturnStatus_t CyFxSpiClockUpdateForDevice(uint8_t deviceAddress) {
#if GPIF_32BIT_SUPPORT_ENABLED == 1
	(void) deviceAddress; // UNUSED
#else
	// Update SPI block clock setting for maximum performance.
	currentSpiConfig.clock = CyFxSpiClockValueForDevice(deviceAddress);

	CyU3PReturnStatus_t status = CyU3PSpiSetConfig(&currentSpiConfig, NULL);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}
#endif

	return (CY_U3P_SUCCESS);
}

// Abstract SPI functions to easier be able to emulate them.
static inline CyU3PReturnStatus_t CyFxSpiSetSsnLine(CyBool_t isHigh) {
#if GPIF_32BIT_SUPPORT_ENABLED == 0
	// The default device SS line is controlled via special firmware API.
	return (CyU3PSpiSetSsnLine(isHigh));
#else
	// In 32-bit mode, we toggle the default SS line manually.
	// Using direct register access for performance.
	uvint32_t *regPtrSSN = &GPIO->lpp_gpio_simple[GPIO_SSN];

	if (isHigh) {
		*regPtrSSN |= CY_U3P_LPP_GPIO_OUT_VALUE;
	}
	else {
		*regPtrSSN &= ~CY_U3P_LPP_GPIO_OUT_VALUE;
	}

	return (CY_U3P_SUCCESS);
#endif
}

static inline CyU3PReturnStatus_t CyFxSpiTransmitWords(uint8_t *data, uint32_t byteCount) {
#if GPIF_32BIT_SUPPORT_ENABLED == 0
	return (CyU3PSpiTransmitWords(data, byteCount));
#else
	// Using direct register access for performance.
	uvint32_t *regPtrSCK = &GPIO->lpp_gpio_simple[GPIO_SCK];
	uvint32_t *regPtrMOSI = &GPIO->lpp_gpio_simple[GPIO_MOSI];

	// Disable clock.
	*regPtrSCK &= ~CY_U3P_LPP_GPIO_OUT_VALUE;

	for (uint32_t byteIndex = 0; byteIndex < byteCount; byteIndex++) {
		// Assign value from data array.
		uint8_t byte = data[byteIndex];

		// Step through the eight bits of the given byte, starting at the highest
		// (MSB) and going down to the lowest (LSB).
		for (size_t i = 0; i < 8; i++) {
			// Set the current bit value, based on the highest bit.
			if (byte & 0x80) {
				*regPtrMOSI |= CY_U3P_LPP_GPIO_OUT_VALUE;
			}
			else {
				*regPtrMOSI &= ~CY_U3P_LPP_GPIO_OUT_VALUE;
			}

			// Pulse clock to signal value is ready to be read.
			*regPtrSCK |= CY_U3P_LPP_GPIO_OUT_VALUE;
			*regPtrSCK &= ~CY_U3P_LPP_GPIO_OUT_VALUE;

			// Shift left by one, making the second highest bit the highest.
			byte = (uint8_t) (byte << 1);
		}
	}

	return (CY_U3P_SUCCESS);
#endif
}

static inline CyU3PReturnStatus_t CyFxSpiReceiveWords(uint8_t *data, uint32_t byteCount) {
#if GPIF_32BIT_SUPPORT_ENABLED == 0
	return (CyU3PSpiReceiveWords(data, byteCount));
#else
	// Using direct register access for performance.
	uvint32_t *regPtrSCK = &GPIO->lpp_gpio_simple[GPIO_SCK];
	uvint32_t *regPtrMISO = &GPIO->lpp_gpio_simple[GPIO_MISO];
	CyBool_t gpioIsHigh = CyFalse;

	// Disable clock.
	*regPtrSCK &= ~CY_U3P_LPP_GPIO_OUT_VALUE;

	for (uint32_t byteIndex = 0; byteIndex < byteCount; byteIndex++) {
		uint8_t byte = 0;

		for (size_t i = 0; i < 8; i++) {
			// Pulse clock to signal slave to output new value.
			*regPtrSCK |= CY_U3P_LPP_GPIO_OUT_VALUE;

			// Get the current bit value, based on the GPIO value.
			gpioIsHigh = (CyBool_t) ((*regPtrMISO & CY_U3P_LPP_GPIO_IN_VALUE) >> 1);

			if (gpioIsHigh) {
				byte |= 1;
			}
			else {
				byte |= 0;
			}

			*regPtrSCK &= ~CY_U3P_LPP_GPIO_OUT_VALUE;

			// Shift left by one, progressively moving the first set bit to be the MSB.
			if (i != 7) {
				byte = (uint8_t) (byte << 1);
			}
		}

		// Assign value to data array.
		data[byteIndex] = byte;
	}

	return (CY_U3P_SUCCESS);
#endif
}

void CyFxSpiSSLineAssert(uint8_t deviceAddress) {
	if (deviceAddress == 0) {
		// The default device SS line is controlled via special call.
		CyFxSpiSetSsnLine((spiIdConfigMap[0]->SSPolarity) ? (CyTrue) : (CyFalse));
	}
	else {
		// All other devices are normal, simple GPIOs.
		// Using direct register access for performance.
		uvint32_t *regPtrSS = &GPIO->lpp_gpio_simple[deviceAddress];

		if (spiIdConfigMap[deviceAddress]->SSPolarity) {
			*regPtrSS |= CY_U3P_LPP_GPIO_OUT_VALUE;
		}
		else {
			*regPtrSS &= ~CY_U3P_LPP_GPIO_OUT_VALUE;
		}
	}
}

void CyFxSpiSSLineDeassert(uint8_t deviceAddress) {
	if (deviceAddress == 0) {
		// The default device SS line is controlled via special call.
		CyFxSpiSetSsnLine((spiIdConfigMap[0]->SSPolarity) ? (CyFalse) : (CyTrue));
	}
	else {
		// All other devices are normal, simple GPIOs.
		// Using direct register access for performance.
		uvint32_t *regPtrSS = &GPIO->lpp_gpio_simple[deviceAddress];

		if (!spiIdConfigMap[deviceAddress]->SSPolarity) {
			*regPtrSS |= CY_U3P_LPP_GPIO_OUT_VALUE;
		}
		else {
			*regPtrSS &= ~CY_U3P_LPP_GPIO_OUT_VALUE;
		}
	}
}

// If data == NULL && dataLength == 0, then just transmit the command and don't do anything else.
// Also, if cmd == NULL && cmdLength == 0, just transmit the data without a command before it.
CyU3PReturnStatus_t CyFxSpiCommand(uint8_t deviceAddress, const uint8_t *cmd, uint8_t cmdLength, uint8_t *data,
	uint16_t dataLength, CyBool_t isRead, uint8_t controlFlags) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Verify the device address for later lookups.
	if ((deviceAddress >= GPIO_MAX_IDENTIFIER) || (spiIdConfigMap[deviceAddress] == NULL)) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// Check for invalid input values
	if (((cmdLength == 0) && (cmd != NULL)) || ((cmdLength != 0) && (cmd == NULL))
		|| ((dataLength == 0) && (data != NULL)) || ((dataLength != 0) && (data == NULL))
		|| ((cmd == NULL) && (data == NULL)) || ((isRead == SPI_READ) && (data == NULL))) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	if (!(controlFlags & SPI_NO_ASSERT)) {
		CyFxSpiSSLineAssert(deviceAddress);
	}

	if (cmd != NULL) {
		status = CyFxSpiTransmitWords((uint8_t *) cmd, cmdLength);
		if (status != CY_U3P_SUCCESS) {
			CyFxSpiSSLineDeassert(deviceAddress);
			return (status);
		}
	}

	if (data != NULL) {
		if (isRead) {
			status = CyFxSpiReceiveWords(data, dataLength);
		}
		else {
			status = CyFxSpiTransmitWords(data, dataLength);
		}

		if (status != CY_U3P_SUCCESS) {
			CyFxSpiSSLineDeassert(deviceAddress);
			return (status);
		}
	}

	if (!(controlFlags & SPI_NO_DEASSERT)) {
		CyFxSpiSSLineDeassert(deviceAddress);
	}

	return (status);
}

// 'data' must be defined, and 'dataLenght' cannot be zero! Calling this without the
// intention of doing a transfer makes no sense.
CyU3PReturnStatus_t CyFxSpiTransfer(uint8_t deviceAddress, uint32_t address, uint8_t *data, uint16_t dataLength,
	CyBool_t isRead) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Verify the device address for later lookups.
	if ((deviceAddress >= GPIO_MAX_IDENTIFIER) || (spiIdConfigMap[deviceAddress] == NULL)) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// When using the standard transfer function, address length, page size and device size MUST be defined!
	if ((spiIdConfigMap[deviceAddress]->addressLength == 0) || (spiIdConfigMap[deviceAddress]->pageSize == 0)
		|| (spiIdConfigMap[deviceAddress]->deviceSize == 0)) {
		return (CY_U3P_ERROR_INVALID_CONFIGURATION);
	}

	// Check for invalid input values, especially command can't have any bits set above its command length
	if (((spiIdConfigMap[deviceAddress]->addressLength != 4)
		&& (address >= ((uint32_t) 0x01 << (spiIdConfigMap[deviceAddress]->addressLength * 8)))) || (data == NULL)
		|| (dataLength == 0) || (dataLength > spiIdConfigMap[deviceAddress]->deviceSize)
		|| (address > (spiIdConfigMap[deviceAddress]->deviceSize - dataLength))) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	uint16_t commandCount, commandDataLength;

	// Is the address page-aligned or in the middle of one?
	if (address & (uint16_t) (spiIdConfigMap[deviceAddress]->pageSize - 1)) {
		// NOT ALIGNED TO PAGE

		// Find out how much bytes we can still write in the same page, based on the start address
		const uint16_t dataInPage = (uint16_t) (spiIdConfigMap[deviceAddress]->pageSize
			- (uint16_t) (address & (uint16_t) (spiIdConfigMap[deviceAddress]->pageSize - 1)));

		// Now calculate how many times to call the command and how much data to pass the first time based on it
		commandDataLength = (dataLength >= dataInPage) ? (dataInPage) : (dataLength);
		commandCount = (uint16_t) (((uint16_t) (dataLength - commandDataLength)
			/ spiIdConfigMap[deviceAddress]->pageSize) + 1); // + 1: the first call

		// Check if there is outstanding data in the transfer, in which case we need to send the command once more
		if (((dataLength - commandDataLength) % spiIdConfigMap[deviceAddress]->pageSize) != 0) {
			commandCount++;
		}
	}
	else {
		// ALIGNED TO PAGE

		// Calculate how many times to call the command and how much data to pass the first time
		commandDataLength =
			(dataLength >= spiIdConfigMap[deviceAddress]->pageSize) ?
				(spiIdConfigMap[deviceAddress]->pageSize) : (dataLength);
		commandCount = (dataLength / spiIdConfigMap[deviceAddress]->pageSize);

		// Check if there is outstanding data in the transfer, in which case we need to send the command once more
		if ((dataLength % spiIdConfigMap[deviceAddress]->pageSize) != 0) {
			commandCount++;
		}
	}

	// Create the command part
	const uint8_t cmdLength = (uint8_t) (spiIdConfigMap[deviceAddress]->addressLength + 1); // Plus one for the command itself
	uint8_t cmd[cmdLength];

	if (isRead) {
		cmd[0] = READ_CMD;
	}
	else {
		cmd[0] = WRITE_CMD;
	}

	while (commandCount--) {
		// Update the address (the command is usually an address which gets bigger on multiple commands!)
		switch (spiIdConfigMap[deviceAddress]->addressLength) {
			case 4:
				cmd[1] = (uint8_t) ((address >> 24) & 0xFF);
				cmd[2] = (uint8_t) ((address >> 16) & 0xFF);
				cmd[3] = (uint8_t) ((address >> 8) & 0xFF);
				cmd[4] = (uint8_t) (address & 0xFF);

				break;

			case 3:
				cmd[1] = (uint8_t) ((address >> 16) & 0xFF);
				cmd[2] = (uint8_t) ((address >> 8) & 0xFF);
				cmd[3] = (uint8_t) (address & 0xFF);

				break;

			case 2:
				cmd[1] = (uint8_t) ((address >> 8) & 0xFF);
				cmd[2] = (uint8_t) (address & 0xFF);

				break;

			case 1:
				cmd[1] = (uint8_t) (address & 0xFF);

				break;
		}

		if (isRead) {
			status = CyFxSpiCommand(deviceAddress, cmd, cmdLength, data, commandDataLength, SPI_READ,
			SPI_ASSERT | SPI_DEASSERT);
			if (status != CY_U3P_SUCCESS) {
				return (status);
			}
		}
		else {
			// Send Write Enable before every write operation
			status = CyFxSpiCommand(deviceAddress, &WRITE_ENABLE_CMD, 1, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
			if (status != CY_U3P_SUCCESS) {
				return (status);
			}

			status = CyFxSpiCommand(deviceAddress, cmd, cmdLength, data, commandDataLength, SPI_WRITE,
			SPI_ASSERT | SPI_DEASSERT);
			if (status != CY_U3P_SUCCESS) {
				return (status);
			}

			// Wait until the device is ready again after every write operation
			uint8_t buf;

			do {
				status = CyFxSpiCommand(deviceAddress, &READ_STATUS_CMD, 1, &buf, 1, SPI_READ,
				SPI_ASSERT | SPI_DEASSERT);
				if (status != CY_U3P_SUCCESS) {
					return (status);
				}
			}
			while (buf & 0x01); // Wait until BUSY bit is false.
		}

		// Update the counters
		address += commandDataLength;
		data += commandDataLength;
		dataLength = (uint16_t) (dataLength - commandDataLength);
		commandDataLength =
			(dataLength >= spiIdConfigMap[deviceAddress]->pageSize) ?
				(spiIdConfigMap[deviceAddress]->pageSize) : (dataLength);
	}

	return (status);
}

// Erase SPI flash blocks of 64KBytes.
CyU3PReturnStatus_t CyFxSpiEraseBlock(uint8_t deviceAddress, uint32_t address) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Verify the device address for later lookups.
	if ((deviceAddress >= GPIO_MAX_IDENTIFIER) || (spiIdConfigMap[deviceAddress] == NULL)) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// When using the standard erase function, address length and device size MUST be defined!
	if ((spiIdConfigMap[deviceAddress]->addressLength == 0) || (spiIdConfigMap[deviceAddress]->deviceSize == 0)) {
		return (CY_U3P_ERROR_INVALID_CONFIGURATION);
	}

	// Check for invalid input values, especially command can't have any bits set above its command length.
	if (((spiIdConfigMap[deviceAddress]->addressLength != 4)
		&& (address >= ((uint32_t) 0x01 << (spiIdConfigMap[deviceAddress]->addressLength * 8))))
		|| (address >= spiIdConfigMap[deviceAddress]->deviceSize)) {
		return (CY_U3P_ERROR_BAD_ARGUMENT);
	}

	// Create the command part
	const uint8_t cmdLength = (uint8_t) (spiIdConfigMap[deviceAddress]->addressLength + 1); // Plus one for the command itself
	uint8_t cmd[cmdLength];

	cmd[0] = ERASE_BLOCK64K_CMD;

	// Update the address (the command is usually an address which gets bigger on multiple commands!)
	switch (spiIdConfigMap[deviceAddress]->addressLength) {
		case 4:
			cmd[1] = (uint8_t) ((address >> 24) & 0xFF);
			cmd[2] = (uint8_t) ((address >> 16) & 0xFF);
			cmd[3] = (uint8_t) ((address >> 8) & 0xFF);
			cmd[4] = (uint8_t) (address & 0xFF);

			break;

		case 3:
			cmd[1] = (uint8_t) ((address >> 16) & 0xFF);
			cmd[2] = (uint8_t) ((address >> 8) & 0xFF);
			cmd[3] = (uint8_t) (address & 0xFF);

			break;

		case 2:
			cmd[1] = (uint8_t) ((address >> 8) & 0xFF);
			cmd[2] = (uint8_t) (address & 0xFF);

			break;

		case 1:
			cmd[1] = (uint8_t) (address & 0xFF);

			break;
	}

	// Send Write Enable before every erase operation
	status = CyFxSpiCommand(deviceAddress, &WRITE_ENABLE_CMD, 1, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	status = CyFxSpiCommand(deviceAddress, cmd, cmdLength, NULL, 0, SPI_WRITE, SPI_ASSERT | SPI_DEASSERT);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// Wait until the device is ready again after every erase operation
	uint8_t buf;

	do {
		status = CyFxSpiCommand(deviceAddress, &READ_STATUS_CMD, 1, &buf, 1, SPI_READ, SPI_ASSERT | SPI_DEASSERT);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}
	}
	while (buf & 0x01); // Wait until BUSY bit is false.

	return (status);
}

CyBool_t CyFxHandleCustomVR_SPI(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	switch (FX3_REQ_DIR(bRequest, bDirection)) {
		case FX3_REQ_DIR(VR_SPI_CONFIG, FX3_USB_DIRECTION_IN):
			// Check maximum length first.
			if (wLength > 255) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_CONFIG: maximum command length (255) exceeded", status);
				break;
			}

			if (wLength != 0) {
				status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
				if (status != CY_U3P_SUCCESS) {
					CyFxErrorHandler(LOG_ERROR, "VR_SPI_CONFIG: CyU3PUsbGetEP0Data failed", status);
					break;
				}
			}
			else {
				CyU3PUsbAckSetup();
			}

			status = CyFxSpiTransferConfig((uint8_t) (wValue & 0xFF), (uint8_t) ((wValue >> 8) & 0xFF), wIndex,
				(wLength == 0) ? (NULL) : (glEP0Buffer), (uint8_t) wLength);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_CONFIG: configuration error", status);
				break;
			}

			break;

		case FX3_REQ_DIR(VR_SPI_CMD, FX3_USB_DIRECTION_OUT):
			status = CyFxSpiCommand(currentSpiDeviceAddress,
				((wIndex == 1) || (currentSpiCommandLength == 0)) ? (NULL) : (currentSpiCommand),
				(uint8_t) ((wIndex == 1) ? (0) : (currentSpiCommandLength)), (wLength == 0) ? (NULL) : (glEP0Buffer),
				wLength, SPI_READ, (uint8_t) wValue);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_CMD READ: transfer error", status);
				break;
			}

			if (wLength != 0) {
				status = CyU3PUsbSendEP0Data(wLength, glEP0Buffer);
				if (status != CY_U3P_SUCCESS) {
					CyFxErrorHandler(LOG_ERROR, "VR_SPI_CMD READ: CyU3PUsbSendEP0Data failed", status);
					break;
				}
			}
			else {
				CyU3PUsbAckSetup();
			}

			break;

		case FX3_REQ_DIR(VR_SPI_CMD, FX3_USB_DIRECTION_IN):
			if (wLength != 0) {
				status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
				if (status != CY_U3P_SUCCESS) {
					CyFxErrorHandler(LOG_ERROR, "VR_SPI_CMD WRITE: CyU3PUsbGetEP0Data failed", status);
					break;
				}
			}
			else {
				CyU3PUsbAckSetup();
			}

			status = CyFxSpiCommand(currentSpiDeviceAddress,
				((wIndex == 1) || (currentSpiCommandLength == 0)) ? (NULL) : (currentSpiCommand),
				(uint8_t) ((wIndex == 1) ? (0) : (currentSpiCommandLength)), (wLength == 0) ? (NULL) : (glEP0Buffer),
				wLength, SPI_WRITE, (uint8_t) wValue);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_CMD WRITE: transfer error", status);
				break;
			}

			break;

		case FX3_REQ_DIR(VR_SPI_TRANSFER, FX3_USB_DIRECTION_OUT):
			if (wLength == 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_TRANSFER READ: zero byte transfer invalid", status);
				break;
			}

			status = CyFxSpiTransfer(currentSpiDeviceAddress, (((uint32_t) wValue << 16) | wIndex), glEP0Buffer,
				wLength, SPI_READ);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_TRANSFER READ: transfer error", status);
				break;
			}

			status = CyU3PUsbSendEP0Data(wLength, glEP0Buffer);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_TRANSFER READ: CyU3PUsbSendEP0Data failed", status);
				break;
			}

			break;

		case FX3_REQ_DIR(VR_SPI_TRANSFER, FX3_USB_DIRECTION_IN):
			if (wLength == 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_TRANSFER WRITE: zero byte transfer invalid", status);
				break;
			}

			status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_TRANSFER WRITE: CyU3PUsbGetEP0Data failed", status);
				break;
			}

			status = CyFxSpiTransfer(currentSpiDeviceAddress, (((uint32_t) wValue << 16) | wIndex), glEP0Buffer,
				wLength, SPI_WRITE);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_TRANSFER WRITE: transfer error", status);
				break;
			}

			break;

		case FX3_REQ_DIR(VR_SPI_ERASE, FX3_USB_DIRECTION_IN):
			if (wLength != 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_ERASE: no payload allowed", status);
				break;
			}

			status = CyFxSpiEraseBlock(currentSpiDeviceAddress, (((uint32_t) wValue << 16) | wIndex));
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SPI_ERASE: failed to erase block", status);
				break;
			}

			CyU3PUsbAckSetup();

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
