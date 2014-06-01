#include "fx3.h"

#if EXAMPLE == 1

spiConfig_DeviceSpecific_Type spiConfig_DeviceSpecific[] = {
	{ 0, 3, 256, 512 * KILOBYTE, 33 * MEGAHERTZ, CyFalse }, /* Default dev-kit SPI Flash (512KB, 33Mhz, SS: default line, active-low) */
};
const uint8_t spiConfig_DeviceSpecific_Length = (sizeof(spiConfig_DeviceSpecific) / sizeof(spiConfig_DeviceSpecific[0]));

// Please keep this sorted, and no duplicates!
// Upper-case letters denote an active-high signal, lower-case an active-low one.
// Please note that changing to active-low also takes care to switch the meaning of edges, low and high: the pos-edge
// for example means changing from electrical high to low now, and the low level (logical 0) is the electrical high.
// Supported types: O out, I in, P positive intr, N negative intr, B both intr, L low/false intr, H high/true intr.
// Up to 24 interrupt input GPIOs are supported.
gpioConfig_DeviceSpecific_Type gpioConfig_DeviceSpecific[] = {
	{ 26, 'o' }, /* GPIO 28 is an active-low OUT */
	{ 27, 'I' }, /* GPIO 26 is an active-high IN */
	{ 45, 'P' }, /* GPIO 27 is an active-high IN and will interrupt on positive transition (false => true) */
};
const uint8_t gpioConfig_DeviceSpecific_Length = (sizeof(gpioConfig_DeviceSpecific) / sizeof(gpioConfig_DeviceSpecific[0]));

void CyFxHandleCustomGPIO_DeviceSpecific(uint8_t gpioId) {
	CyFxErrorHandler(LOG_DEBUG, "GPIO was toggled.", gpioId);
}

extern uint8_t CyFxUSBSerialNumberDscr[];

CyU3PReturnStatus_t CyFxHandleCustomINIT_DeviceSpecific(void) {
	// Set Serial Number to 1.
	CyFxUSBSerialNumberDscr[16] = '1';

	return (CY_U3P_SUCCESS);
}

CyBool_t CyFxHandleCustomVR_DeviceSpecific(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength) {
	(void) wValue; // UNUSED
	(void) wIndex; // UNUSED
	(void) wLength; // UNUSED

	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	switch (FX3_REQ_DIR(bRequest, bDirection)) {
		case FX3_REQ_DIR(0xFF, FX3_USB_DIRECTION_IN):
			// Fail request
			status = CY_U3P_ERROR_BAD_ARGUMENT;

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

#endif /* EXAMPLE */
