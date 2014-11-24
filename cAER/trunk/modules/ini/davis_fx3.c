#include "davis_common.h"
#include "davis_fx3.h"
#include "base/module.h"
#include <pthread.h>
#include <unistd.h>

struct davisFX3_state {
	// State for data management, common to all DAVISes.
	struct davisCommon_state cstate;
	// Debug transfer support (FX3 only).
	struct libusb_transfer **debugTransfers;
	atomic_ops_uint debugTransfersLength;
};

typedef struct davisFX3_state *davisFX3State;

static bool caerInputDAVISFX3Init(caerModuleData moduleData);
// RUN: common to all DAVIS systems.
// CONFIG: Nothing to do here in the main thread!
// Biases are configured asynchronously, and buffer sizes in the data
// acquisition thread itself. Resetting the main config_refresh flag
// will also happen there.
static void caerInputDAVISFX3Exit(caerModuleData moduleData);

static struct caer_module_functions caerInputDAVISFX3Functions = { .moduleInit = &caerInputDAVISFX3Init, .moduleRun =
	&caerInputDAVISCommonRun, .moduleConfig = NULL, .moduleExit = &caerInputDAVISFX3Exit };

void caerInputDAVISFX3(uint16_t moduleID, caerPolarityEventPacket *polarity, caerFrameEventPacket *frame,
	caerIMU6EventPacket *imu6, caerSpecialEventPacket *special) {
	caerModuleData moduleData = caerMainloopFindModule(moduleID, "DAVISFX3");

	// IMPORTANT: THE CONTENT OF OUTPUT ARGUMENTS MUST BE SET TO NULL!
	if (polarity != NULL) {
		*polarity = NULL;
	}
	if (frame != NULL) {
		*frame = NULL;
	}
	if (imu6 != NULL) {
		*imu6 = NULL;
	}
	if (special != NULL) {
		*special = NULL;
	}

	caerModuleSM(&caerInputDAVISFX3Functions, moduleData, sizeof(struct davisFX3_state), 4, polarity, frame, imu6,
		special);
}

static void *dataAcquisitionThread(void *inPtr);
static void dataAcquisitionThreadConfig(caerModuleData data);
static void allocateDebugTransfers(davisFX3State state);
static void deallocateDebugTransfers(davisFX3State state);
static void LIBUSB_CALL libUsbDebugCallback(struct libusb_transfer *transfer);
static void debugTranslator(davisFX3State state, uint8_t *buffer, size_t bytesSent);

static bool caerInputDAVISFX3Init(caerModuleData moduleData) {
	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString, "Initializing module ...");

	// First, always create all needed setting nodes, set their default values
	// and add their listeners.
	// Set default biases, from SBRet20s_gs.xml settings.
	createCommonConfiguration(moduleData);

	// Subsystem 4: External Input
	sshsNode extNode = sshsGetRelativeNode(moduleData->moduleNode, "logic/ExternalInput/");

	sshsNodePutBoolIfAbsent(extNode, "RunGenerator", 0);
	sshsNodePutBoolIfAbsent(extNode, "GenerateUseCustomSignal", 0);
	sshsNodePutBoolIfAbsent(extNode, "GeneratePulsePolarity", 1);
	sshsNodePutIntIfAbsent(extNode, "GeneratePulseInterval", 10);
	sshsNodePutIntIfAbsent(extNode, "GeneratePulseLength", 5);

	davisFX3State state = moduleData->moduleState;
	davisCommonState cstate = &state->cstate;

	// Data source is the same as the module ID (but accessible in state-space).
	cstate->sourceID = moduleData->moduleID;

	// Put global source information into SSHS.
	sshsNode sourceInfoNode = sshsGetRelativeNode(moduleData->moduleNode, "sourceInfo/");
	sshsNodePutShort(sourceInfoNode, "dvsSizeX", DAVIS_ARRAY_SIZE_X);
	sshsNodePutShort(sourceInfoNode, "dvsSizeY", DAVIS_ARRAY_SIZE_Y);
	sshsNodePutShort(sourceInfoNode, "frameSizeX", DAVIS_ARRAY_SIZE_X);
	sshsNodePutShort(sourceInfoNode, "frameSizeY", DAVIS_ARRAY_SIZE_Y);
	sshsNodePutShort(sourceInfoNode, "frameOriginalDepth", DAVIS_ADC_DEPTH);
	sshsNodePutShort(sourceInfoNode, "frameOriginalChannels", DAVIS_COLOR_CHANNELS);

	// Initialize state fields.
	cstate->maxPolarityPacketSize = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxSize");
	cstate->maxPolarityPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxInterval");

	cstate->maxFramePacketSize = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxSize");
	cstate->maxFramePacketInterval = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxInterval");

	cstate->maxIMU6PacketSize = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxSize");
	cstate->maxIMU6PacketInterval = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxInterval");

	cstate->maxSpecialPacketSize = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxSize");
	cstate->maxSpecialPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxInterval");

	cstate->currentPolarityPacket = caerPolarityEventPacketAllocate(cstate->maxPolarityPacketSize, cstate->sourceID);
	cstate->currentPolarityPacketPosition = 0;

	cstate->currentFramePacket = caerFrameEventPacketAllocate(cstate->maxFramePacketSize, cstate->sourceID,
	DAVIS_ARRAY_SIZE_X, DAVIS_ARRAY_SIZE_Y, DAVIS_COLOR_CHANNELS);
	cstate->currentFramePacketPosition = 0;

	cstate->currentIMU6Packet = caerIMU6EventPacketAllocate(cstate->maxIMU6PacketSize, cstate->sourceID);
	cstate->currentIMU6PacketPosition = 0;

	cstate->currentSpecialPacket = caerSpecialEventPacketAllocate(cstate->maxSpecialPacketSize, cstate->sourceID);
	cstate->currentSpecialPacketPosition = 0;

	cstate->wrapAdd = 0;
	cstate->lastTimestamp = 0;
	cstate->currentTimestamp = 0;
	cstate->dvsTimestamp = 0;
	cstate->dvsLastY = 0;
	cstate->dvsGotY = false;
	cstate->dvsTranslateRowOnlyEvents = false;
	cstate->apsGlobalShutter = sshsNodeGetBool(sshsGetRelativeNode(moduleData->moduleNode, "logic/APS/"),
		"GlobalShutter");
	cstate->apsCurrentReadoutType = APS_READOUT_RESET;
	for (size_t i = 0; i < APS_READOUT_TYPES_NUM; i++) {
		cstate->apsCountX[i] = 0;
		cstate->apsCountY[i] = 0;
	}
	memset(cstate->apsCurrentResetFrame, 0, DAVIS_ARRAY_SIZE_X * DAVIS_ARRAY_SIZE_Y * DAVIS_COLOR_CHANNELS);

	// Store reference to parent mainloop, so that we can correctly notify
	// the availability or not of data to consume.
	cstate->mainloopNotify = caerMainloopGetReference();

	// Create data exchange buffers.
	cstate->dataExchangeBuffer = ringBufferInit(sshsNodeGetInt(moduleData->moduleNode, "dataExchangeBufferSize"));
	if (cstate->dataExchangeBuffer == NULL) {
		freeAllPackets(cstate);

		caerLog(LOG_CRITICAL, moduleData->moduleSubSystemString, "Failed to initialize data exchange buffer.");
		return (false);
	}

	// Initialize libusb using a separate context for each device.
	// This is to correctly support one thread per device.
	if ((errno = libusb_init(&cstate->deviceContext)) != LIBUSB_SUCCESS) {
		freeAllPackets(cstate);
		ringBufferFree(cstate->dataExchangeBuffer);

		caerLog(LOG_CRITICAL, moduleData->moduleSubSystemString, "Failed to initialize libusb context. Error: %s (%d).",
			libusb_strerror(errno), errno);
		return (false);
	}

	// Try to open a DAVISFX3 device on a specific USB port.
	cstate->deviceHandle = deviceOpen(cstate->deviceContext, DAVIS_FX3_VID, DAVIS_FX3_PID, DAVIS_FX3_DID_TYPE,
		sshsNodeGetByte(moduleData->moduleNode, "usbBusNumber"),
		sshsNodeGetByte(moduleData->moduleNode, "usbDevAddress"));
	if (cstate->deviceHandle == NULL) {
		freeAllPackets(cstate);
		ringBufferFree(cstate->dataExchangeBuffer);
		libusb_exit(cstate->deviceContext);

		caerLog(LOG_CRITICAL, moduleData->moduleSubSystemString, "Failed to open DAVISFX3 device.");
		return (false);
	}

	// At this point we can get some more precise data on the device and update
	// the logging string to reflect that and be more informative.
	unsigned char serialNumber[8 + 1];
	libusb_get_string_descriptor_ascii(cstate->deviceHandle, 3, serialNumber, 8 + 1);
	serialNumber[8] = '\0'; // Ensure NUL termination.

	uint8_t busNumber = libusb_get_bus_number(libusb_get_device(cstate->deviceHandle));
	uint8_t devAddress = libusb_get_device_address(libusb_get_device(cstate->deviceHandle));

	size_t fullLogStringLength = (size_t) snprintf(NULL, 0, "%s SN-%s [%" PRIu8 ":%" PRIu8 "]",
		moduleData->moduleSubSystemString, serialNumber, busNumber, devAddress);
	char fullLogString[fullLogStringLength + 1];
	snprintf(fullLogString, fullLogStringLength + 1, "%s SN-%s [%" PRIu8 ":%" PRIu8 "]",
		moduleData->moduleSubSystemString, serialNumber, busNumber, devAddress);

	caerModuleSetSubSystemString(moduleData, fullLogString);
	cstate->sourceSubSystemString = moduleData->moduleSubSystemString;

	// Start data acquisition thread.
	if ((errno = pthread_create(&state->cstate.dataAcquisitionThread, NULL, &dataAcquisitionThread, moduleData)) != 0) {
		freeAllPackets(cstate);
		ringBufferFree(cstate->dataExchangeBuffer);
		deviceClose(cstate->deviceHandle);
		libusb_exit(cstate->deviceContext);

		caerLog(LOG_CRITICAL, moduleData->moduleSubSystemString,
			"Failed to start data acquisition thread. Error: %s (%d).", caerLogStrerror(errno),
			errno);
		return (false);
	}

	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString,
		"Initialized DAVISFX3 module successfully with device Bus=%" PRIu8 ":Addr=%" PRIu8 ".", busNumber, devAddress);
	return (true);
}

static void caerInputDAVISFX3Exit(caerModuleData moduleData) {
	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString, "Shutting down ...");

	davisFX3State state = moduleData->moduleState;
	davisCommonState cstate = &state->cstate;

	// Wait for data acquisition thread to terminate...
	if ((errno = pthread_join(state->cstate.dataAcquisitionThread, NULL)) != 0) {
		// This should never happen!
		caerLog(LOG_CRITICAL, moduleData->moduleSubSystemString,
			"Failed to join data acquisition thread. Error: %s (%d).", caerLogStrerror(errno), errno);
	}

	// Finally, close the device fully.
	deviceClose(cstate->deviceHandle);

	// Destroy libusb context.
	libusb_exit(cstate->deviceContext);

	// Empty ringbuffer.
	void *packet;
	while ((packet = ringBufferGet(cstate->dataExchangeBuffer)) != NULL) {
		caerMainloopDataAvailableDecrease(cstate->mainloopNotify);
		free(packet);
	}

	// And destroy it.
	ringBufferFree(cstate->dataExchangeBuffer);

	// Free remaining incomplete packets.
	freeAllPackets(cstate);

	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString, "Shutdown successful.");
}

static void *dataAcquisitionThread(void *inPtr) {
	// inPtr is a pointer to module data.
	caerModuleData data = inPtr;
	davisFX3State state = data->moduleState;
	davisCommonState cstate = &state->cstate;

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "Initializing data acquisition thread ...");

	// Send default start-up biases and config values to device before enabling it.

	// Create buffers as specified in config file.
	allocateDebugTransfers(state);
	allocateDataTransfers(cstate, sshsNodeGetInt(data->moduleNode, "bufferNumber"),
		sshsNodeGetInt(data->moduleNode, "bufferSize"));

	// Enable AER data transfer on USB end-point.
	sendSpiConfigCommand(cstate->deviceHandle, 0x00, 0x00, 0x01);
	sendSpiConfigCommand(cstate->deviceHandle, 0x00, 0x01, 0x01);
	sendSpiConfigCommand(cstate->deviceHandle, 0x01, 0x00, 0x01);
	sendSpiConfigCommand(cstate->deviceHandle, 0x03, 0x00, 0x01);

	// APS tests.
	sendSpiConfigCommand(cstate->deviceHandle, 0x02, 14, 1); // Wait on transfer stall.
	sendSpiConfigCommand(cstate->deviceHandle, 0x02, 2,
		sshsNodeGetBool(sshsGetRelativeNode(data->moduleNode, "logic/APS/"), "GlobalShutter")); // GS/RS support.
	sendSpiConfigCommand(cstate->deviceHandle, 0x02, 0, 1); // Run APS.

	// Handle USB events (1 second timeout).
	struct timeval te = { .tv_sec = 0, .tv_usec = 1000000 };

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "data acquisition thread ready to process events.");

	while (atomic_ops_uint_load(&data->running, ATOMIC_OPS_FENCE_NONE) != 0
		&& atomic_ops_uint_load(&cstate->dataTransfersLength, ATOMIC_OPS_FENCE_NONE) > 0) {
		// Check config refresh, in this case to adjust buffer sizes.
		if (atomic_ops_uint_load(&data->configUpdate, ATOMIC_OPS_FENCE_NONE) != 0) {
			dataAcquisitionThreadConfig(data);
		}

		libusb_handle_events_timeout(cstate->deviceContext, &te);
	}

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "shutting down data acquisition thread ...");

	// Disable AER data transfer on USB end-point (reverse order than enabling).
	sendSpiConfigCommand(cstate->deviceHandle, 0x03, 0x00, 0x00);
	sendSpiConfigCommand(cstate->deviceHandle, 0x02, 0x00, 0x00);
	sendSpiConfigCommand(cstate->deviceHandle, 0x01, 0x00, 0x00);
	sendSpiConfigCommand(cstate->deviceHandle, 0x00, 0x01, 0x00);
	sendSpiConfigCommand(cstate->deviceHandle, 0x00, 0x00, 0x00);

	// Cancel all transfers and handle them.
	deallocateDataTransfers(cstate);
	deallocateDebugTransfers(state);

	// Ensure parent also shuts down (on disconnected device for example).
	sshsNodePutBool(data->moduleNode, "shutdown", true);

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "data acquisition thread shut down.");

	return (NULL);
}

static void dataAcquisitionThreadConfig(caerModuleData moduleData) {
	davisFX3State state = moduleData->moduleState;
	davisCommonState cstate = &state->cstate;

	// Get the current value to examine by atomic exchange, since we don't
	// want there to be any possible store between a load/store pair.
	uintptr_t configUpdate = atomic_ops_uint_swap(&moduleData->configUpdate, 0, ATOMIC_OPS_FENCE_NONE);

	if (configUpdate & (0x01 << 0)) {
		// Bias update required.
	}

	if (configUpdate & (0x01 << 1)) {
		// Chip config update required.
	}

	if (configUpdate & (0x01 << 2)) {
		// FPGA config update required.
		// TODO: figure this out.
	}

	if (configUpdate & (0x01 << 3)) {
		// Do buffer size change: cancel all and recreate them.
		deallocateDataTransfers(cstate);
		allocateDataTransfers(cstate, sshsNodeGetInt(moduleData->moduleNode, "bufferNumber"),
			sshsNodeGetInt(moduleData->moduleNode, "bufferSize"));
	}

	if (configUpdate & (0x01 << 4)) {
		// Update maximum size and interval settings for packets.
		cstate->maxPolarityPacketSize = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxSize");
		cstate->maxPolarityPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxInterval");

		cstate->maxFramePacketSize = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxSize");
		cstate->maxFramePacketInterval = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxInterval");

		cstate->maxIMU6PacketSize = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxSize");
		cstate->maxIMU6PacketInterval = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxInterval");

		cstate->maxSpecialPacketSize = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxSize");
		cstate->maxSpecialPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxInterval");
	}
}

static void allocateDebugTransfers(davisFX3State state) {
	atomic_ops_uint_store(&state->debugTransfersLength, 0, ATOMIC_OPS_FENCE_NONE);

	// Set number of transfers and allocate memory for the main transfer array.
	state->debugTransfers = calloc(DEBUG_TRANSFER_NUM, sizeof(struct libusb_transfer *));
	if (state->debugTransfers == NULL) {
		caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
			"Failed to allocate memory for %" PRIu32 " libusb transfers (debug channel). Error: %s (%d).",
			DEBUG_TRANSFER_NUM, caerLogStrerror(errno), errno);
		return;
	}

	// Allocate transfers and set them up.
	for (size_t i = 0; i < DEBUG_TRANSFER_NUM; i++) {
		state->debugTransfers[i] = libusb_alloc_transfer(0);
		if (state->debugTransfers[i] == NULL) {
			caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
				"Unable to allocate further libusb transfers (debug channel, %zu of %" PRIu32 ").", i,
				DEBUG_TRANSFER_NUM);
			return;
		}

		// Create data buffer.
		state->debugTransfers[i]->length = DEBUG_TRANSFER_SIZE;
		state->debugTransfers[i]->buffer = malloc(DEBUG_TRANSFER_SIZE);
		if (state->debugTransfers[i]->buffer == NULL) {
			caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
				"Unable to allocate buffer for libusb transfer %zu (debug channel). Error: %s (%d).", i,
				caerLogStrerror(errno), errno);

			libusb_free_transfer(state->debugTransfers[i]);
			state->debugTransfers[i] = NULL;

			return;
		}

		// Initialize Transfer.
		state->debugTransfers[i]->dev_handle = state->cstate.deviceHandle;
		state->debugTransfers[i]->endpoint = DEBUG_ENDPOINT;
		state->debugTransfers[i]->type = LIBUSB_TRANSFER_TYPE_INTERRUPT;
		state->debugTransfers[i]->callback = &libUsbDebugCallback;
		state->debugTransfers[i]->user_data = state;
		state->debugTransfers[i]->timeout = 0;
		state->debugTransfers[i]->flags = LIBUSB_TRANSFER_FREE_BUFFER;

		if ((errno = libusb_submit_transfer(state->debugTransfers[i])) == LIBUSB_SUCCESS) {
			atomic_ops_uint_inc(&state->debugTransfersLength, ATOMIC_OPS_FENCE_NONE);
		}
		else {
			caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
				"Unable to submit libusb transfer %zu (debug channel). Error: %s (%d).", i, libusb_strerror(errno),
				errno);

			// The transfer buffer is freed automatically here thanks to
			// the LIBUSB_TRANSFER_FREE_BUFFER flag set above.
			libusb_free_transfer(state->debugTransfers[i]);
			state->debugTransfers[i] = NULL;

			return;
		}
	}
}

static void deallocateDebugTransfers(davisFX3State state) {
	// This will change later on, but we still need it.
	uint32_t transfersNum = (uint32_t) atomic_ops_uint_load(&state->debugTransfersLength, ATOMIC_OPS_FENCE_NONE);

	// Cancel all current transfers first.
	for (size_t i = 0; i < transfersNum; i++) {
		errno = libusb_cancel_transfer(state->debugTransfers[i]);
		if (errno != LIBUSB_SUCCESS && errno != LIBUSB_ERROR_NOT_FOUND) {
			caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
				"Unable to cancel libusb transfer %zu (debug channel). Error: %s (%d).", i, libusb_strerror(errno),
				errno);
			// Proceed with canceling all transfers regardless of errors.
		}
	}

	// Wait for all transfers to go away (0.1 seconds timeout).
	struct timeval te = { .tv_sec = 0, .tv_usec = 100000 };

	while (atomic_ops_uint_load(&state->debugTransfersLength, ATOMIC_OPS_FENCE_NONE) > 0) {
		libusb_handle_events_timeout(state->cstate.deviceContext, &te);
	}

	// The buffers and transfers have been deallocated in the callback.
	// Only the transfers array remains.
	free(state->debugTransfers);
}

static void LIBUSB_CALL libUsbDebugCallback(struct libusb_transfer *transfer) {
	davisFX3State state = transfer->user_data;

	if (transfer->status == LIBUSB_TRANSFER_COMPLETED) {
		// Handle debug data.
		debugTranslator(state, transfer->buffer, (size_t) transfer->actual_length);
	}

	if (transfer->status != LIBUSB_TRANSFER_CANCELLED && transfer->status != LIBUSB_TRANSFER_NO_DEVICE) {
		// Submit transfer again.
		if (libusb_submit_transfer(transfer) == LIBUSB_SUCCESS) {
			return;
		}
	}

	// Cannot recover (cancelled, no device, or other critical error).
	// Signal this by adjusting the counter, free and exit.
	atomic_ops_uint_dec(&state->debugTransfersLength, ATOMIC_OPS_FENCE_NONE);
	libusb_free_transfer(transfer);
}

static void debugTranslator(davisFX3State state, uint8_t *buffer, size_t bytesSent) {
	UNUSED_ARGUMENT(state);

	// Check if this is a debug message (length 7-64 bytes).
	if (bytesSent >= 7 && buffer[0] == 0x00) {
		// Debug message, log this.
		caerLog(LOG_ERROR, state->cstate.sourceSubSystemString, "Error message: '%s' (code %u at time %u).", &buffer[6],
			buffer[1], *((uint32_t *) &buffer[2]));
	}
	else {
		// Unknown/invalid debug message, log this.
		caerLog(LOG_WARNING, state->cstate.sourceSubSystemString, "Unknown/invalid debug message.");
	}
}
