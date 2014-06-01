#include "fx3.h"
#include "common_vendor_requests.h"

CyBool_t CyFxHandleCustomVR_Common(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	switch (FX3_REQ_DIR(bRequest, bDirection)) {
#if MS_FEATURE_DESCRIPTOR_ENABLED == 1
		case FX3_REQ_DIR(VR_MS_FEATURE_DSCR, FX3_USB_DIRECTION_OUT):
			if (wIndex == 0x0004) {
				// Microsoft Compatible ID Feature Descriptor
				// Request the WinUSB driver for our device, see https://github.com/pbatard/libwdi/wiki/WCID-Devices
				glEP0Buffer[0] = 0x28; // Descriptor length, 4 bytes LE = 40 bytes
				glEP0Buffer[1] = 0x00;
				glEP0Buffer[2] = 0x00;
				glEP0Buffer[3] = 0x00;
				glEP0Buffer[4] = 0x00; // Version, 2 bytes LE = 1.0
				glEP0Buffer[5] = 0x01;
				glEP0Buffer[6] = 0x04; // Compatibility ID descriptor index, 2 bytes LE = 0x0004
				glEP0Buffer[7] = 0x00;
				glEP0Buffer[8] = 0x01; // Number of sections, 1 byte = 1 section
				glEP0Buffer[9] = 0x00; // RESERVED, 7 bytes
				glEP0Buffer[10] = 0x00;
				glEP0Buffer[11] = 0x00;
				glEP0Buffer[12] = 0x00;
				glEP0Buffer[13] = 0x00;
				glEP0Buffer[14] = 0x00;
				glEP0Buffer[15] = 0x00;
				glEP0Buffer[16] = 0x00; // Interface Number, 1 byte = Interface #0
				glEP0Buffer[17] = 0x01; // RESERVED, 1 byte
				glEP0Buffer[18] = 0x57; // Compatible ID, 8 bytes ASCII string = WINUSB\0\0
				glEP0Buffer[19] = 0x49;
				glEP0Buffer[20] = 0x4E;
				glEP0Buffer[21] = 0x55;
				glEP0Buffer[22] = 0x53;
				glEP0Buffer[23] = 0x42;
				glEP0Buffer[24] = 0x00;
				glEP0Buffer[25] = 0x00;
				glEP0Buffer[26] = 0x00; // Sub-compatible ID, 8 bytes ASCII string (unused)
				glEP0Buffer[27] = 0x00;
				glEP0Buffer[28] = 0x00;
				glEP0Buffer[29] = 0x00;
				glEP0Buffer[30] = 0x00;
				glEP0Buffer[31] = 0x00;
				glEP0Buffer[32] = 0x00;
				glEP0Buffer[33] = 0x00;
				glEP0Buffer[34] = 0x00; // RESERVED, 6 bytes
				glEP0Buffer[35] = 0x00;
				glEP0Buffer[36] = 0x00;
				glEP0Buffer[37] = 0x00;
				glEP0Buffer[38] = 0x00;
				glEP0Buffer[39] = 0x00;

				status = CyU3PUsbSendEP0Data(40, glEP0Buffer);
				if (status != CY_U3P_SUCCESS) {
					CyFxErrorHandler(LOG_ERROR, "VR_MS_FEATURE_DSCR: CyU3PUsbSendEP0Data failed", status);
					break;
				}
			}
			else {
				// Unsupported feature descriptor request
				// We need to detect if wIndex is 0 and filter it out, because 0 means CY_U3P_SUCCESS.
				// See http://libusbx.1081486.n5.nabble.com/Libusbx-devel-libusbx-xusb-example-and-Microsoft-OS-Descriptor-tp845p876.html
				// for why we need this with the WinUSB driver, which sets wIndex to 0 erroneously.
				status = (wIndex == 0) ? (CY_U3P_ERROR_BAD_ARGUMENT) : ((CyU3PReturnStatus_t) wIndex);

				CyFxErrorHandler(LOG_ERROR, "VR_MS_FEATURE_DSCR: unsupported request", status);
				break;
			}

			break;
#endif

		case FX3_REQ_DIR(VR_TEST, FX3_USB_DIRECTION_IN):
			// Get data from host
			if (wLength != 0) {
				status = CyU3PUsbGetEP0Data(wLength, glEP0Buffer, NULL);
				if (status != CY_U3P_SUCCESS) {
					CyFxErrorHandler(LOG_ERROR, "VR_TEST: CyU3PUsbGetEP0Data failed", status);
					break;
				}
			}
			else {
				CyU3PUsbAckSetup();
			}

			// Limit read length to MAX_TRANSFER_SIZE_STATUS
			if (wLength > FX3_MAX_TRANSFER_SIZE_STATUS) {
				wLength = FX3_MAX_TRANSFER_SIZE_STATUS;
			}

			// Make sure string is correctly terminated (for strlen() in ErrorHandler)
			glEP0Buffer[wLength] = 0x00;

			// Send string back using default, already present ErrorHandler
			CyFxErrorHandler(LOG_EMERGENCY, (const char *) glEP0Buffer, status);

			break;

		case FX3_REQ_DIR(VR_LOG_LEVEL, FX3_USB_DIRECTION_IN):
			if (wLength != 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_LOG_LEVEL: no payload allowed", status);
				break;
			}

			// Reject invalid log-levels
			if (wValue > LOG_DEBUG) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_LOG_LEVEL: invalid log-level given", status);
				break;
			}

			// If LOG_DEBUG, also enable the system alive message, else make sure to remove it
			if (wValue == LOG_DEBUG && glLogLevel != LOG_DEBUG) {
				status = CyU3PTimerStart(&glSystemAliveTimer);
				if (status != CY_U3P_SUCCESS) {
					CyFxErrorHandler(LOG_ERROR, "VR_LOG_LEVEL: CyU3PTimerStart failed", status);
					break;
				}
			}
			else if (wValue != LOG_DEBUG && glLogLevel == LOG_DEBUG) {
				status = CyU3PTimerStop(&glSystemAliveTimer);
				if (status != CY_U3P_SUCCESS) {
					CyFxErrorHandler(LOG_ERROR, "VR_LOG_LEVEL: CyU3PTimerStop failed", status);
					break;
				}
			}

			// Set log-level to given value, enabling or disabling certain log messages
			glLogLevel = (uint8_t) wValue;

			CyU3PUsbAckSetup();

			break;

		case FX3_REQ_DIR(VR_FX3_RESET, FX3_USB_DIRECTION_IN):
			if (wLength != 0) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_FX3_RESET: no payload allowed", status);
				break;
			}

			CyU3PUsbAckSetup(); // Close request before resetting!

			// Hard-reset the Cypress FX3 device
			CyU3PDeviceReset(CyFalse);

			break;

		case FX3_REQ_DIR(VR_STATUS, FX3_USB_DIRECTION_OUT): {
			if (wLength != 8) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_STATUS: invalid transfer length (!= 8)", status);
				break;
			}

			// Send status back to the control endpoint (0-3: timestamp, 4: AppRunning, 5: LogLevel, 6: LogFailedAmount, 7: USB connection speed)
			uint32_t time = CyU3PGetTime();
			memcpy(glEP0Buffer, &time, sizeof(time));
			uint16_t buffer_len = sizeof(time);

			glEP0Buffer[buffer_len++] = (uint8_t) glAppRunning;
			glEP0Buffer[buffer_len++] = glLogLevel;
			glEP0Buffer[buffer_len++] = glLogFailedAmount;

			// Get current USB connection speed
			CyU3PUSBSpeed_t usbSpeed = CyU3PUsbGetSpeed();
			glEP0Buffer[buffer_len++] = usbSpeed;

			status = CyU3PUsbSendEP0Data(buffer_len, glEP0Buffer);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_STATUS: CyU3PUsbSendEP0Data failed", status);
				break;
			}

			break;
		}

		case FX3_REQ_DIR(VR_SUPPORTED, FX3_USB_DIRECTION_OUT):
			if (wLength != 7) {
				status = CY_U3P_ERROR_BAD_ARGUMENT; // Set to something known!
				CyFxErrorHandler(LOG_ERROR, "VR_SUPPORTED: invalid transfer length (!= 7)", status);
				break;
			}

			// Get information about compile-time support of features
			glEP0Buffer[0] = GPIF_32BIT_SUPPORT_ENABLED;
			glEP0Buffer[1] = I2C_SUPPORT_ENABLED;
			glEP0Buffer[2] = SPI_SUPPORT_ENABLED;
			glEP0Buffer[3] = GPIO_SUPPORT_ENABLED;
			glEP0Buffer[4] = DEVICE_SPECIFIC_VENDOR_REQUESTS;
			glEP0Buffer[5] = DMA_USBTOFX3_CALLBACK;
			glEP0Buffer[6] = DMA_FX3TOUSB_CALLBACK;

			status = CyU3PUsbSendEP0Data(7, glEP0Buffer);
			if (status != CY_U3P_SUCCESS) {
				CyFxErrorHandler(LOG_ERROR, "VR_SUPPORTED: CyU3PUsbSendEP0Data failed", status);
				break;
			}

			break;

		default:
			// Not handled in this module
			return (CyFalse);

			break;
	}

	// If status is success, it means we handled the vendor request and did so without encountering an error.
	// Else, some error occurred while handling the request, so we stall the end-point ourselves.
	if (status != CY_U3P_SUCCESS) {
		CyU3PUsbStall(0, CyTrue, CyTrue);
	}

	// In any case, we handled the request!
	return (CyTrue);
}
