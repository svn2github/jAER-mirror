#include "cyu3gpio.h"
#include "fx3.h"
#include "gpio_support.h"
#include "heartbeat.h"

// Supported operations on GPIOs
enum gpioOperations {
	OFF = 0,
	ON,
	TOGGLE,
	TIMED,
	RECURRING,
};

#if GPIF_32BIT_SUPPORT_ENABLED == 0
#if SPI_SUPPORT_ENABLED == 1
static const uint8_t gpioValidIds[] = { 26, 27, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
	51, 52, 57 };
#else
static const uint8_t gpioValidIds[] = {26, 27, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
#endif
#else
// No SPI available on 32-bit!
static const uint8_t gpioValidIds[] = {26, 27, 45, 50, 51, 52, 53, 54, 55, 56, 57};
#endif

static const uint8_t gpioValidTypes[] = { 'O', 'I', 'P', 'N', 'B', 'L', 'H' }; // Possible types always in upper-case!
// No gpioOverride's are needed according to Cypress documentation, since the two CTRL lines (26, 27) that we
// don't use for GPIF2 and can thus use as GPIO aren't blocked, and simply need to be enabled to work as expected.

// Maximum number of GPIOs that can be configured as interrupt-types (we have at most 27 configurable pins)
#define GPIO_MAX_INTERRUPT_SLOTS (24)

static uint8_t gpioInterruptSlotIdMap[GPIO_MAX_INTERRUPT_SLOTS] = { 0xFF }; // 0xFF is never used as valid GPIO ID, as the maximum is 60
static uint8_t gpioInterruptIdSlotMap[GPIO_MAX_IDENTIFIER] = { 0xFF }; // // 0xFF is never used as valid slot number, as the maximum is 16
static uint8_t gpioIdTypeMap[GPIO_MAX_IDENTIFIER] = { 0xFF }; // 0xFF is never used as valid GPIO Type, as they are all ASCII letters

// General event flag for GPIO Interrupt Handling
static CyU3PEvent glEventFlagGPIO;

static int CyFxGpioConfigComparator_GPIOCONFIG_DEVICESPECIFIC_TYPE(const void *a, const void *b) {
	const gpioConfig_DeviceSpecific_Type *aa = a;
	const gpioConfig_DeviceSpecific_Type *bb = b;

	if (aa->gpioId > bb->gpioId) {
		return (1); // Greater than
	}

	if (aa->gpioId < bb->gpioId) {
		return (-1); // Less than
	}

	return (0); // Equal
}

static int CyFxGpioConfigComparator_UINT8_T(const void *a, const void *b) {
	const uint8_t *aa = a;
	const uint8_t *bb = b;

	if (*aa > *bb) {
		return (1); // Greater than
	}

	if (*aa < *bb) {
		return (-1); // Less than
	}

	return (0); // Equal
}

CyBool_t CyFxGpioVerifyId(const uint8_t gpioId) {
	// Check if the range makes sense at all first.
	if (gpioId >= GPIO_MAX_IDENTIFIER) {
		return (CyFalse);
	}

	// Check gpioId with Cypress's own function.
	if (!CyU3PIsGpioValid(gpioId)) {
		return (CyFalse);
	}

	// Verify gpioId validity.
	if (bsearch(&gpioId, gpioValidIds, (sizeof(gpioValidIds) / sizeof(uint8_t)), sizeof(uint8_t),
		&CyFxGpioConfigComparator_UINT8_T) == NULL) {
		// Invalid configuration, didn't find the given GPIO inside the safe list!
		return (CyFalse);
	}

	return (CyTrue);
}

CyU3PReturnStatus_t CyFxGpioConfigParse(uint32_t *gpioSimpleEn0, uint32_t *gpioSimpleEn1) {
	// Enabling the GPIO block without any GPIOs defined? Nope!
	if (gpioConfig_DeviceSpecific_Length == 0) {
		return (CY_U3P_ERROR_NOT_CONFIGURED);
	}

	// Make sure gpioConfig is sorted for duplicate ID detection.
	qsort(gpioConfig_DeviceSpecific, gpioConfig_DeviceSpecific_Length, sizeof(gpioConfig_DeviceSpecific_Type),
		&CyFxGpioConfigComparator_GPIOCONFIG_DEVICESPECIFIC_TYPE);

	// Detect duplicates (which of course are forbidden!) (NOTE: there can be none if only one is used!)
	if (gpioConfig_DeviceSpecific_Length > 1) {
		for (size_t i = 1; i < gpioConfig_DeviceSpecific_Length; i++) {
			if (!CyFxGpioConfigComparator_GPIOCONFIG_DEVICESPECIFIC_TYPE(&gpioConfig_DeviceSpecific[i],
				&gpioConfig_DeviceSpecific[i - 1])) {
				return (CY_U3P_ERROR_INVALID_CONFIGURATION);
			}
		}
	}

	// Check that all given GPIOs are valid in the current configuration.
	for (size_t i = 0, intr = 0; i < gpioConfig_DeviceSpecific_Length; i++) {
		const uint8_t gpioId = gpioConfig_DeviceSpecific[i].gpioId;
		const uint8_t gpioType = gpioConfig_DeviceSpecific[i].gpioType;

		// Verify gpioId validity.
		if (!CyFxGpioVerifyId(gpioId)) {
			return (CY_U3P_ERROR_BAD_INDEX);
		}

		// Verify gpioType validity.
		CyBool_t found = CyFalse;

		for (size_t j = 0; j < (sizeof(gpioValidTypes) / sizeof(uint8_t)); j++) {
			// Check both upper and lower case letters.
			if (gpioType == gpioValidTypes[j] || gpioType == (gpioValidTypes[j] + 32)) {
				found = CyTrue;
				break;
			}
		}

		if (!found) {
			return (CY_U3P_ERROR_BAD_OPTION);
		}

		// gpioSimpleEn is used by IOMatrix and contains all valid GPIOs.
		if (gpioId < 32) {
			(*gpioSimpleEn0) |= ((uint32_t) 1 << gpioId);
		}
		else {
			(*gpioSimpleEn1) |= ((uint32_t) 1 << (gpioId - 32));
		}

		// Set ID to Type mapping; use an array for fast, direct lookup.
		gpioIdTypeMap[gpioId] = gpioType;

		// Set Interrupt Slot to ID and ID to Interrupt Slot mappings, using arrays for fast, direct lookup.
		if (gpioType != 'o' && gpioType != 'O' && gpioType != 'i' && gpioType != 'I') {
			if (intr == GPIO_MAX_INTERRUPT_SLOTS) {
				// Maximum number of Interrupt GPIOs reached!
				return (CY_U3P_ERROR_BAD_SIZE);
			}

			gpioInterruptSlotIdMap[intr] = gpioId;
			gpioInterruptIdSlotMap[gpioId] = (uint8_t) intr;

			intr++;
		}
	}

#if GPIO_DEBUG_LED_ENABLED == 1
	// Check that the GPIO number attached to the Debug LED is indeed present, and configured as an output.
	if (GPIO_DEBUG_LED_NUMBER >= GPIO_MAX_IDENTIFIER || gpioIdTypeMap[GPIO_DEBUG_LED_NUMBER] == 0xFF
		|| (gpioIdTypeMap[GPIO_DEBUG_LED_NUMBER] != 'o' && gpioIdTypeMap[GPIO_DEBUG_LED_NUMBER] != 'O')) {
		return (CY_U3P_ERROR_INVALID_CONFIGURATION);
	}
#endif

	return (CY_U3P_SUCCESS);
}

/**
 * GPIO interrupt callback handler. This is received from the interrupt context. So DMA API is not available
 * from here. Set an event in the event group, so that the GPIO thread can react to the event.
 */
static void CyFxGpioInterruptHandler(uint8_t gpioId) {
	// Send event by setting the appropriate event flag.
	CyU3PEventSet(&glEventFlagGPIO, ((uint32_t) 0x01 << (gpioInterruptIdSlotMap[gpioId])), CYU3P_EVENT_OR);
}

void CyFxGpioEventHandlerLoop(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;
	uint32_t eventFlagGPIO;
	size_t i;

	for (;;) {
		// Wait for a GPIO interrupt event
		status = CyU3PEventGet(&glEventFlagGPIO, 0x00FFFFFF, CYU3P_EVENT_OR_CLEAR, &eventFlagGPIO, CYU3P_WAIT_FOREVER);
		if (status == CY_U3P_SUCCESS) {
			i = 0;

			// Parse returned event to get gpioId back and type of event
			while (eventFlagGPIO > 0) {
				// The GPIO i has an event, let's call the user handler
				if (eventFlagGPIO & (uint32_t) 0x01) {
					CyFxHandleCustomGPIO_DeviceSpecific(gpioInterruptSlotIdMap[i]);
				}

				// Let's continue to the next GPIO
				eventFlagGPIO >>= 1;
				i++;
			}
		}
	}
}

CyU3PReturnStatus_t CyFxGpioInit(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Initialize the GPIO module
	CyU3PGpioClock_t gpioClock;

	// The fast clock is based on SYS_CLK. The Simple GPIOs run at SYS_CLK / 4 (fast clock / 2 again).
	gpioClock.fastClkDiv = 4;
	gpioClock.slowClkDiv = 0;
	gpioClock.halfDiv = CyFalse;
	gpioClock.simpleDiv = CY_U3P_GPIO_SIMPLE_DIV_BY_2;
	gpioClock.clkSrc = CY_U3P_SYS_CLK;

#if GPIO_SUPPORT_ENABLED == 0
	status = CyU3PGpioInit(&gpioClock, NULL);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}
#else
	status = CyU3PGpioInit(&gpioClock, &CyFxGpioInterruptHandler);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// Initialize event for general GPIO event signaling.
	status = CyU3PEventCreate(&glEventFlagGPIO);
	if (status != CY_U3P_SUCCESS) {
		return (status);
	}

	// Configure each simple GPIO as specified
	CyU3PGpioSimpleConfig_t gpioSimpleConfig;

	for (size_t i = 0; i < gpioConfig_DeviceSpecific_Length; i++) {
		if (gpioConfig_DeviceSpecific[i].gpioType == 'o' || gpioConfig_DeviceSpecific[i].gpioType == 'O') {
			// Output configuration
			gpioSimpleConfig.outValue = (gpioConfig_DeviceSpecific[i].gpioType == 'O') ? (CyFalse) : (CyTrue); // Default to OFF.
			gpioSimpleConfig.driveLowEn = CyTrue;
			gpioSimpleConfig.driveHighEn = CyTrue;
			gpioSimpleConfig.inputEn = CyFalse;
			gpioSimpleConfig.intrMode = CY_U3P_GPIO_NO_INTR;
		}
		else {
			// Input configuration
			gpioSimpleConfig.outValue = CyFalse;
			gpioSimpleConfig.driveLowEn = CyFalse;
			gpioSimpleConfig.driveHighEn = CyFalse;
			gpioSimpleConfig.inputEn = CyTrue;

			// Take active-high/active-low into account by inverting the type of trigger when needed
			switch (gpioConfig_DeviceSpecific[i].gpioType) {
				case 'P':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_POS_EDGE;
					break;

				case 'p':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_NEG_EDGE;
					break;

				case 'N':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_NEG_EDGE;
					break;

				case 'n':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_POS_EDGE;
					break;

				case 'B':
				case 'b':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_BOTH_EDGE;
					break;

				case 'L':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_LOW_LEVEL;
					break;

				case 'l':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_HIGH_LEVEL;
					break;

				case 'H':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_HIGH_LEVEL;
					break;

				case 'h':
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_INTR_LOW_LEVEL;
					break;

				default:
					gpioSimpleConfig.intrMode = CY_U3P_GPIO_NO_INTR;
					break;
			}
		}

		status = CyU3PGpioSetSimpleConfig(gpioConfig_DeviceSpecific[i].gpioId, &gpioSimpleConfig);
		if (status != CY_U3P_SUCCESS) {
			return (status);
		}
	}
#endif

	return (status);
}

static void CyFxGpioPeriodicSwitch(uint32_t input) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Get current state of indicated gpioId
	CyBool_t gpioState = CyFalse;

	status = CyU3PGpioSimpleGetValue((uint8_t) input, &gpioState);
	if (status == CY_U3P_SUCCESS) {
		// Set the inverted value
		CyU3PGpioSimpleSetValue((uint8_t) input, !gpioState);
	}
}

void CyFxGpioTurnOff(uint8_t gpioId) {
	// Verify gpioId validity
	if (gpioId >= GPIO_MAX_IDENTIFIER || gpioIdTypeMap[gpioId] == 0xFF) {
		return;
	}

	if (gpioIdTypeMap[gpioId] == 'O') {
		// Active-high OFF means go low
		CyU3PGpioSimpleSetValue(gpioId, CyFalse);
	}
	else {
		// Active-low OFF means go high
		CyU3PGpioSimpleSetValue(gpioId, CyTrue);
	}
}

void CyFxGpioTurnOn(uint8_t gpioId) {
	// Verify gpioId validity
	if (gpioId >= GPIO_MAX_IDENTIFIER || gpioIdTypeMap[gpioId] == 0xFF) {
		return;
	}

	if (gpioIdTypeMap[gpioId] == 'O') {
		// Active-high ON means go high
		CyU3PGpioSimpleSetValue(gpioId, CyTrue);
	}
	else {
		// Active-low ON means go low
		CyU3PGpioSimpleSetValue(gpioId, CyFalse);
	}
}

CyBool_t CyFxHandleCustomVR_GPIO(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	switch (FX3_REQ_DIR(bRequest, bDirection)) {
		case FX3_REQ_DIR(VR_GPIO_GET, FX3_USB_DIRECTION_OUT): {
			// Format: wValue: gpioId, wIndex: unused
			if (wLength != 1) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_GPIO_GET: invalid transfer length (!= 1)", status);
				break;
			}

			// Verify gpioId validity
			if (wValue >= GPIO_MAX_IDENTIFIER || gpioIdTypeMap[wValue] == 0xFF) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_GPIO_GET: invalid GPIO Id given", status);
				break;
			}

			// Get current gpioId value
			CyBool_t gpioIsHigh = CyFalse;

			status = CyU3PGpioSimpleGetValue((uint8_t) wValue, &gpioIsHigh);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_GPIO_GET: CyU3PGpioSimpleGetValue failed", status);
				break;
			}

			// Take active-high/active-low into account for conversion (none needed for active-high!)
			if (gpioIdTypeMap[wValue] > 96) {
				// Invert for active-low
				gpioIsHigh = !gpioIsHigh;
			}

			// Send it back to the control endpoint
			status = CyU3PUsbSendEP0Data(1, (uint8_t *) &gpioIsHigh);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_GPIO_GET: CyU3PUsbSendEP0Data failed", status);
				break;
			}

			break;
		}

		case FX3_REQ_DIR(VR_GPIO_SET, FX3_USB_DIRECTION_IN):
			// Format: wValue: gpioId, wIndex: operation to execute, wLength: 0 for OFF/ON/TOGGLE,
			// else for TIMED and RECURRING, 2 bytes with time in ms
			if (wValue >= GPIO_MAX_IDENTIFIER || (gpioIdTypeMap[wValue] != 'o' && gpioIdTypeMap[wValue] != 'O')) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET: invalid GPIO Id given", status);
				break;
			}

			// The gpioId is valid, so let's see what we have to do ...
			switch (wIndex) {
				case OFF:
					if (wLength != 0) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET OFF: no payload allowed", status);
						break;
					}

					CyFxGpioTurnOff((uint8_t) wValue);

					CyU3PUsbAckSetup();

					break;

				case ON:
					if (wLength != 0) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET ON: no payload allowed", status);
						break;
					}

					CyFxGpioTurnOn((uint8_t) wValue);

					CyU3PUsbAckSetup();

					break;

				case TOGGLE:
					if (wLength != 0) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET TOGGLE: no payload allowed", status);
						break;
					}

					CyFxGpioTurnOn((uint8_t) wValue);
					CyFxGpioTurnOff((uint8_t) wValue);

					CyU3PUsbAckSetup();

					break;

				case TIMED: {
					// Get time from request data (first two bytes, in network order)
					if (wLength != 2) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET TIMED: invalid transfer length (!= 2)", status);
						break;
					}

					status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET TIMED: CyU3PUsbGetEP0Data failed", status);
						break;
					}

					uint16_t time = (uint16_t) ((glEP0Buffer[0] << 8) | glEP0Buffer[1]);

					CyFxGpioTurnOn((uint8_t) wValue);
					CyU3PThreadSleep(time);
					CyFxGpioTurnOff((uint8_t) wValue);

					break;
				}

				case RECURRING: {
					// Get time from request data (first two bytes, in network order)
					if (wLength != 2) {
						status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET RECURRING: invalid transfer length (!= 2)", status);
						break;
					}

					status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET RECURRING: CyU3PUsbGetEP0Data failed", status);
						break;
					}

					uint16_t time = (uint16_t) ((glEP0Buffer[0] << 8) | glEP0Buffer[1]);

					if (time == 0) {
						// Turn off any existing recurring switch for this gpioId
						CyFxHeartbeatFunctionRemove(&CyFxGpioPeriodicSwitch, wValue);
						break;
					}

					// Set a new Heartbeat on this gpioId (or update an existing one)
					status = CyFxHeartbeatFunctionAdd(&CyFxGpioPeriodicSwitch, wValue, time);
					if (status != CY_U3P_SUCCESS) {
						CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET RECURRING: CyFxHeartbeatFunctionAdd failed", status);
						break;
					}

					break;
				}

				default:
					// If it's not one of the above cases, the given operation has to be invalid, return error.
					status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
					CyFxErrorHandler(LOG_ERROR, "VR_GPIO_SET: invalid GPIO operation", status);

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
