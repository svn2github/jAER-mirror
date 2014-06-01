#include "fx3.h"

#if SRC_SINK == 1

spiConfig_DeviceSpecific_Type spiConfig_DeviceSpecific[] = {
	{ 0, 3, 256, 512 * KILOBYTE, 33 * MEGAHERTZ, CyFalse }, /* Default dev-kit SPI Flash (512KB, 33Mhz, SS: default line, active-low) */
};
const uint8_t spiConfig_DeviceSpecific_Length = (sizeof(spiConfig_DeviceSpecific) / sizeof(spiConfig_DeviceSpecific[0]));

void CyFxDmaUSBtoFX3Callback(CyU3PDmaChannel *chHandle, CyU3PDmaCbType_t type, CyU3PDmaCBInput_t *input) {
	(void) type; // UNUSED
	(void) input; // UNUSED

	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	status = CyU3PDmaChannelDiscardBuffer(chHandle);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyU3PDmaChannelDiscardBuffer failed", status);
		return;
	}
}

void CyFxDmaUSBtoFX3CallbackInit(CyU3PDmaChannel *chHandle) {
	(void) chHandle; // UNUSED
}

void CyFxDmaUSBtoFX3CallbackDestroy(CyU3PDmaChannel *chHandle) {
	(void) chHandle; // UNUSED
}

void CyFxDmaFX3toUSBCallback(CyU3PDmaChannel *chHandle, CyU3PDmaCbType_t type, CyU3PDmaCBInput_t *input) {
	(void) type; // UNUSED
	(void) input; // UNUSED

	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;
	CyU3PDmaBuffer_t buffer;

	status = CyU3PDmaChannelGetBuffer(chHandle, &buffer, CYU3P_NO_WAIT);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyU3PDmaChannelGetBuffer failed", status);
		return;
	}

	status = CyU3PDmaChannelCommitBuffer(chHandle, buffer.size, 0);
	if (status != CY_U3P_SUCCESS) {
		CyFxErrorHandler(LOG_ERROR, "CyU3PDmaChannelCommitBuffer failed", status);
		return;
	}
}

void CyFxDmaFX3toUSBCallbackInit(CyU3PDmaChannel *chHandle) {
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;
	CyU3PDmaBuffer_t buffer;

	for (size_t i = 0; i < FX3_FIFO_DATA_DMA_FX3TOUSB_BUF_COUNT; i++) {
		status = CyU3PDmaChannelGetBuffer(chHandle, &buffer, CYU3P_NO_WAIT);
		if (status != CY_U3P_SUCCESS) {
			CyFxErrorHandler(LOG_ERROR, "CyU3PDmaChannelGetBuffer failed", status);
			continue;
		}

		// Set a fixed pattern of 0xFF in the test buffers.
		memset(buffer.buffer, 0xFF, buffer.size);

		status = CyU3PDmaChannelCommitBuffer(chHandle, buffer.size, 0);
		if (status != CY_U3P_SUCCESS) {
			CyFxErrorHandler(LOG_ERROR, "CyU3PDmaChannelCommitBuffer failed", status);
			continue;
		}
	}
}

void CyFxDmaFX3toUSBCallbackDestroy(CyU3PDmaChannel *chHandle) {
	(void) chHandle; // UNUSED
}

#endif /* SRC_SINK */
