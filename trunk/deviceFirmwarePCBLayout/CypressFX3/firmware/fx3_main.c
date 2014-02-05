#include "cyu3dma.h"
#include "cyu3gpif.h"
#include "cyu3pib.h"
#include "fx3.h"

// Feature specific configuration inclusion
#include "fx3_usbdescr.h"
#include "features/common_vendor_requests.h"
#include "features/heartbeat.h"
#if GPIO_SUPPORT_ENABLED == 1
#include "features/gpio_support.h"
#endif
#if I2C_SUPPORT_ENABLED == 1
#include "features/i2c_support.h"
#endif
#if SPI_SUPPORT_ENABLED == 1
#include "features/spi_support.h"
#endif
/* This file should be included only once, as it contains
 * structure definitions. Including it in multiple places
 * can result in linker errors. */
#if GPIF_32BIT_SUPPORT_ENABLED == 1
#include "gpif2/sync_slave_fifo_data32_sockets2.cydsn/cyfxgpif2config.h"
#else
#include "gpif2/sync_slave_fifo_data16_sockets2.cydsn/cyfxgpif2config.h"
#endif

// Global variables declarations
static CyU3PThread glApplicationThread; // Application thread structure
static CyU3PThread glHeartbeatThread; // Heartbeat thread structure
CyBool_t glAppRunning = CyFalse; // Whether the application is active or not
uint8_t glLogLevel = FX3_LOG_LEVEL; // Default log level
uint8_t glLogFailedAmount = 0; // Number of failed log calls made

static CyU3PDmaChannel glEP1DMAChannelCPUtoUSB; // DMA Channel handle for CPU2U transfer
static CyU3PDmaChannel glEP2DMAChannelUSBtoFX3; // DMA Channel handle for U2FX transfer
static CyU3PDmaChannel glEP2DMAChannelFX3toUSB; // DMA Channel handle for FX2U transfer

uint8_t glEP0Buffer[FX3_MAX_TRANSFER_SIZE_CONTROL] __attribute__ ((aligned (32))) = { 0 };

/**
 * Application Error Handler.
 * Please note that a debug message should never be longer than 58 characters.
 * This limitation arises from the fact the Status endpoint buffer is 64 bytes long, as it is an interrupt
 * type endpoint. 1 byte is used for encoding the type of message being sent, 1 other byte is used to encode
 * the error code, and 4 bytes are used to encode the current time, resulting in the actual content being
 * at most 64 - 1 - 1 - 4 = 58 bytes.
 */
void CyFxErrorHandler(uint8_t log_level, const char *debug_message, CyU3PReturnStatus_t error_code) {
	// Only send log messages that are of equal or higher priority than the global setting
	if (log_level <= glLogLevel) {
#if GPIO_DEBUG_LED_ENABLED == 1
		// Quickly blink the Debug LED twice to indicate an error has happened and a message was dispatched.
		CyFxGpioTurnOn(GPIO_DEBUG_LED_NUMBER);
		CyFxGpioTurnOff(GPIO_DEBUG_LED_NUMBER);

		CyFxGpioTurnOn(GPIO_DEBUG_LED_NUMBER);
		CyFxGpioTurnOff(GPIO_DEBUG_LED_NUMBER);
#endif

		// Get DMA buffer for the status channel
		CyU3PReturnStatus_t status;
		CyU3PDmaBuffer_t buffer;

		status = CyU3PDmaChannelGetBuffer(&glEP1DMAChannelCPUtoUSB, &buffer, FX3_STATUS_DMA_CPUTOUSB_BUF_TIMEOUT);
		if (status != CY_U3P_SUCCESS) {
			glLogFailedAmount++;
			return;
		}

		// Set msgType value to 0x00 to signal this is a standard debug message
		buffer.buffer[0] = 0x00;
		buffer.buffer[1] = (uint8_t) error_code;
		buffer.count = 2;

		// Add FX3 internal timestamp
		uint32_t time = CyU3PGetTime();
		memcpy(buffer.buffer + buffer.count, &time, sizeof(time));
		buffer.count = (uint16_t) (buffer.count + sizeof(time));

		// Take the input
		size_t str_len = strlen(debug_message);

		// Cut down on excessive length
		if (str_len > ((size_t) FX3_MAX_TRANSFER_SIZE_STATUS - buffer.count)) {
			str_len = ((size_t) FX3_MAX_TRANSFER_SIZE_STATUS - buffer.count);
		}

		memcpy(buffer.buffer + buffer.count, debug_message, str_len);
		buffer.count = (uint16_t) (buffer.count + str_len);

		// Send the message to the host
		status = CyU3PDmaChannelCommitBuffer(&glEP1DMAChannelCPUtoUSB, buffer.count, 0);
		if (status != CY_U3P_SUCCESS) {
			glLogFailedAmount++;
			return;
		}
	}
}

/**
 * This function initializes the debug module.
 * Debug messages are sent out over USB EP1 IN. This enables easy debugging, provided system initialization succeeded
 * and the DMA and USB engines are still operational.
 */
static void CyFxStatusInit(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Status endpoint (EP1) configuration
	CyU3PEpConfig_t epCfg;

	epCfg.enable = CyTrue;
	epCfg.epType = CY_U3P_USB_EP_INTR;
	epCfg.burstLen = 1;
	epCfg.streams = 0;
	epCfg.pcktSize = FX3_MAX_TRANSFER_SIZE_STATUS;
	epCfg.isoPkts = 0;

	// EP1 Consumer endpoint configuration
	status = CyU3PSetEpConfig(FX3_STATUS_EP_ADDR_OUT, &epCfg);
	if (status != CY_U3P_SUCCESS) {
		// No debug facility ready yet!
		CyU3PDeviceReset(CyFalse);
	}

	// Create a DMA Manual Out Channel between two sockets of an endpoint.
	// The DMA size is always 64 here, as that's the size limit on (backwards-compatible) interrupt endpoints.
	CyU3PDmaChannelConfig_t dmaCfg;

	dmaCfg.size = FX3_MAX_TRANSFER_SIZE_STATUS;
	dmaCfg.count = FX3_STATUS_DMA_CPUTOUSB_BUF_COUNT;
	dmaCfg.prodSckId = FX3_STATUS_PRODUCER_CPU_SOCKET;
	dmaCfg.consSckId = FX3_STATUS_CONSUMER_USB_SOCKET;
	dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
	dmaCfg.notification = 0;
	dmaCfg.cb = NULL;
	dmaCfg.prodHeader = 0;
	dmaCfg.prodFooter = 0;
	dmaCfg.consHeader = 0;
	dmaCfg.prodAvailCount = 0;

	status = CyU3PDmaChannelCreate(&glEP1DMAChannelCPUtoUSB, CY_U3P_DMA_TYPE_MANUAL_OUT, &dmaCfg);
	if (status != CY_U3P_SUCCESS) {
		// No debug facility ready yet!
		CyU3PDeviceReset(CyFalse);
	}

	// Flush the endpoint memory
	CyU3PUsbFlushEp(FX3_STATUS_EP_ADDR_OUT);

	// Set DMA channel transfer size to infinite.
	status = CyU3PDmaChannelSetXfer(&glEP1DMAChannelCPUtoUSB, 0);
	if (status != CY_U3P_SUCCESS) {
		// No debug facility ready yet!
		CyU3PDeviceReset(CyFalse);
	}

	// Ready for logging now, ignore failed calls before this
	glLogFailedAmount = 0;
}

static void CyFxStatusDestroy(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Flush the endpoint memory
	CyU3PUsbFlushEp(FX3_STATUS_EP_ADDR_OUT);

	// Destroy the DMA channels
	CyU3PDmaChannelDestroy(&glEP1DMAChannelCPUtoUSB);

	// Disable endpoints
	CyU3PEpConfig_t epCfg;
	memset(&epCfg, 0, sizeof(epCfg));
	epCfg.enable = CyFalse;

	// EP1 Consumer endpoint configuration
	status = CyU3PSetEpConfig(FX3_STATUS_EP_ADDR_OUT, &epCfg);
	if (status != CY_U3P_SUCCESS) {
		// No debug facility ready anymore! Ignore error.
	}
}

/**
 * This function starts the FIFO application. This is called when a SET_CONF event is received from the USB host.
 * The FIFO endpoints are configured and the DMA pipes are setup in this function.
 */
static void CyFxFIFODataInit(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// First identify the USB speed.
	CyU3PUSBSpeed_t usbSpeed = CyU3PUsbGetSpeed();

	// Based on the USB Speed configure the end-point packet size and the burst length.
	uint16_t size = 64;
	uint8_t burst_len_fx3tousb = 1;
	uint8_t burst_len_usbtofx3 = 1;

	switch (usbSpeed) {
		case CY_U3P_FULL_SPEED:
			break;

		case CY_U3P_HIGH_SPEED:
			size = 512;
			break;

		case CY_U3P_SUPER_SPEED:
			size = 1024;
			// USB 3.0 supports bursts!
			burst_len_fx3tousb = FX3_FIFO_DATA_DMA_FX3TOUSB_BURST_LEN;
			burst_len_usbtofx3 = FX3_FIFO_DATA_DMA_USBTOFX3_BURST_LEN;
			break;

		default:
			CyFxErrorHandler(LOG_CRITICAL, "CyFxFIFODataInit: Invalid USB speed found", usbSpeed);
			break;
	}

	// FIFO_DATA end-point (EP2) configuration.
	CyU3PEpConfig_t epCfg;

	epCfg.enable = CyTrue;
	epCfg.epType = CY_U3P_USB_EP_BULK;
	epCfg.streams = 0;
	epCfg.isoPkts = 0;
	epCfg.pcktSize = size;

	// EP2 FX3toUSB end-point configuration.
	epCfg.burstLen = burst_len_fx3tousb;

	status = CyU3PSetEpConfig(FX3_FIFO_DATA_EP_ADDR_OUT, &epCfg);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataInit: CyU3PSetEpConfig(FX3toUSB) failed", status);
	}

	// EP2 USBtoFX3 end-point configuration.
	epCfg.burstLen = burst_len_usbtofx3;

	status = CyU3PSetEpConfig(FX3_FIFO_DATA_EP_ADDR_IN, &epCfg);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataInit: CyU3PSetEpConfig(USBtoFX3) failed", status);
	}

	// FIFO_DATA end-point (EP2) DMA channels configuration.
	// DMA size is based on the detected USB speed and the burst length.
	CyU3PDmaChannelConfig_t dmaCfg;

	dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
	dmaCfg.prodHeader = 0;
	dmaCfg.prodFooter = 0;
	dmaCfg.consHeader = 0;
	dmaCfg.prodAvailCount = 0;

	// EP2 FX3toUSB end-point DMA channel configuration.
	dmaCfg.size = (uint16_t) (size * burst_len_fx3tousb);
	dmaCfg.count = FX3_FIFO_DATA_DMA_FX3TOUSB_BUF_COUNT;
	dmaCfg.prodSckId = FX3_FIFO_DATA_PRODUCER_FX3_SOCKET;
	dmaCfg.consSckId = FX3_FIFO_DATA_CONSUMER_USB_SOCKET;

#if DMA_FX3TOUSB_CALLBACK == 1
	dmaCfg.notification = FX3_FIFO_DATA_DMA_FX3TOUSB_CB_EVENT;
	dmaCfg.cb = &CyFxDmaFX3toUSBCallback;

	status = CyU3PDmaChannelCreate(&glEP2DMAChannelFX3toUSB,
		(FX3_FIFO_DATA_PRODUCER_FX3_SOCKET == CY_U3P_CPU_SOCKET_PROD) ?
			(CY_U3P_DMA_TYPE_MANUAL_OUT) : (CY_U3P_DMA_TYPE_MANUAL), &dmaCfg);
#else
	dmaCfg.notification = 0;
	dmaCfg.cb = NULL;

	status = CyU3PDmaChannelCreate(&glEP2DMAChannelFX3toUSB, CY_U3P_DMA_TYPE_AUTO, &dmaCfg);
#endif
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataInit: CyU3PDmaChannelCreate(FX3toUSB) failed", status);
	}

	// EP2 USBtoFX3 end-point DMA channel configuration.
	dmaCfg.size = (uint16_t) (size * burst_len_usbtofx3);
	dmaCfg.count = FX3_FIFO_DATA_DMA_USBTOFX3_BUF_COUNT;
	dmaCfg.prodSckId = FX3_FIFO_DATA_PRODUCER_USB_SOCKET;
	dmaCfg.consSckId = FX3_FIFO_DATA_CONSUMER_FX3_SOCKET;

#if DMA_USBTOFX3_CALLBACK == 1
	dmaCfg.notification = FX3_FIFO_DATA_DMA_USBTOFX3_CB_EVENT;
	dmaCfg.cb = &CyFxDmaUSBtoFX3Callback;

	status = CyU3PDmaChannelCreate(&glEP2DMAChannelUSBtoFX3,
		(FX3_FIFO_DATA_CONSUMER_FX3_SOCKET == CY_U3P_CPU_SOCKET_CONS) ?
			(CY_U3P_DMA_TYPE_MANUAL_IN) : (CY_U3P_DMA_TYPE_MANUAL), &dmaCfg);
#else
	dmaCfg.notification = 0;
	dmaCfg.cb = NULL;

	status = CyU3PDmaChannelCreate(&glEP2DMAChannelUSBtoFX3, CY_U3P_DMA_TYPE_AUTO, &dmaCfg);
#endif
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataInit: CyU3PDmaChannelCreate(USBtoFX3) failed", status);
	}

	// Flush the end-point memory.
	CyU3PUsbFlushEp(FX3_FIFO_DATA_EP_ADDR_OUT);
	CyU3PUsbFlushEp(FX3_FIFO_DATA_EP_ADDR_IN);

	// Set DMA channel transfer size to infinite.
	status = CyU3PDmaChannelSetXfer(&glEP2DMAChannelFX3toUSB, 0);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataInit: CyU3PDmaChannelSetXfer(FX3toUSB) failed", status);
	}

	status = CyU3PDmaChannelSetXfer(&glEP2DMAChannelUSBtoFX3, 0);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataInit: CyU3PDmaChannelSetXfer(USBtoFX3) failed", status);
	}

	// Call additional DMA management functions.
#if DMA_FX3TOUSB_CALLBACK == 1
	CyFxDmaFX3toUSBCallbackInit(&glEP2DMAChannelFX3toUSB);
#endif
#if DMA_USBTOFX3_CALLBACK == 1
	CyFxDmaUSBtoFX3CallbackInit(&glEP2DMAChannelUSBtoFX3);
#endif

	// Update the status flag.
	glAppRunning = CyTrue;
}

/**
 * This function stops the FIFO application. This shall be called whenever a RESET or DISCONNECT event is received from
 * the USB host. The FIFO endpoints are disabled and the DMA pipes are destroyed.
 */
static void CyFxFIFODataDestroy(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Update the status flag.
	glAppRunning = CyFalse;

	// Call additional DMA management functions.
#if DMA_USBTOFX3_CALLBACK == 1
	CyFxDmaUSBtoFX3CallbackDestroy(&glEP2DMAChannelUSBtoFX3);
#endif
#if DMA_FX3TOUSB_CALLBACK == 1
	CyFxDmaFX3toUSBCallbackDestroy(&glEP2DMAChannelFX3toUSB);
#endif

	// Flush the end-point memory.
	CyU3PUsbFlushEp(FX3_FIFO_DATA_EP_ADDR_IN);
	CyU3PUsbFlushEp(FX3_FIFO_DATA_EP_ADDR_OUT);

	// Destroy the DMA channels.
	CyU3PDmaChannelDestroy(&glEP2DMAChannelUSBtoFX3);
	CyU3PDmaChannelDestroy(&glEP2DMAChannelFX3toUSB);

	// Disable end-points.
	CyU3PEpConfig_t epCfg;
	memset(&epCfg, 0, sizeof(epCfg));
	epCfg.enable = CyFalse;

	// EP2 USBtoFX3 end-point configuration.
	status = CyU3PSetEpConfig(FX3_FIFO_DATA_EP_ADDR_IN, &epCfg);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataDestroy: CyU3PSetEpConfig(USBtoFX3) failed", status);
	}

	// EP2 FX3toUSB end-point configuration.
	status = CyU3PSetEpConfig(FX3_FIFO_DATA_EP_ADDR_OUT, &epCfg);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyFxFIFODataDestroy: CyU3PSetEpConfig(FX3toUSB) failed", status);
	}
}

/**
 * Callback function to check for PIB errors.
 */
static void CyFxPIBErrorCB(CyU3PPibIntrType cbType, uint16_t cbArg) {
	if (cbType == CYU3P_PIB_INTR_ERROR) {
		switch (CYU3P_GET_PIB_ERROR_TYPE(cbArg)) {
			// Detect buffer over/underruns when talking to the Slave FIFO.
			case CYU3P_PIB_ERR_THR0_WR_OVERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR0_WR_OVERRUN", cbArg);
				break;

			case CYU3P_PIB_ERR_THR1_WR_OVERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR1_WR_OVERRUN", cbArg);
				break;

			case CYU3P_PIB_ERR_THR2_WR_OVERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR2_WR_OVERRUN", cbArg);
				break;

			case CYU3P_PIB_ERR_THR3_WR_OVERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR3_WR_OVERRUN", cbArg);
				break;

			case CYU3P_PIB_ERR_THR0_RD_UNDERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR0_RD_OVERRUN", cbArg);
				break;

			case CYU3P_PIB_ERR_THR1_RD_UNDERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR01_RD_OVERRUN", cbArg);
				break;

			case CYU3P_PIB_ERR_THR2_RD_UNDERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR02_RD_OVERRUN", cbArg);
				break;

			case CYU3P_PIB_ERR_THR3_RD_UNDERRUN:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: CYU3P_PIB_ERR_THR03_RD_OVERRUN", cbArg);
				break;

			default:
				CyFxErrorHandler(LOG_CRITICAL, "PIB Error: Other PIB Error occurred!", cbArg);
				break;
		}
	}
}

/**
 * Callback to handle the USB setup requests.
 */
static CyBool_t CyFxUSBSetupRequestsCB(uint32_t setupdat0, uint32_t setupdat1) {
	/* Fast enumeration is used. Only requests addressed to the interface, class,
	 * vendor and unknown control requests are received by this function. */

	uint8_t bRequest, bReqType, bType, bTarget, bDirection;
	uint16_t wValue, wIndex, wLength;
	CyBool_t reqHandled = CyFalse;

	// Decode the fields from the setup request.
	bReqType = (setupdat0 & CY_U3P_USB_REQUEST_TYPE_MASK);
	bType = (bReqType & CY_U3P_USB_TYPE_MASK);
	bTarget = (bReqType & CY_U3P_USB_TARGET_MASK);
	bDirection = (bReqType & FX3_USB_DIRECTION_MASK);
	bRequest = (uint8_t) ((setupdat0 & CY_U3P_USB_REQUEST_MASK) >> CY_U3P_USB_REQUEST_POS);
	wValue = (uint16_t) ((setupdat0 & CY_U3P_USB_VALUE_MASK) >> CY_U3P_USB_VALUE_POS);
	wIndex = (uint16_t) ((setupdat1 & CY_U3P_USB_INDEX_MASK) >> CY_U3P_USB_INDEX_POS);
	wLength = (uint16_t) ((setupdat1 & CY_U3P_USB_LENGTH_MASK) >> CY_U3P_USB_LENGTH_POS);

	// Handle USB standard requests.
	if (bType == CY_U3P_USB_STANDARD_RQT) {
#if MS_FEATURE_DESCRIPTOR_ENABLED == 1
		/* Handle Microsoft OS string descriptor request. */
		if ((bTarget == CY_U3P_USB_TARGET_DEVICE) && (bRequest == CY_U3P_USB_SC_GET_DESCRIPTOR)
			&& (wValue == ((CY_U3P_USB_STRING_DESCR << 8) | 0xEE))) {
			// Ensure we only send the Microsoft OS string descriptor, and not anything more!
			if (wLength > CyFxUSBMicrosoftOSDscr[0]) {
				wLength = CyFxUSBMicrosoftOSDscr[0];
			}

			CyU3PUsbSendEP0Data(wLength, (uint8_t *) CyFxUSBMicrosoftOSDscr);

			reqHandled = CyTrue;
		}
#endif

		/* Handle SET_FEATURE(FUNCTION_SUSPEND) and CLEAR_FEATURE(FUNCTION_SUSPEND)
		 * requests here. It should be allowed to pass if the device is in configured
		 * state and failed otherwise. */
		if ((bTarget == CY_U3P_USB_TARGET_INTF)
			&& ((bRequest == CY_U3P_USB_SC_SET_FEATURE) || (bRequest == CY_U3P_USB_SC_CLEAR_FEATURE))
			&& (wValue == 0)) {
			if (glAppRunning) {
				CyU3PUsbAckSetup();
			}
			else {
				CyU3PUsbStall(0, CyTrue, CyFalse);
			}

			reqHandled = CyTrue;
		}

		/* CLEAR_FEATURE request for endpoint is always passed to the setup callback
		 * regardless of the enumeration model used. When a clear feature is received,
		 * the previous transfer has to be flushed and cleaned up. This is done at the
		 * protocol level. Since this is just a loopback operation, there is no higher
		 * level protocol. So flush the EP memory and reset the DMA channel associated
		 * with it. If there are more than one EP associated with the channel reset both
		 * the EPs. The endpoint stall and toggle / sequence number is also expected to be
		 * reset. Return CyFalse to make the library clear the stall and reset the endpoint
		 * toggle. Or invoke the CyU3PUsbStall (ep, CyFalse, CyTrue) and return CyTrue.
		 * Here we are clearing the stall ourselves. */
		if ((bTarget == CY_U3P_USB_TARGET_ENDPT) && (bRequest == CY_U3P_USB_SC_CLEAR_FEATURE)
			&& (wValue == CY_U3P_USBX_FS_EP_HALT)) {
			if (glAppRunning) {
				if (wIndex == FX3_STATUS_EP_ADDR_OUT) {
					CyU3PDmaChannelReset(&glEP1DMAChannelCPUtoUSB);
					CyU3PUsbFlushEp(FX3_STATUS_EP_ADDR_OUT);
					CyU3PUsbResetEp(FX3_STATUS_EP_ADDR_OUT);
					CyU3PDmaChannelSetXfer(&glEP1DMAChannelCPUtoUSB, 0);
				}

				if (wIndex == FX3_FIFO_DATA_EP_ADDR_OUT) {
					CyU3PDmaChannelReset(&glEP2DMAChannelFX3toUSB);
					CyU3PUsbFlushEp(FX3_FIFO_DATA_EP_ADDR_OUT);
					CyU3PUsbResetEp(FX3_FIFO_DATA_EP_ADDR_OUT);
					CyU3PDmaChannelSetXfer(&glEP2DMAChannelFX3toUSB, 0);
				}

				if (wIndex == FX3_FIFO_DATA_EP_ADDR_IN) {
					CyU3PDmaChannelReset(&glEP2DMAChannelUSBtoFX3);
					CyU3PUsbFlushEp(FX3_FIFO_DATA_EP_ADDR_IN);
					CyU3PUsbResetEp(FX3_FIFO_DATA_EP_ADDR_IN);
					CyU3PDmaChannelSetXfer(&glEP2DMAChannelUSBtoFX3, 0);
				}

				CyU3PUsbStall((uint8_t) wIndex, CyFalse, CyTrue);

				reqHandled = CyTrue;
			}
		}
	}

	// Handle supported vendor requests.
	if (bType == CY_U3P_USB_VENDOR_RQT) {
		// Verify that the request is not exceeding the size of the global EP0 buffer, which is where that data goes.
		if (wLength > FX3_MAX_TRANSFER_SIZE_CONTROL) {
			CyFxErrorHandler(LOG_ERROR, "VR_HANDLER: wLength exceeds maximum control transfer size",
				CY_U3P_ERROR_BAD_ARGUMENT);

			CyU3PUsbStall(0, CyTrue, CyTrue);

			reqHandled = CyTrue;
		}

#if DEVICE_SPECIFIC_VENDOR_REQUESTS == 1
		if (!reqHandled) {
			reqHandled = CyFxHandleCustomVR_DeviceSpecific(bDirection, bRequest, wValue, wIndex, wLength);
		}
#endif

		if (!reqHandled) {
			reqHandled = CyFxHandleCustomVR_Common(bDirection, bRequest, wValue, wIndex, wLength);
		}

#if GPIO_SUPPORT_ENABLED == 1
		if (!reqHandled) {
			reqHandled = CyFxHandleCustomVR_GPIO(bDirection, bRequest, wValue, wIndex, wLength);
		}
#endif

#if I2C_SUPPORT_ENABLED == 1
		if (!reqHandled) {
			reqHandled = CyFxHandleCustomVR_I2C(bDirection, bRequest, wValue, wIndex, wLength);
		}
#endif

#if SPI_SUPPORT_ENABLED == 1 && GPIF_32BIT_SUPPORT_ENABLED == 0
		if (!reqHandled) {
			reqHandled = CyFxHandleCustomVR_SPI(bDirection, bRequest, wValue, wIndex, wLength);
		}
#endif
	}

	return (reqHandled);
}

/**
 * This is the callback function to handle USB events.
 */
static void CyFxUSBEventsCB(CyU3PUsbEventType_t evtype, uint16_t evdata) {
	(void) evdata; // UNUSED

	switch (evtype) {
		case CY_U3P_USB_EVENT_SETCONF:
			// Stop the application before re-starting.
			if (glAppRunning) {
				CyFxFIFODataDestroy();
				CyFxStatusDestroy();
			}

			// Start the application.
			CyFxStatusInit();
			CyFxFIFODataInit();

			break;

		case CY_U3P_USB_EVENT_RESET:
		case CY_U3P_USB_EVENT_DISCONNECT:
			// Stop the application.
			if (glAppRunning) {
				CyFxFIFODataDestroy();
				CyFxStatusDestroy();
			}

			break;

		default:
			break;
	}
}

/**
 * Callback function to handle LPM requests from the USB 3.0 host. This function is invoked by the API
 * whenever a state change from U0 -> U1 or U0 -> U2 happens. If we return CyTrue from this function, the
 * FX3 device is retained in the low power state. If we return CyFalse, the FX3 device immediately tries
 * to trigger an exit back to U0.
 *
 * This application does not have any state in which we should not allow U1/U2 transitions; and therefore
 * the function always return CyTrue.
 */
static CyBool_t CyFxLPMRequestsCB(CyU3PUsbLinkPowerMode link_mode) {
	(void) link_mode; // UNUSED

	return (CyTrue);
}

/**
 * This function initializes the various interfaces (GPIF, GPIO, I2C, SPI, USB).
 */
static void CyFxAppInit(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Initialize the p-port block.
	CyU3PPibClock_t pibClock;

	pibClock.clkDiv = 4;
	pibClock.clkSrc = CY_U3P_SYS_CLK;
	pibClock.isHalfDiv = CyFalse;
	pibClock.isDllEnable = CyFalse; // Disable DLL for sync GPIF!

	status = CyU3PPibInit(CyTrue, &pibClock);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// Register a callback for notification of PIB interrupts.
	CyU3PPibRegisterCallback(&CyFxPIBErrorCB, CYU3P_PIB_INTR_ERROR);

	// Load the GPIF configuration for Slave FIFO sync mode.
	status = CyU3PGpifLoad(&CyFxGpifConfig);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// Configure watermarks for almost full/almost empty flags. */
	if (FX3_FIFO_DATA_PRODUCER_FX3_SOCKET == CY_U3P_PIB_SOCKET_0) {
		status = CyU3PGpifSocketConfigure(0, FX3_FIFO_DATA_PRODUCER_FX3_SOCKET, FX3_SOCKET_0_WATERMARK, CyFalse, 1);
		if (status != CY_U3P_SUCCESS) {
			goto handle_error;
		}
	}

	if (FX3_FIFO_DATA_CONSUMER_FX3_SOCKET == CY_U3P_PIB_SOCKET_1) {
		status = CyU3PGpifSocketConfigure(1, FX3_FIFO_DATA_CONSUMER_FX3_SOCKET, FX3_SOCKET_1_WATERMARK, CyFalse, 1);
		if (status != CY_U3P_SUCCESS) {
			goto handle_error;
		}
	}

	// Start the GPIF state machine.
	status = CyU3PGpifSMStart(RESET, ALPHA_RESET);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

#if GPIO_SUPPORT_ENABLED == 1
	// Initialize the GPIO interface for the pins.
	status = CyFxGpioInit();
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}
#endif

#if I2C_SUPPORT_ENABLED == 1
	// Initialize the I2C interface for the EEPROM and other devices.
	status = CyFxI2cInit();
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}
#endif

#if SPI_SUPPORT_ENABLED == 1 && GPIF_32BIT_SUPPORT_ENABLED == 0
	// Initialize the SPI interface for the flash memory and other devices.
	status = CyFxSpiInit();
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}
#endif

#if DEVICE_SPECIFIC_INITIALIZATION == 1
	// Do device specific initialization steps (after all blocks have been started, but before USB is enabled).
	status = CyFxHandleCustomINIT_DeviceSpecific();
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}
#endif

	// Start the USB functionality.
	status = CyU3PUsbStart();
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	/* The fast enumeration is the easiest way to setup a USB connection,
	 * where all enumeration phase is handled by the library. Only the
	 * class / vendor requests need to be handled by the application. */
	CyU3PUsbRegisterSetupCallback(CyFxUSBSetupRequestsCB, CyTrue);

	/* Setup the callback to handle the USB events. */
	CyU3PUsbRegisterEventCallback(CyFxUSBEventsCB);

	/* Register a callback to handle LPM requests from the USB 3.0 host. */
	CyU3PUsbRegisterLPMRequestCallback(CyFxLPMRequestsCB);

	/* Set the USB Enumeration descriptors */

	// Super speed device descriptor
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_DEVICE_DESCR, 0, (uint8_t *) CyFxUSB30DeviceDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// High speed device descriptor
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_HS_DEVICE_DESCR, 0, (uint8_t *) CyFxUSB20DeviceDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// BOS descriptor
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_BOS_DESCR, 0, (uint8_t *) CyFxUSBBOSDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// Device qualifier descriptor
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_DEVQUAL_DESCR, 0, (uint8_t *) CyFxUSBDeviceQualDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// Super speed configuration descriptor
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_CONFIG_DESCR, 0, (uint8_t *) CyFxUSBSSConfigDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// High speed configuration descriptor
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_HS_CONFIG_DESCR, 0, (uint8_t *) CyFxUSBHSConfigDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// Full speed configuration descriptor
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_FS_CONFIG_DESCR, 0, (uint8_t *) CyFxUSBFSConfigDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// String descriptor 0
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 0, (uint8_t *) CyFxUSBStringLangIDDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// String descriptor 1 - Manufacturer
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 1, (uint8_t *) CyFxUSBManufacturerDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// String descriptor 2 - Product
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 2, (uint8_t *) CyFxUSBProductDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// String descriptor 3 - Serial Number
	status = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 3, (uint8_t *) CyFxUSBSerialNumberDscr);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	// Connect the USB pins, so that we can enumerate on the host!
	status = CyU3PConnectState(CyTrue, FX3_USB3_ENUMERATION);
	if (status != CY_U3P_SUCCESS) {
		goto handle_error;
	}

	return;

	handle_error:
	// No debug facility ready yet!
	// Cannot recover from this error.
	// Application cannot continue, full reset
	CyU3PDeviceReset(CyFalse);
}

/**
 * Entry function for the Application Thread.
 */
static void CyFxApplicationThreadEntry(uint32_t input) {
	(void) input; // UNUSED

	// Initialize the main application.
	CyFxAppInit();

#if GPIO_SUPPORT_ENABLED == 1
	// Run the GPIO event handling loop.
	CyFxGpioEventHandlerLoop();
#endif
}

/**
 * Entry function for the Heartbeat Thread.
 */
static void CyFxHeartbeatThreadEntry(uint32_t input) {
	(void) input; // UNUSED

	// Initialize the Heartbeat system.
	if (CyFxHeartbeatInit() == CY_U3P_SUCCESS) {
		// Run the Heartbeat system itself.
		CyFxHeartbeatFunctionsExecuteLoop();
	}
}

/**
 * Application define function which creates the threads.
 * DO NOT CHANGE THE FUNCTION SIGNATURE!!!
 */
void CyFxApplicationDefine(void) {
	void *ptr = NULL;
	uint32_t retThrdCreate = CY_U3P_SUCCESS;

	// Allocate the memory for the thread
	ptr = CyU3PMemAlloc(FX3_APPLICATION_THREAD_STACK);

	// Create the thread for the application
	retThrdCreate = CyU3PThreadCreate (&glApplicationThread, // Application thread structure
		(char *)"21:INI_FX3_Application",// Thread ID and name
		&CyFxApplicationThreadEntry,// Application thread entry function
		0,// No input parameter to thread
		ptr,// Pointer to the allocated thread stack
		FX3_APPLICATION_THREAD_STACK,// Application Thread stack size
		FX3_APPLICATION_THREAD_PRIORITY,// Application Thread priority
		FX3_APPLICATION_THREAD_PRIORITY,// Application Thread preemption threshold
		CYU3P_NO_TIME_SLICE,// No time slice
		CYU3P_AUTO_START// Start the thread immediately
	);

	// Check the return code
	if (retThrdCreate != 0) {
		// Thread Creation failed with the error code retThrdCreate
		// Application cannot continue, full reset
		CyU3PDeviceReset(CyFalse);
	}

	// Allocate the memory for the thread
	ptr = CyU3PMemAlloc(FX3_HEARTBEAT_THREAD_STACK);

	// Create the thread for the heartbeat
	retThrdCreate = CyU3PThreadCreate (&glHeartbeatThread, // Heartbeat thread structure
		(char *)"22:INI_FX3_Heartbeat",// Thread ID and name
		&CyFxHeartbeatThreadEntry,// Heartbeat thread entry function
		0,// No input parameter to thread
		ptr,// Pointer to the allocated thread stack
		FX3_HEARTBEAT_THREAD_STACK,// Heartbeat Thread stack size
		FX3_HEARTBEAT_THREAD_PRIORITY,// Heartbeat Thread priority
		FX3_HEARTBEAT_THREAD_PRIORITY,// Heartbeat Thread preemption threshold
		CYU3P_NO_TIME_SLICE,// No time slice
		CYU3P_AUTO_START// Start the thread immediately
	);

	// Check the return code
	if (retThrdCreate != 0) {
		// Thread Creation failed with the error code retThrdCreate
		// Application cannot continue, full reset
		CyU3PDeviceReset(CyFalse);
	}
}

/**
 * Main function.
 */
int main(void) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	// Initialize the device.
	CyU3PSysClockConfig_t clockConfig;

	clockConfig.setSysClk400 = CyTrue;
	clockConfig.cpuClkDiv = 2;
	clockConfig.dmaClkDiv = 2;
	clockConfig.mmioClkDiv = 2;
	clockConfig.useStandbyClk = CyFalse;
	clockConfig.clkSrc = CY_U3P_SYS_CLK;

	status = CyU3PDeviceInit(&clockConfig);
	if (status != CY_U3P_SUCCESS) {
		goto handle_fatal_error;
	}

	// Initialize the caches. Enable both Instruction and Data Caches.
	status = CyU3PDeviceCacheControl(CyTrue, CyTrue, CyTrue);
	if (status != CY_U3P_SUCCESS) {
		goto handle_fatal_error;
	}

	// Configure the IO matrix for the device.
	CyU3PIoMatrixConfig_t ioConfig;

	// Initialize to all simple GPIOs disabled.
	ioConfig.gpioSimpleEn[0] = 0;
	ioConfig.gpioSimpleEn[1] = 0;

#if GPIO_SUPPORT_ENABLED == 1
	// Parse the GPIO configuration for later use and enable simple GPIOs based on configuration.
	status = CyFxGpioConfigParse(&ioConfig.gpioSimpleEn[0], &ioConfig.gpioSimpleEn[1]);
	if (status != CY_U3P_SUCCESS) {
		goto handle_fatal_error;
	}
#endif

	// Never use complex GPIOs.
	ioConfig.gpioComplexEn[0] = 0;
	ioConfig.gpioComplexEn[1] = 0;

	// Enable 32bit GPIF data bus.
#if GPIF_32BIT_SUPPORT_ENABLED == 1
	ioConfig.isDQ32Bit = CyTrue;
#else
	ioConfig.isDQ32Bit = CyFalse;
#endif

	// Enable I2C block.
#if I2C_SUPPORT_ENABLED == 1
	// Verify the I2C configuration first.
	status = CyFxI2cConfigParse();
	if (status != CY_U3P_SUCCESS) {
		goto handle_fatal_error;
	}

	ioConfig.useI2C = CyTrue;
#else
	ioConfig.useI2C = CyFalse;
#endif

	// Enable SPI block.
#if SPI_SUPPORT_ENABLED == 1 && GPIF_32BIT_SUPPORT_ENABLED == 0 // No SPI available on 32-bit!
	// Verify the SPI configuration first.
	status = CyFxSpiConfigParse(&ioConfig.gpioSimpleEn[0], &ioConfig.gpioSimpleEn[1]);
	if (status != CY_U3P_SUCCESS) {
		goto handle_fatal_error;
	}

	ioConfig.useSpi = CyTrue;
#else
	ioConfig.useSpi = CyFalse;
#endif

	// Disable remaining interfaces (UART, I2S).
	ioConfig.useUart = CyFalse;
	ioConfig.useI2S = CyFalse;
	ioConfig.lppMode = CY_U3P_IO_MATRIX_LPP_DEFAULT;
	ioConfig.s0Mode = CY_U3P_SPORT_INACTIVE;
	ioConfig.s1Mode = CY_U3P_SPORT_INACTIVE;

	status = CyU3PDeviceConfigureIOMatrix(&ioConfig);
	if (status != CY_U3P_SUCCESS) {
		goto handle_fatal_error;
	}

	// This is a non returnable call for initializing the RTOS kernel
	CyU3PKernelEntry();

	// Dummy return to make the compiler happy
	return (EXIT_SUCCESS);

	handle_fatal_error:
	// Cannot recover from this error.
	// Application cannot continue, full reset
	CyU3PDeviceReset(CyFalse);
}
