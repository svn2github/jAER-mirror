#include "davis_common.h"
#include <pthread.h>
#include <unistd.h>

static inline void checkMonotonicTimestamp(davisHandle handle) {
	if (handle->state.currentTimestamp <= handle->state.lastTimestamp) {
		caerLog(LOG_ALERT, handle->info.deviceString,
			"Timestamps: non strictly-monotonic timestamp detected: lastTimestamp=%" PRIu32 ", currentTimestamp=%" PRIu32 ", difference=%" PRIu32 ".",
			handle->state.lastTimestamp, handle->state.currentTimestamp,
			(handle->state.lastTimestamp - handle->state.currentTimestamp));
	}
}

static inline void initFrame(davisHandle handle, caerFrameEvent currentFrameEvent) {
	handle->state.apsCurrentReadoutType = APS_READOUT_RESET;
	for (size_t j = 0; j < APS_READOUT_TYPES_NUM; j++) {
		handle->state.apsCountX[j] = 0;
		handle->state.apsCountY[j] = 0;
	}

	if (currentFrameEvent != NULL) {
		// Write out start of frame timestamp.
		caerFrameEventSetTSStartOfFrame(currentFrameEvent, handle->state.currentTimestamp);

		// Allocate memory for pixels.
		caerFrameEventAllocatePixels(currentFrameEvent, handle->state.apsWindow0SizeX, handle->state.apsWindow0SizeY,
			1);
	}
}

static inline bool isDavisPixel(uint16_t xPos, uint16_t yPos) {
	if (((xPos & 0x01) == 1) && ((yPos & 0x01) == 0)) {
		return (true);
	}

	return (false);
}

static inline float calculateIMUAccelScale(uint8_t imuAccelScale) {
	// Accelerometer scale is:
	// 0 - +-2 g - 16384 LSB/g
	// 1 - +-4 g - 8192 LSB/g
	// 2 - +-8 g - 4096 LSB/g
	// 3 - +-16 g - 2048 LSB/g
	float accelScale = 65536.0f / (float) U32T(4 * (1 << imuAccelScale));

	return (accelScale);
}

static inline float calculateIMUGyroScale(uint8_t imuGyroScale) {
	// Gyroscope scale is:
	// 0 - +-250 °/s - 131 LSB/°/s
	// 1 - +-500 °/s - 65.5 LSB/°/s
	// 2 - +-1000 °/s - 32.8 LSB/°/s
	// 3 - +-2000 °/s - 16.4 LSB/°/s
	float gyroScale = 65536.0f / (float) U32T(500 * (1 << imuGyroScale));

	return (gyroScale);
}

static void freeAllMemory(davisHandle handle) {
	if (handle->state.currentPolarityPacket != NULL) {
		free(handle->state.currentPolarityPacket);
		handle->state.currentPolarityPacket = NULL;
	}

	if (handle->state.currentFramePacket != NULL) {
		free(handle->state.currentFramePacket);
		handle->state.currentFramePacket = NULL;
	}

	if (handle->state.currentIMU6Packet != NULL) {
		free(handle->state.currentIMU6Packet);
		handle->state.currentIMU6Packet = NULL;
	}

	if (handle->state.currentSpecialPacket != NULL) {
		free(handle->state.currentSpecialPacket);
		handle->state.currentSpecialPacket = NULL;
	}

	if (handle->state.apsCurrentResetFrame != NULL) {
		free(handle->state.apsCurrentResetFrame);
		handle->state.apsCurrentResetFrame = NULL;
	}

	if (handle->state.apsCurrentSignalFrame != NULL) {
		free(handle->state.apsCurrentSignalFrame);
		handle->state.apsCurrentSignalFrame = NULL;
	}

	if (handle->state.dataExchangeBuffer != NULL) {
		ringBufferFree(handle->state.dataExchangeBuffer);
		handle->state.dataExchangeBuffer = NULL;
	}

	if (handle->info.deviceString != NULL) {
		free(handle->info.deviceString);
		handle->info.deviceString = NULL;
	}
}

void spiConfigSend(libusb_device_handle *devHandle, uint8_t moduleAddr, uint8_t paramAddr, uint32_t param) {
	uint8_t spiConfig[4] = { 0 };

	spiConfig[0] = U8T(param >> 24);
	spiConfig[1] = U8T(param >> 16);
	spiConfig[2] = U8T(param >> 8);
	spiConfig[3] = U8T(param >> 0);

	libusb_control_transfer(devHandle, LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
	VR_FPGA_CONFIG, moduleAddr, paramAddr, spiConfig, sizeof(spiConfig), 0);
}

uint32_t spiConfigReceive(libusb_device_handle *devHandle, uint8_t moduleAddr, uint8_t paramAddr) {
	uint32_t returnedParam = 0;
	uint8_t spiConfig[4] = { 0 };

	libusb_control_transfer(devHandle, LIBUSB_ENDPOINT_IN | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
	VR_FPGA_CONFIG, moduleAddr, paramAddr, spiConfig, sizeof(spiConfig), 0);

	returnedParam |= U32T(spiConfig[0] << 24);
	returnedParam |= U32T(spiConfig[1] << 16);
	returnedParam |= U32T(spiConfig[2] << 8);
	returnedParam |= U32T(spiConfig[3] << 0);

	return (returnedParam);
}

bool davisOpen(davisHandle handle, uint16_t VID, uint16_t PID, uint8_t DID_TYPE, uint8_t busNumberRestrict,
	uint8_t devAddressRestrict, const char *serialNumberRestrict) {
	// Initialize libusb using a separate context for each device.
	// This is to correctly support one thread per device.
	if ((errno = libusb_init(&handle->state.deviceContext)) != LIBUSB_SUCCESS) {
		caerLog(LOG_CRITICAL, "DAVIS", "Failed to initialize libusb context. Error: %s (%d).", libusb_strerror(errno),
			errno);
		return (false);
	}

	// Try to open a DAVIS device on a specific USB port.
	handle->state.deviceHandle = deviceOpen(handle->state.deviceContext, VID, PID, DID_TYPE, busNumberRestrict,
		devAddressRestrict);
	if (handle->state.deviceHandle == NULL) {
		libusb_exit(handle->state.deviceContext);

		caerLog(LOG_CRITICAL, "DAVIS", "Failed to open device.");
		return (false);
	}

	// At this point we can get some more precise data on the device and update
	// the logging string to reflect that and be more informative.
	uint8_t busNumber = libusb_get_bus_number(libusb_get_device(handle->state.deviceHandle));
	uint8_t devAddress = libusb_get_device_address(libusb_get_device(handle->state.deviceHandle));

	char serialNumber[8 + 1];
	libusb_get_string_descriptor_ascii(handle->state.deviceHandle, 3, (unsigned char *) serialNumber, 8 + 1);
	serialNumber[8] = '\0'; // Ensure NUL termination.

	size_t fullLogStringLength = (size_t) snprintf(NULL, 0, "%s SN-%s [%" PRIu8 ":%" PRIu8 "]", "DAVIS", serialNumber,
		busNumber, devAddress);

	char *fullLogString = malloc(fullLogStringLength + 1);
	if (fullLogString == NULL) {
		caerLog(LOG_CRITICAL, "DAVIS", "Unable to allocate memory for device log string.");
	}

	snprintf(fullLogString, fullLogStringLength + 1, "%s SN-%s [%" PRIu8 ":%" PRIu8 "]", "DAVIS", serialNumber,
		busNumber, devAddress);

	// Update module log string, make it accessible in cstate space.
	handle->info.deviceString = fullLogString;

	// Now check if the Serial Number matches.
	if (!str_equals(serialNumberRestrict, "") && !str_equals(serialNumberRestrict, serialNumber)) {
		libusb_close(handle->state.deviceHandle);
		libusb_exit(handle->state.deviceContext);

		caerLog(LOG_CRITICAL, handle->info.deviceString, "Device Serial Number doesn't match.");
		return (false);
	}

	return (true);
}

bool davisInfoInitialize(davisHandle handle) {
	// So now we have a working connection to the device we want. Let's get some data!
	handle->info.apsSizeX = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 0));
	handle->info.apsSizeY = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 1));

	uint8_t apsOrientationInfo = U8T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 2));
	handle->state.apsInvertXY = apsOrientationInfo & 0x04;
	handle->state.apsFlipX = apsOrientationInfo & 0x02;
	handle->state.apsFlipY = apsOrientationInfo & 0x01;

	handle->info.apsColorFilter = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 3);

	handle->info.apsHasGlobalShutter = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 7);
	handle->info.apsHasQuadROI = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 19);
	handle->info.apsHasExternalADC = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 32);
	handle->info.apsHasInternalADC = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_APS, 33);

	handle->info.dvsSizeX = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_DVS, 0));
	handle->info.dvsSizeY = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_DVS, 1));

	handle->state.dvsInvertXY = U8T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_DVS, 2)) & 0x04;

	handle->info.dvsHasPixelFilter = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_DVS, 11);
	handle->info.dvsHasBackgroundActivityFilter = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_DVS, 28);

	handle->info.extInputHasGenerator = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_EXTINPUT, 6);

	handle->info.logicVersion = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_SYSINFO, 0));
	handle->info.chipID = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_SYSINFO, 1));
	handle->info.deviceIsMaster = spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_SYSINFO, 2);
	handle->info.logicClock = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_SYSINFO, 3));
	handle->info.adcClock = U16T(spiConfigReceive(handle->state.deviceHandle, DAVIS_CONFIG_SYSINFO, 4));

	return (true);
}

bool davisStateInitialize(davisHandle handle) {
	// Initialize state fields.
	updatePacketSizesIntervals(moduleData->moduleNode, cstate);

	cstate->currentPolarityPacket = caerPolarityEventPacketAllocate(cstate->maxPolarityPacketSize, cstate->sourceID);

	cstate->currentFramePacket = caerFrameEventPacketAllocate(cstate->maxFramePacketSize, cstate->sourceID,
		cstate->apsSizeX, cstate->apsSizeY, DAVIS_COLOR_CHANNELS);

	cstate->currentIMU6Packet = caerIMU6EventPacketAllocate(cstate->maxIMU6PacketSize, cstate->sourceID);

	cstate->currentSpecialPacket = caerSpecialEventPacketAllocate(cstate->maxSpecialPacketSize, cstate->sourceID);

	cstate->imuAccelScale = calculateIMUAccelScale(sshsNodeGetByte(imuNode, "AccelFullScale"));
	cstate->imuGyroScale = calculateIMUGyroScale(sshsNodeGetByte(imuNode, "GyroFullScale"));

	cstate->apsWindow0SizeX = U16T(
		sshsNodeGetShort(apsNode, "EndColumn0") + 1 - sshsNodeGetShort(apsNode, "StartColumn0"));
	cstate->apsWindow0SizeY = U16T(sshsNodeGetShort(apsNode, "EndRow0") + 1 - sshsNodeGetShort(apsNode, "StartRow0"));

	cstate->apsGlobalShutter = sshsNodeGetBool(apsNode, "GlobalShutter");

	cstate->apsResetRead = sshsNodeGetBool(apsNode, "ResetRead");

	initFrame(cstate, NULL);
	cstate->apsCurrentResetFrame = calloc((size_t) cstate->apsSizeX * cstate->apsSizeY * DAVIS_COLOR_CHANNELS,
		sizeof(uint16_t));
	if (cstate->apsCurrentResetFrame == NULL) {
		freeAllMemory(cstate);

		caerLog(LOG_CRITICAL, moduleData->moduleSubSystemString, "Failed to allocate reset frame array.");
		return (false);
	}
	if (cstate->chipID == CHIP_DAVISRGB) {
		cstate->apsCurrentSignalFrame = calloc((size_t) cstate->apsSizeX * cstate->apsSizeY * DAVIS_COLOR_CHANNELS,
			sizeof(uint16_t));
		if (cstate->apsCurrentSignalFrame == NULL) {
			freeAllMemory(cstate);

			caerLog(LOG_CRITICAL, moduleData->moduleSubSystemString, "Failed to allocate signal frame array.");
			return (false);
		}
	}

	return (true);
}

caerEventPacketContainer davisDataStart(davisHandle handle, void *dataAcquisitionThread(void *inPtr)) {
	// Create data exchange buffers. Size is fixed until module restart.
	handle->state.dataExchangeBuffer = ringBufferInit(
		sshsNodeGetInt(sshsGetRelativeNode(moduleData->moduleNode, "system/"), "DataExchangeBufferSize"));
	if (handle->state.dataExchangeBuffer == NULL) {
		freeAllMemory(cstate);

		caerLog(LOG_CRITICAL, handle->info.deviceString, "Failed to initialize data exchange buffer.");
		return (false);
	}

	// Start data acquisition thread.
	if ((errno = pthread_create(&handle->state.dataAcquisitionThread, NULL, dataAcquisitionThread, handle)) != 0) {
		freeAllMemory(cstate);

		caerLog(LOG_CRITICAL, handle->info.deviceString, "Failed to start data acquisition thread. Error: %s (%d).",
			caerLogStrerror(errno), errno);
		return (false);
	}
}

bool davisDataStop(davisHandle handle) {
	// Disable all data transfer on USB end-point.
	sendDisableDataConfig(handle->state.deviceHandle);

	// Wait for data acquisition thread to terminate...
	if ((errno = pthread_join(handle->state.dataAcquisitionThread, NULL)) != 0) {
		// This should never happen!
		caerLog(LOG_CRITICAL, handle->info.deviceString, "Failed to join data acquisition thread. Error: %s (%d).",
			caerLogStrerror(errno), errno);
	}

	// Empty ringbuffer.
	void *packet;
	while ((packet = ringBufferGet(handle->state.dataExchangeBuffer)) != NULL) {
		caerMainloopDataAvailableDecrease(handle->state.dataNotify);
		free(packet);
	}
}

void caerInputDAVISCommonExit(caerModuleData moduleData) {
	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString, "Shutting down ...");

	// The common state is always the first member of the moduleState structure
	// for the DAVIS modules, so we can trust it being at address offset 0.
	davisCommonState cstate = moduleData->moduleState;

	// Finally, close the device fully.
	deviceClose(cstate->deviceHandle);

	// Destroy libusb context.
	libusb_exit(cstate->deviceContext);

	// Free remaining incomplete packets.
	freeAllMemory(cstate);

	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString, "Shutdown successful.");
}

void caerInputDAVISCommonRun(caerModuleData moduleData, size_t argsNumber, va_list args) {
	UNUSED_ARGUMENT(argsNumber);

	// Interpret variable arguments (same as above in main function).
	caerPolarityEventPacket *polarity = va_arg(args, caerPolarityEventPacket *);
	caerFrameEventPacket *frame = va_arg(args, caerFrameEventPacket *);
	caerIMU6EventPacket *imu6 = va_arg(args, caerIMU6EventPacket *);
	caerSpecialEventPacket *special = va_arg(args, caerSpecialEventPacket *);

	davisCommonState state = moduleData->moduleState;

	// Check what the user wants.
	bool wantPolarity = false, havePolarity = false;
	bool wantFrame = false, haveFrame = false;
	bool wantIMU6 = false, haveIMU6 = false;
	bool wantSpecial = false, haveSpecial = false;

	if (polarity != NULL) {
		wantPolarity = true;
	}

	if (frame != NULL) {
		wantFrame = true;
	}

	if (imu6 != NULL) {
		wantIMU6 = true;
	}

	if (special != NULL) {
		wantSpecial = true;
	}

	void *packet;
	while ((packet = ringBufferLook(state->dataExchangeBuffer)) != NULL) {
		// Check what kind it is and assign accordingly.
		caerEventPacketHeader packetHeader = packet;

		// Check polarity events first, then frame, then IMU6, finally special.
		if (packetHeader->eventType == POLARITY_EVENT) {
			// Throw away unwanted packets first.
			if (!wantPolarity) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				free(ringBufferGet(state->dataExchangeBuffer));
				continue;
			}

			// At this point packet is something we want, so we see if we can
			// assign it to one of the output pointers. This will be possible if
			// the output is still free, if not, we have to wait until next loop
			// iteration to fit this somewhere, and so we exit.
			if (!havePolarity) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				*polarity = ringBufferGet(state->dataExchangeBuffer);
				havePolarity = true;

				// Ensure memory gets recycled after the loop is over.
				caerMainloopFreeAfterLoop(*polarity);

				continue;
			}

			// Couldn't fit the current packet into any free output pointers,
			// break off and defer to next iteration of mainloop.
			break;
		}
		else if (packetHeader->eventType == FRAME_EVENT) {
			// Throw away unwanted packets first.
			if (!wantFrame) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				free(ringBufferGet(state->dataExchangeBuffer));
				continue;
			}

			// At this point packet is something we want, so we see if we can
			// assign it to one of the output pointers. This will be possible if
			// the output is still free, if not, we have to wait until next loop
			// iteration to fit this somewhere, and so we exit.
			if (!haveFrame) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				*frame = ringBufferGet(state->dataExchangeBuffer);
				haveFrame = true;

				// Ensure memory gets recycled after the loop is over.
				caerMainloopFreeAfterLoop(*frame);

				continue;
			}

			// Couldn't fit the current packet into any free output pointers,
			// break off and defer to next iteration of mainloop.
			break;
		}
		else if (packetHeader->eventType == IMU6_EVENT) {
			// Throw away unwanted packets first.
			if (!wantIMU6) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				free(ringBufferGet(state->dataExchangeBuffer));
				continue;
			}

			// At this point packet is something we want, so we see if we can
			// assign it to one of the output pointers. This will be possible if
			// the output is still free, if not, we have to wait until next loop
			// iteration to fit this somewhere, and so we exit.
			if (!haveIMU6) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				*imu6 = ringBufferGet(state->dataExchangeBuffer);
				haveIMU6 = true;

				// Ensure memory gets recycled after the loop is over.
				caerMainloopFreeAfterLoop(*imu6);

				continue;
			}

			// Couldn't fit the current packet into any free output pointers,
			// break off and defer to next iteration of mainloop.
			break;
		}
		else if (packetHeader->eventType == SPECIAL_EVENT) {
			// Throw away unwanted packets first.
			if (!wantSpecial) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				free(ringBufferGet(state->dataExchangeBuffer));
				continue;
			}

			// At this point packet is something we want, so we see if we can
			// assign it to one of the output pointers. This will be possible if
			// the output is still free, if not, we have to wait until next loop
			// iteration to fit this somewhere, and so we exit.
			if (!haveSpecial) {
				caerMainloopDataAvailableDecrease(state->mainloopNotify);
				*special = ringBufferGet(state->dataExchangeBuffer);
				haveSpecial = true;

				// Ensure memory gets recycled after the loop is over.
				caerMainloopFreeAfterLoop(*special);

				continue;
			}

			// Couldn't fit the current packet into any free output pointers,
			// break off and defer to next iteration of mainloop.
			break;
		}
	}
}

void allocateDataTransfers(davisCommonState state, uint32_t bufferNum, uint32_t bufferSize) {
	// Set number of transfers and allocate memory for the main transfer array.
	state->dataTransfers = calloc(bufferNum, sizeof(struct libusb_transfer *));
	if (state->dataTransfers == NULL) {
		caerLog(LOG_CRITICAL, state->sourceSubSystemString,
			"Failed to allocate memory for %" PRIu32 " libusb transfers (data channel). Error: %s (%d).", bufferNum,
			caerLogStrerror(errno), errno);
		return;
	}
	state->dataTransfersLength = bufferNum;

	// Allocate transfers and set them up.
	for (size_t i = 0; i < bufferNum; i++) {
		state->dataTransfers[i] = libusb_alloc_transfer(0);
		if (state->dataTransfers[i] == NULL) {
			caerLog(LOG_CRITICAL, state->sourceSubSystemString,
				"Unable to allocate further libusb transfers (data channel, %zu of %" PRIu32 ").", i, bufferNum);
			continue;
		}

		// Create data buffer.
		state->dataTransfers[i]->length = (int) bufferSize;
		state->dataTransfers[i]->buffer = malloc(bufferSize);
		if (state->dataTransfers[i]->buffer == NULL) {
			caerLog(LOG_CRITICAL, state->sourceSubSystemString,
				"Unable to allocate buffer for libusb transfer %zu (data channel). Error: %s (%d).", i,
				caerLogStrerror(errno), errno);

			libusb_free_transfer(state->dataTransfers[i]);
			state->dataTransfers[i] = NULL;

			continue;
		}

		// Initialize Transfer.
		state->dataTransfers[i]->dev_handle = state->deviceHandle;
		state->dataTransfers[i]->endpoint = DATA_ENDPOINT;
		state->dataTransfers[i]->type = LIBUSB_TRANSFER_TYPE_BULK;
		state->dataTransfers[i]->callback = &libUsbDataCallback;
		state->dataTransfers[i]->user_data = state;
		state->dataTransfers[i]->timeout = 0;
		state->dataTransfers[i]->flags = LIBUSB_TRANSFER_FREE_BUFFER;

		if ((errno = libusb_submit_transfer(state->dataTransfers[i])) == LIBUSB_SUCCESS) {
			state->activeDataTransfers++;
		}
		else {
			caerLog(LOG_CRITICAL, state->sourceSubSystemString,
				"Unable to submit libusb transfer %zu (data channel). Error: %s (%d).", i, libusb_strerror(errno),
				errno);

			// The transfer buffer is freed automatically here thanks to
			// the LIBUSB_TRANSFER_FREE_BUFFER flag set above.
			libusb_free_transfer(state->dataTransfers[i]);
			state->dataTransfers[i] = NULL;

			continue;
		}
	}

	if (state->activeDataTransfers == 0) {
		// Didn't manage to allocate any USB transfers, free array memory and log failure.
		free(state->dataTransfers);
		state->dataTransfers = NULL;
		state->dataTransfersLength = 0;

		caerLog(LOG_CRITICAL, state->sourceSubSystemString, "Unable to allocate any libusb transfers.");
	}
}

void deallocateDataTransfers(davisCommonState state) {
	// Cancel all current transfers first.
	for (size_t i = 0; i < state->dataTransfersLength; i++) {
		if (state->dataTransfers[i] != NULL) {
			errno = libusb_cancel_transfer(state->dataTransfers[i]);
			if (errno != LIBUSB_SUCCESS && errno != LIBUSB_ERROR_NOT_FOUND) {
				caerLog(LOG_CRITICAL, state->sourceSubSystemString,
					"Unable to cancel libusb transfer %zu (data channel). Error: %s (%d).", i, libusb_strerror(errno),
					errno);
				// Proceed with trying to cancel all transfers regardless of errors.
			}
		}
	}

	// Wait for all transfers to go away (0.1 seconds timeout).
	struct timeval te = { .tv_sec = 0, .tv_usec = 100000 };

	while (state->activeDataTransfers > 0) {
		libusb_handle_events_timeout(state->deviceContext, &te);
	}

	// The buffers and transfers have been deallocated in the callback.
	// Only the transfers array remains, which we free here.
	free(state->dataTransfers);
	state->dataTransfers = NULL;
	state->dataTransfersLength = 0;
}

static void LIBUSB_CALL libUsbDataCallback(struct libusb_transfer *transfer) {
	davisCommonState state = transfer->user_data;

	if (transfer->status == LIBUSB_TRANSFER_COMPLETED) {
		// Handle event data.
		dataTranslator(state, transfer->buffer, (size_t) transfer->actual_length);
	}

	if (transfer->status != LIBUSB_TRANSFER_CANCELLED && transfer->status != LIBUSB_TRANSFER_NO_DEVICE) {
		// Submit transfer again.
		if (libusb_submit_transfer(transfer) == LIBUSB_SUCCESS) {
			return;
		}
	}

	// Cannot recover (cancelled, no device, or other critical error).
	// Signal this by adjusting the counter, free and exit.
	state->activeDataTransfers--;
	for (size_t i = 0; i < state->dataTransfersLength; i++) {
		// Remove from list, so we don't try to cancel it later on.
		if (state->dataTransfers[i] == transfer) {
			state->dataTransfers[i] = NULL;
		}
	}
	libusb_free_transfer(transfer);
}

static void dataTranslator(davisCommonState state, uint8_t *buffer, size_t bytesSent) {
	// Truncate off any extra partial event.
	if ((bytesSent & 0x01) != 0) {
		caerLog(LOG_ALERT, state->sourceSubSystemString, "%zu bytes received via USB, which is not a multiple of two.",
			bytesSent);
		bytesSent &= (size_t) ~0x01;
	}

	for (size_t i = 0; i < bytesSent; i += 2) {
		bool forcePacketCommit = false;

		uint16_t event = le16toh(*((uint16_t * ) (&buffer[i])));

		// Check if timestamp.
		if ((event & 0x8000) != 0) {
			// Is a timestamp! Expand to 32 bits. (Tick is 1µs already.)
			state->lastTimestamp = state->currentTimestamp;
			state->currentTimestamp = state->wrapAdd + (event & 0x7FFF);

			// Check monotonicity of timestamps.
			checkMonotonicTimestamp(state);
		}
		else {
			// Get all current events, so we don't have to duplicate code in every branch.
			caerPolarityEvent currentPolarityEvent = caerPolarityEventPacketGetEvent(state->currentPolarityPacket,
				state->currentPolarityPacketPosition);
			caerFrameEvent currentFrameEvent = caerFrameEventPacketGetEvent(state->currentFramePacket,
				state->currentFramePacketPosition);
			caerIMU6Event currentIMU6Event = caerIMU6EventPacketGetEvent(state->currentIMU6Packet,
				state->currentIMU6PacketPosition);
			caerSpecialEvent currentSpecialEvent = caerSpecialEventPacketGetEvent(state->currentSpecialPacket,
				state->currentSpecialPacketPosition);

			// Look at the code, to determine event and data type.
			uint8_t code = (uint8_t) ((event & 0x7000) >> 12);
			uint16_t data = (event & 0x0FFF);

			switch (code) {
				case 0: // Special event
					switch (data) {
						case 0: // Ignore this, but log it.
							caerLog(LOG_ERROR, state->sourceSubSystemString, "Caught special reserved event!");
							break;

						case 1: { // Timetamp reset
							state->wrapAdd = 0;
							state->lastTimestamp = 0;
							state->currentTimestamp = 0;
							state->dvsTimestamp = 0;

							caerLog(LOG_INFO, state->sourceSubSystemString, "Timestamp reset event received.");

							// Create timestamp reset event.
							caerSpecialEventSetTimestamp(currentSpecialEvent, UINT32_MAX);
							caerSpecialEventSetType(currentSpecialEvent, TIMESTAMP_RESET);
							caerSpecialEventValidate(currentSpecialEvent, state->currentSpecialPacket);
							state->currentSpecialPacketPosition++;

							// Commit packets when doing a reset to clearly separate them.
							forcePacketCommit = true;

							// Update Master/Slave status on incoming TS resets.
							//sshsNode sourceInfoNode = caerMainloopGetSourceInfo(state->sourceID);
							//sshsNodePutBool(sourceInfoNode, "deviceIsMaster",
							//	spiConfigReceive(state->deviceHandle, FPGA_SYSINFO, 2));

							break;
						}

						case 2: { // External input (falling edge)
							caerLog(LOG_DEBUG, state->sourceSubSystemString,
								"External input (falling edge) event received.");

							caerSpecialEventSetTimestamp(currentSpecialEvent, state->currentTimestamp);
							caerSpecialEventSetType(currentSpecialEvent, EXTERNAL_INPUT_FALLING_EDGE);
							caerSpecialEventValidate(currentSpecialEvent, state->currentSpecialPacket);
							state->currentSpecialPacketPosition++;
							break;
						}

						case 3: { // External input (rising edge)
							caerLog(LOG_DEBUG, state->sourceSubSystemString,
								"External input (rising edge) event received.");

							caerSpecialEventSetTimestamp(currentSpecialEvent, state->currentTimestamp);
							caerSpecialEventSetType(currentSpecialEvent, EXTERNAL_INPUT_RISING_EDGE);
							caerSpecialEventValidate(currentSpecialEvent, state->currentSpecialPacket);
							state->currentSpecialPacketPosition++;
							break;
						}

						case 4: { // External input (pulse)
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "External input (pulse) event received.");

							caerSpecialEventSetTimestamp(currentSpecialEvent, state->currentTimestamp);
							caerSpecialEventSetType(currentSpecialEvent, EXTERNAL_INPUT_PULSE);
							caerSpecialEventValidate(currentSpecialEvent, state->currentSpecialPacket);
							state->currentSpecialPacketPosition++;
							break;
						}

						case 5: { // IMU Start (6 axes)
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "IMU6 Start event received.");

							state->imuIgnoreEvents = false;
							state->imuCount = 0;

							caerIMU6EventSetTimestamp(currentIMU6Event, state->currentTimestamp);
							break;
						}

						case 7: // IMU End
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "IMU End event received.");
							if (state->imuIgnoreEvents) {
								break;
							}

							if (state->imuCount == IMU6_COUNT) {
								caerIMU6EventValidate(currentIMU6Event, state->currentIMU6Packet);
								state->currentIMU6PacketPosition++;
							}
							else {
								caerLog(LOG_INFO, state->sourceSubSystemString,
									"IMU End: failed to validate IMU sample count (%" PRIu8 "), discarding samples.",
									state->imuCount);
							}
							break;

						case 8: { // APS Global Shutter Frame Start
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS GS Frame Start event received.");
							state->apsIgnoreEvents = false;
							state->apsGlobalShutter = true;
							state->apsResetRead = true;

							initFrame(state, currentFrameEvent);

							break;
						}

						case 9: { // APS Rolling Shutter Frame Start
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS RS Frame Start event received.");
							state->apsIgnoreEvents = false;
							state->apsGlobalShutter = false;
							state->apsResetRead = true;

							initFrame(state, currentFrameEvent);

							break;
						}

						case 10: { // APS Frame End
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Frame End event received.");
							if (state->apsIgnoreEvents) {
								break;
							}

							bool validFrame = true;

							for (size_t j = 0; j < APS_READOUT_TYPES_NUM; j++) {
								uint16_t checkValue = caerFrameEventGetLengthX(currentFrameEvent);

								// Check main reset read against zero if disabled.
								if (j == APS_READOUT_RESET && !state->apsResetRead) {
									checkValue = 0;
								}

								// Check second reset read (Cp RST, DAVIS RGB).
								if (j == APS_READOUT_CPRESET && state->chipID != CHIP_DAVISRGB) {
									checkValue = 0;
								}

								caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Frame End: CountX[%zu] is %d.", j,
									state->apsCountX[j]);

								if (state->apsCountX[j] != checkValue) {
									caerLog(LOG_ERROR, state->sourceSubSystemString,
										"APS Frame End: wrong column count [%zu - %d] detected.", j,
										state->apsCountX[j]);
									validFrame = false;
								}
							}

							// Write out end of frame timestamp.
							caerFrameEventSetTSEndOfFrame(currentFrameEvent, state->currentTimestamp);

							// Validate event and advance frame packet position.
							if (validFrame) {
								caerFrameEventValidate(currentFrameEvent, state->currentFramePacket);
							}
							state->currentFramePacketPosition++;

							break;
						}

						case 11: { // APS Reset Column Start
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Reset Column Start event received.");
							if (state->apsIgnoreEvents) {
								break;
							}

							state->apsCurrentReadoutType = APS_READOUT_RESET;
							state->apsCountY[state->apsCurrentReadoutType] = 0;

							state->apsRGBPixelOffsetDirection = 0;
							state->apsRGBPixelOffset = 1; // RGB support, first pixel of row always even.

							// The first Reset Column Read Start is also the start
							// of the exposure for the RS.
							if (!state->apsGlobalShutter && state->apsCountX[APS_READOUT_RESET] == 0) {
								caerFrameEventSetTSStartOfExposure(currentFrameEvent, state->currentTimestamp);
							}

							break;
						}

						case 12: { // APS Signal Column Start
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Signal Column Start event received.");
							if (state->apsIgnoreEvents) {
								break;
							}

							state->apsCurrentReadoutType = APS_READOUT_SIGNAL;
							state->apsCountY[state->apsCurrentReadoutType] = 0;

							state->apsRGBPixelOffsetDirection = 0;
							state->apsRGBPixelOffset = 1; // RGB support, first pixel of row always even.

							// The first Signal Column Read Start is also always the end
							// of the exposure time, for both RS and GS.
							if (state->apsCountX[APS_READOUT_SIGNAL] == 0) {
								caerFrameEventSetTSEndOfExposure(currentFrameEvent, state->currentTimestamp);
							}

							break;
						}

						case 13: { // APS Column End
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Column End event received.");
							if (state->apsIgnoreEvents) {
								break;
							}

							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Column End: CountX[%d] is %d.",
								state->apsCurrentReadoutType, state->apsCountX[state->apsCurrentReadoutType]);
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Column End: CountY[%d] is %d.",
								state->apsCurrentReadoutType, state->apsCountY[state->apsCurrentReadoutType]);

							if (state->apsCountY[state->apsCurrentReadoutType]
								!= caerFrameEventGetLengthY(currentFrameEvent)) {
								caerLog(LOG_ERROR, state->sourceSubSystemString,
									"APS Column End: wrong row count [%d - %d] detected.", state->apsCurrentReadoutType,
									state->apsCountY[state->apsCurrentReadoutType]);
							}

							state->apsCountX[state->apsCurrentReadoutType]++;

							// The last Reset Column Read End is also the start
							// of the exposure for the GS.
							if (state->apsGlobalShutter && state->apsCurrentReadoutType == APS_READOUT_RESET
								&& state->apsCountX[APS_READOUT_RESET] == caerFrameEventGetLengthX(currentFrameEvent)) {
								caerFrameEventSetTSStartOfExposure(currentFrameEvent, state->currentTimestamp);
							}

							break;
						}

						case 14: { // APS Global Shutter Frame Start with no Reset Read
							caerLog(LOG_DEBUG, state->sourceSubSystemString,
								"APS GS NORST Frame Start event received.");
							state->apsIgnoreEvents = false;
							state->apsGlobalShutter = true;
							state->apsResetRead = false;

							initFrame(state, currentFrameEvent);

							// If reset reads are disabled, the start of exposure is closest to
							// the start of frame.
							caerFrameEventSetTSStartOfExposure(currentFrameEvent, state->currentTimestamp);

							break;
						}

						case 15: { // APS Rolling Shutter Frame Start with no Reset Read
							caerLog(LOG_DEBUG, state->sourceSubSystemString,
								"APS RS NORST Frame Start event received.");
							state->apsIgnoreEvents = false;
							state->apsGlobalShutter = false;
							state->apsResetRead = false;

							initFrame(state, currentFrameEvent);

							// If reset reads are disabled, the start of exposure is closest to
							// the start of frame.
							caerFrameEventSetTSStartOfExposure(currentFrameEvent, state->currentTimestamp);

							break;
						}

						case 16:
						case 17:
						case 18:
						case 19:
						case 20:
						case 21:
						case 22:
						case 23:
						case 24:
						case 25:
						case 26:
						case 27:
						case 28:
						case 29:
						case 30:
						case 31: {
							caerLog(LOG_DEBUG, state->sourceSubSystemString,
								"IMU Scale Config event (%" PRIu16 ") received.", data);
							if (state->imuIgnoreEvents) {
								break;
							}

							// Set correct IMU accel and gyro scales, used to interpret subsequent
							// IMU samples from the device.
							state->imuAccelScale = calculateIMUAccelScale((data >> 2) & 0x03);
							state->imuGyroScale = calculateIMUGyroScale(data & 0x03);

							// At this point the IMU event count should be zero (reset by start).
							if (state->imuCount != 0) {
								caerLog(LOG_INFO, state->sourceSubSystemString,
									"IMU Scale Config: previous IMU start event missed, attempting recovery.");
							}

							// Increase IMU count by one, to a total of one (0+1=1).
							// This way we can recover from the above error of missing start, and we can
							// later discover if the IMU Scale Config event actually arrived itself.
							state->imuCount = 1;

							break;
						}

						case 32: { // APS Reset2 Column Start
							caerLog(LOG_DEBUG, state->sourceSubSystemString, "APS Reset2 Column Start event received.");
							if (state->apsIgnoreEvents) {
								break;
							}

							state->apsCurrentReadoutType = APS_READOUT_CPRESET;
							state->apsCountY[state->apsCurrentReadoutType] = 0;

							state->apsRGBPixelOffsetDirection = 0;
							state->apsRGBPixelOffset = 1; // RGB support, first pixel of row always even.

							// TODO: figure out exposure time calculation from ADC sample times.

							break;
						}

						default:
							caerLog(LOG_ERROR, state->sourceSubSystemString,
								"Caught special event that can't be handled: %d.", data);
							break;
					}
					break;

				case 1: // Y address
					// Check range conformity.
					if (data >= state->dvsSizeY) {
						caerLog(LOG_ALERT, state->sourceSubSystemString,
							"DVS: Y address out of range (0-%d): %" PRIu16 ".", state->dvsSizeY - 1, data);
						break; // Skip invalid Y address (don't update lastY).
					}

					if (state->dvsGotY) {
						// Use the previous timestamp here, since this refers to the previous Y.
						caerSpecialEventSetTimestamp(currentSpecialEvent, state->dvsTimestamp);
						caerSpecialEventSetType(currentSpecialEvent, DVS_ROW_ONLY);
						caerSpecialEventSetData(currentSpecialEvent, state->dvsLastY);
						caerSpecialEventValidate(currentSpecialEvent, state->currentSpecialPacket);
						state->currentSpecialPacketPosition++;

						caerLog(LOG_DEBUG, state->sourceSubSystemString,
							"DVS: row-only event received for address Y=%" PRIu16 ".", state->dvsLastY);
					}

					state->dvsLastY = data;
					state->dvsGotY = true;
					state->dvsTimestamp = state->currentTimestamp;

					break;

				case 2: // X address, Polarity OFF
				case 3: { // X address, Polarity ON
					// Check range conformity.
					if (data >= state->dvsSizeX) {
						caerLog(LOG_ALERT, state->sourceSubSystemString,
							"DVS: X address out of range (0-%d): %" PRIu16 ".", state->dvsSizeX - 1, data);
						break; // Skip invalid event.
					}

					// Invert polarity for PixelParade high gain pixels (DavisSense), because of
					// negative gain from pre-amplifier.
					uint8_t polarity = ((state->chipID == CHIP_DAVIS208) && (data < 192)) ? ((uint8_t) ~code) : (code);

					caerPolarityEventSetTimestamp(currentPolarityEvent, state->dvsTimestamp);
					caerPolarityEventSetPolarity(currentPolarityEvent, (polarity & 0x01));
					if (state->dvsInvertXY) {
						caerPolarityEventSetY(currentPolarityEvent, data);
						caerPolarityEventSetX(currentPolarityEvent, state->dvsLastY);
					}
					else {
						caerPolarityEventSetY(currentPolarityEvent, state->dvsLastY);
						caerPolarityEventSetX(currentPolarityEvent, data);
					}
					caerPolarityEventValidate(currentPolarityEvent, state->currentPolarityPacket);
					state->currentPolarityPacketPosition++;

					state->dvsGotY = false;

					break;
				}

				case 4: {
					if (state->apsIgnoreEvents) {
						break;
					}

					// Let's check that apsCountY is not above the maximum. This could happen
					// if start/end of column events are discarded (no wait on transfer stall).
					if (state->apsCountY[state->apsCurrentReadoutType] >= caerFrameEventGetLengthY(currentFrameEvent)) {
						caerLog(LOG_DEBUG, state->sourceSubSystemString,
							"APS ADC sample: row count is at maximum, discarding further samples.");
						break;
					}

					// If reset read, we store the values in a local array. If signal read, we
					// store the final pixel value directly in the output frame event. We already
					// do the subtraction between reset and signal here, to avoid carrying that
					// around all the time and consuming memory. This way we can also only take
					// infrequent reset reads and re-use them for multiple frames, which can heavily
					// reduce traffic, and should not impact image quality heavily, at least in GS.
					uint16_t xPos =
						(state->apsFlipX) ?
							(U16T(
								caerFrameEventGetLengthX(currentFrameEvent) - 1
									- state->apsCountX[state->apsCurrentReadoutType])) :
							(U16T(state->apsCountX[state->apsCurrentReadoutType]));
					uint16_t yPos =
						(state->apsFlipY) ?
							(U16T(
								caerFrameEventGetLengthY(currentFrameEvent) - 1
									- state->apsCountY[state->apsCurrentReadoutType])) :
							(U16T(state->apsCountY[state->apsCurrentReadoutType]));

					if (state->chipID == CHIP_DAVISRGB) {
						yPos = U16T(yPos + state->apsRGBPixelOffset);
					}

					if (state->apsInvertXY) {
						SWAP_VAR(uint16_t, xPos, yPos);
					}

					size_t pixelPosition = (size_t) (yPos * caerFrameEventGetLengthX(currentFrameEvent)) + xPos;

					uint16_t xPosAbs = U16T(xPos + state->apsWindow0StartX);
					uint16_t yPosAbs = U16T(yPos + state->apsWindow0StartY);
					size_t pixelPositionAbs = (size_t) (yPosAbs * state->apsSizeX) + xPosAbs;

					if (state->apsCurrentReadoutType == APS_READOUT_RESET) {
						state->apsCurrentResetFrame[pixelPositionAbs] = data;
					}
					else if (state->chipID == CHIP_DAVISRGB && state->apsCurrentReadoutType == APS_READOUT_SIGNAL) {
						// Only for DAVIS RGB.
						state->apsCurrentSignalFrame[pixelPositionAbs] = data;
					}
					else {
						int32_t pixelValue = 0;

						if (state->chipID == CHIP_DAVISRGB) {
							// For DAVIS RGB, this is CP Reset, the last read for both GS and RS modes.
							float C = 7.35f / 2.13f;

							if (isDavisPixel(xPos, yPos)) {
								// DAVIS Pixel
								pixelValue = (int32_t) ((float) (state->apsCurrentResetFrame[pixelPositionAbs]
									- state->apsCurrentSignalFrame[pixelPositionAbs])
									+ (C * (float) (data - state->apsCurrentSignalFrame[pixelPositionAbs])));

								// Protect against overflow from addition.
								pixelValue = (pixelValue > 1023) ? (1023) : (pixelValue);
							}
							else {
								// APS Pixel
								pixelValue = (state->apsCurrentResetFrame[pixelPositionAbs]
									- state->apsCurrentSignalFrame[pixelPositionAbs]);
							}
						}
						else {
							pixelValue = (state->apsCurrentResetFrame[pixelPositionAbs] - data);
						}

						// Normalize the ADC value to 16bit generic depth and check for underflow.
						pixelValue = pixelValue << (16 - DAVIS_ADC_DEPTH);
						caerFrameEventGetPixelArrayUnsafe(currentFrameEvent)[pixelPosition] = htole16(
							U16T((pixelValue < 0) ? (0) : (pixelValue)));
					}

					caerLog(LOG_DEBUG, state->sourceSubSystemString,
						"APS ADC Sample: column=%" PRIu16 ", row=%" PRIu16 ", xPos=%" PRIu16 ", yPos=%" PRIu16 ", data=%" PRIu16 ".",
						state->apsCountX[state->apsCurrentReadoutType], state->apsCountY[state->apsCurrentReadoutType],
						xPos, yPos, data);

					state->apsCountY[state->apsCurrentReadoutType]++;

					// RGB support: first 320 pixels are even, then odd.
					if (state->chipID == CHIP_DAVISRGB) {
						if (state->apsRGBPixelOffsetDirection == 0) { // Increasing
							state->apsRGBPixelOffset++;

							if (state->apsRGBPixelOffset == 321) {
								// Switch to decreasing after last even pixel.
								state->apsRGBPixelOffsetDirection = 1;
								state->apsRGBPixelOffset = 318;
							}
						}
						else { // Decreasing
							state->apsRGBPixelOffset = (int16_t) (state->apsRGBPixelOffset - 3);
						}
					}

					break;
				}

				case 5: {
					// Misc 8bit data, used currently only
					// for IMU events in DAVIS FX3 boards.
					uint8_t misc8Code = U8T((data & 0x0F00) >> 8);
					uint8_t misc8Data = U8T(data & 0x00FF);

					switch (misc8Code) {
						case 0:
							if (state->imuIgnoreEvents) {
								break;
							}

							// Detect missing IMU end events.
							if (state->imuCount >= IMU6_COUNT) {
								caerLog(LOG_INFO, state->sourceSubSystemString,
									"IMU data: IMU samples count is at maximum, discarding further samples.");
								break;
							}

							// IMU data event.
							switch (state->imuCount) {
								case 0:
									caerLog(LOG_ERROR, state->sourceSubSystemString,
										"IMU data: missing IMU Scale Config event. Parsing of IMU events will still be attempted, but be aware that Accel/Gyro scale conversions may be inaccurate.");
									state->imuCount = 1;
									// Fall through to next case, as if imuCount was equal to 1.

								case 1:
								case 3:
								case 5:
								case 7:
								case 9:
								case 11:
								case 13:
									state->imuTmpData = misc8Data;
									break;

								case 2: {
									uint16_t accelX = U16T((state->imuTmpData << 8) | misc8Data);
									caerIMU6EventSetAccelX(currentIMU6Event, accelX / state->imuAccelScale);
									break;
								}

								case 4: {
									uint16_t accelY = U16T((state->imuTmpData << 8) | misc8Data);
									caerIMU6EventSetAccelY(currentIMU6Event, accelY / state->imuAccelScale);
									break;
								}

								case 6: {
									uint16_t accelZ = U16T((state->imuTmpData << 8) | misc8Data);
									caerIMU6EventSetAccelZ(currentIMU6Event, accelZ / state->imuAccelScale);
									break;
								}

									// Temperature is signed. Formula for converting to °C:
									// (SIGNED_VAL / 340) + 36.53
								case 8: {
									int16_t temp = (int16_t) U16T((state->imuTmpData << 8) | misc8Data);
									caerIMU6EventSetTemp(currentIMU6Event, (temp / 340.0f) + 36.53f);
									break;
								}

								case 10: {
									uint16_t gyroX = U16T((state->imuTmpData << 8) | misc8Data);
									caerIMU6EventSetGyroX(currentIMU6Event, gyroX / state->imuGyroScale);
									break;
								}

								case 12: {
									uint16_t gyroY = U16T((state->imuTmpData << 8) | misc8Data);
									caerIMU6EventSetGyroY(currentIMU6Event, gyroY / state->imuGyroScale);
									break;
								}

								case 14: {
									uint16_t gyroZ = U16T((state->imuTmpData << 8) | misc8Data);
									caerIMU6EventSetGyroZ(currentIMU6Event, gyroZ / state->imuGyroScale);
									break;
								}
							}

							state->imuCount++;

							break;

						default:
							caerLog(LOG_ERROR, state->sourceSubSystemString,
								"Caught Misc8 event that can't be handled.");
							break;
					}

					break;
				}

				case 7: // Timestamp wrap
					// Each wrap is 2^15 µs (~32ms), and we have
					// to multiply it with the wrap counter,
					// which is located in the data part of this
					// event.
					state->wrapAdd += (uint32_t) (0x8000 * data);

					state->lastTimestamp = state->currentTimestamp;
					state->currentTimestamp = state->wrapAdd;

					// Check monotonicity of timestamps.
					checkMonotonicTimestamp(state);

					caerLog(LOG_DEBUG, state->sourceSubSystemString,
						"Timestamp wrap event received with multiplier of %" PRIu16 ".", data);
					break;

				default:
					caerLog(LOG_ERROR, state->sourceSubSystemString, "Caught event that can't be handled.");
					break;
			}
		}

		// Commit packet to the ring-buffer, so they can be processed by the
		// main-loop, when their stated conditions are met.
		if (forcePacketCommit
			|| (state->currentPolarityPacketPosition
				>= caerEventPacketHeaderGetEventCapacity(&state->currentPolarityPacket->packetHeader))
			|| ((state->currentPolarityPacketPosition > 1)
				&& (caerPolarityEventGetTimestamp(
					caerPolarityEventPacketGetEvent(state->currentPolarityPacket,
						state->currentPolarityPacketPosition - 1))
					- caerPolarityEventGetTimestamp(caerPolarityEventPacketGetEvent(state->currentPolarityPacket, 0))
					>= state->maxPolarityPacketInterval))) {
			if (!ringBufferPut(state->dataExchangeBuffer, state->currentPolarityPacket)) {
				// Failed to forward packet, drop it.
				free(state->currentPolarityPacket);
				caerLog(LOG_INFO, state->sourceSubSystemString,
					"Dropped Polarity Event Packet because ring-buffer full!");
			}
			else {
				caerMainloopDataAvailableIncrease(state->mainloopNotify);
			}

			// Allocate new packet for next iteration.
			state->currentPolarityPacket = caerPolarityEventPacketAllocate(state->maxPolarityPacketSize,
				state->sourceID);
			state->currentPolarityPacketPosition = 0;
		}

		if (forcePacketCommit
			|| (state->currentFramePacketPosition
				>= caerEventPacketHeaderGetEventCapacity(&state->currentFramePacket->packetHeader))
			|| ((state->currentFramePacketPosition > 1)
				&& (caerFrameEventGetTSStartOfExposure(
					caerFrameEventPacketGetEvent(state->currentFramePacket, state->currentFramePacketPosition - 1))
					- caerFrameEventGetTSStartOfExposure(caerFrameEventPacketGetEvent(state->currentFramePacket, 0))
					>= state->maxFramePacketInterval))) {
			if (!ringBufferPut(state->dataExchangeBuffer, state->currentFramePacket)) {
				// Failed to forward packet, drop it.
				free(state->currentFramePacket);
				caerLog(LOG_INFO, state->sourceSubSystemString, "Dropped Frame Event Packet because ring-buffer full!");
			}
			else {
				caerMainloopDataAvailableIncrease(state->mainloopNotify);
			}

			// Allocate new packet for next iteration.
			state->currentFramePacket = caerFrameEventPacketAllocate(state->maxFramePacketSize, state->sourceID,
				state->apsSizeX, state->apsSizeY, DAVIS_COLOR_CHANNELS);
			state->currentFramePacketPosition = 0;

			// Ignore all APS events, until a new APS Start event comes in.
			// This is to correctly support the forced packet commits that a TS reset,
			// or a timeout condition, impose. Continuing to parse events would result
			// in a corrupted state of the first event in the new packet, as it would
			// be incomplete and miss vital initialization data.
			state->apsIgnoreEvents = true;
		}

		if (forcePacketCommit
			|| (state->currentIMU6PacketPosition
				>= caerEventPacketHeaderGetEventCapacity(&state->currentIMU6Packet->packetHeader))
			|| ((state->currentIMU6PacketPosition > 1)
				&& (caerIMU6EventGetTimestamp(
					caerIMU6EventPacketGetEvent(state->currentIMU6Packet, state->currentIMU6PacketPosition - 1))
					- caerIMU6EventGetTimestamp(caerIMU6EventPacketGetEvent(state->currentIMU6Packet, 0))
					>= state->maxIMU6PacketInterval))) {
			if (!ringBufferPut(state->dataExchangeBuffer, state->currentIMU6Packet)) {
				// Failed to forward packet, drop it.
				free(state->currentIMU6Packet);
				caerLog(LOG_INFO, state->sourceSubSystemString, "Dropped IMU6 Event Packet because ring-buffer full!");
			}
			else {
				caerMainloopDataAvailableIncrease(state->mainloopNotify);
			}

			// Allocate new packet for next iteration.
			state->currentIMU6Packet = caerIMU6EventPacketAllocate(state->maxIMU6PacketSize, state->sourceID);
			state->currentIMU6PacketPosition = 0;

			// Ignore all IMU events, until a new IMU Start event comes in.
			// This is to correctly support the forced packet commits that a TS reset,
			// or a timeout condition, impose. Continuing to parse events would result
			// in a corrupted state of the first event in the new packet, as it would
			// be incomplete and miss vital initialization data.
			state->imuIgnoreEvents = true;
		}

		if (forcePacketCommit
			|| (state->currentSpecialPacketPosition
				>= caerEventPacketHeaderGetEventCapacity(&state->currentSpecialPacket->packetHeader))
			|| ((state->currentSpecialPacketPosition > 1)
				&& (caerSpecialEventGetTimestamp(
					caerSpecialEventPacketGetEvent(state->currentSpecialPacket,
						state->currentSpecialPacketPosition - 1))
					- caerSpecialEventGetTimestamp(caerSpecialEventPacketGetEvent(state->currentSpecialPacket, 0))
					>= state->maxSpecialPacketInterval))) {
			retry_special: if (!ringBufferPut(state->dataExchangeBuffer, state->currentSpecialPacket)) {
				// Failed to forward packet, drop it, unless it contains a timestamp
				// related change, those are critical, so we just spin until we can
				// deliver that one. (Easily detected by forcePacketCommit!)
				if (forcePacketCommit) {
					goto retry_special;
				}
				else {
					// Failed to forward packet, drop it.
					free(state->currentSpecialPacket);
					caerLog(LOG_INFO, state->sourceSubSystemString,
						"Dropped Special Event Packet because ring-buffer full!");
				}
			}
			else {
				caerMainloopDataAvailableIncrease(state->mainloopNotify);
			}

			// Allocate new packet for next iteration.
			state->currentSpecialPacket = caerSpecialEventPacketAllocate(state->maxSpecialPacketSize, state->sourceID);
			state->currentSpecialPacketPosition = 0;
		}
	}
}

static libusb_device_handle *deviceOpen(libusb_context *devContext, uint16_t devVID, uint16_t devPID, uint8_t devType,
	uint8_t busNumber, uint8_t devAddress) {
	libusb_device_handle *devHandle = NULL;
	libusb_device **devicesList;

	ssize_t result = libusb_get_device_list(devContext, &devicesList);

	if (result >= 0) {
		// Cycle thorough all discovered devices and find a match.
		for (size_t i = 0; i < (size_t) result; i++) {
			struct libusb_device_descriptor devDesc;

			if (libusb_get_device_descriptor(devicesList[i], &devDesc) != LIBUSB_SUCCESS) {
				continue;
			}

			// Check if this is the device we want (VID/PID).
			if (devDesc.idVendor == devVID && devDesc.idProduct == devPID
				&& (uint8_t) ((devDesc.bcdDevice & 0xFF00) >> 8) == devType) {
				// If a USB port restriction is given, honor it.
				if (busNumber > 0 && libusb_get_bus_number(devicesList[i]) != busNumber) {
					continue;
				}

				if (devAddress > 0 && libusb_get_device_address(devicesList[i]) != devAddress) {
					continue;
				}

				if (libusb_open(devicesList[i], &devHandle) != LIBUSB_SUCCESS) {
					devHandle = NULL;

					continue;
				}

				// Check that the active configuration is set to number 1. If not, do so.
				int activeConfiguration;
				if (libusb_get_configuration(devHandle, &activeConfiguration) != LIBUSB_SUCCESS) {
					libusb_close(devHandle);
					devHandle = NULL;

					continue;
				}

				if (activeConfiguration != 1) {
					if (libusb_set_configuration(devHandle, 1) != LIBUSB_SUCCESS) {
						libusb_close(devHandle);
						devHandle = NULL;

						continue;
					}
				}

				// Claim interface 0 (default).
				if (libusb_claim_interface(devHandle, 0) != LIBUSB_SUCCESS) {
					libusb_close(devHandle);
					devHandle = NULL;

					continue;
				}

				// Found and configured it!
				break;
			}
		}

		libusb_free_device_list(devicesList, true);
	}

	return (devHandle);
}

static void deviceClose(libusb_device_handle *devHandle) {
	// Release interface 0 (default).
	libusb_release_interface(devHandle, 0);

	libusb_close(devHandle);
}

void sendEnableDataConfig(sshsNode moduleNode, libusb_device_handle *devHandle) {
	sendUSBConfig(moduleNode, devHandle);
	sendMultiplexerConfig(moduleNode, devHandle);
	sendDVSConfig(moduleNode, devHandle);
	sendAPSConfig(moduleNode, devHandle);
	sendIMUConfig(moduleNode, devHandle);
	sendExternalInputDetectorConfig(moduleNode, devHandle);
}

void sendDisableDataConfig(libusb_device_handle *devHandle) {
	spiConfigSend(devHandle, FPGA_EXTINPUT, 0, 0);
	spiConfigSend(devHandle, FPGA_IMU, 0, 0);
	spiConfigSend(devHandle, FPGA_APS, 4, 0);
	spiConfigSend(devHandle, FPGA_DVS, 3, 0);
	spiConfigSend(devHandle, FPGA_MUX, 3, 0); // Ensure chip turns off.
	spiConfigSend(devHandle, FPGA_MUX, 1, 0); // Turn off timestamp too.
	spiConfigSend(devHandle, FPGA_MUX, 0, 0);
	spiConfigSend(devHandle, FPGA_USB, 0, 0);
}

void dataAcquisitionThreadConfig(caerModuleData moduleData) {
	// The common state is always the first member of the moduleState structure
	// for the DAVIS modules, so we can trust it being at address offset 0.
	davisCommonState cstate = moduleData->moduleState;

	// Get the current value to examine by atomic exchange, since we don't
	// want there to be any possible store between a load/store pair.
	uintptr_t configUpdate = atomic_ops_uint_swap(&moduleData->configUpdate, 0, ATOMIC_OPS_FENCE_NONE);

	if (configUpdate & (0x01 << 0)) {
		reallocateUSBBuffers(moduleData->moduleNode, cstate);
	}

	if (configUpdate & (0x01 << 1)) {
		updatePacketSizesIntervals(moduleData->moduleNode, cstate);
	}
}

static void reallocateUSBBuffers(sshsNode moduleNode, davisCommonState state) {
	sshsNode usbNode = sshsGetRelativeNode(moduleNode, "usb/");

	deallocateDataTransfers(state);
	allocateDataTransfers(state, sshsNodeGetInt(usbNode, "BufferNumber"), sshsNodeGetInt(usbNode, "BufferSize"));
}

static void updatePacketSizesIntervals(sshsNode moduleNode, davisCommonState state) {
	sshsNode sysNode = sshsGetRelativeNode(moduleNode, "system/");

	// Packet settings (size (in events) and time interval (in µs)).
	state->maxPolarityPacketSize = sshsNodeGetInt(sysNode, "PolarityPacketMaxSize");
	state->maxPolarityPacketInterval = sshsNodeGetInt(sysNode, "PolarityPacketMaxInterval");

	state->maxFramePacketSize = sshsNodeGetInt(sysNode, "FramePacketMaxSize");
	state->maxFramePacketInterval = sshsNodeGetInt(sysNode, "FramePacketMaxInterval");

	state->maxIMU6PacketSize = sshsNodeGetInt(sysNode, "IMU6PacketMaxSize");
	state->maxIMU6PacketInterval = sshsNodeGetInt(sysNode, "IMU6PacketMaxInterval");

	state->maxSpecialPacketSize = sshsNodeGetInt(sysNode, "SpecialPacketMaxSize");
	state->maxSpecialPacketInterval = sshsNodeGetInt(sysNode, "SpecialPacketMaxInterval");
}
