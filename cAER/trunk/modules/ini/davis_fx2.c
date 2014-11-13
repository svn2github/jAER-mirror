#include "davis_common.h"
#include "davis_fx2.h"
#include "base/module.h"
#include <pthread.h>
#include <unistd.h>

struct davisFX2_state {
	// State for data management, common to all DAVISes.
	struct davisCommon_state cstate;
	// Data Acquisition Thread
	pthread_t dataAcquisitionThread;
};

typedef struct davisFX2_state *davisFX2State;

static bool caerInputDAVISFX2Init(caerModuleData moduleData);
// RUN: common to all DAVIS systems.
// CONFIG: Nothing to do here in the main thread!
// Biases are configured asynchronously, and buffer sizes in the data
// acquisition thread itself. Resetting the main config_refresh flag
// will also happen there.
static void caerInputDAVISFX2Exit(caerModuleData moduleData);

static struct caer_module_functions caerInputDAVISFX2Functions = { .moduleInit = &caerInputDAVISFX2Init, .moduleRun =
	&caerInputDAVISCommonRun, .moduleConfig = NULL, .moduleExit = &caerInputDAVISFX2Exit };

void caerInputDAVISFX2(uint16_t moduleID, caerPolarityEventPacket *polarity, caerFrameEventPacket *frame,
	caerIMU6EventPacket *imu6, caerSpecialEventPacket *special) {
	caerModuleData moduleData = caerMainloopFindModule(moduleID, "DAVISFX2");

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

	caerModuleSM(&caerInputDAVISFX2Functions, moduleData, sizeof(struct davisFX2_state), 4, polarity, frame, imu6,
		special);
}

static void *dataAcquisitionThread(void *inPtr);
static void dataAcquisitionThreadConfig(caerModuleData data);
static void sendAddressedCoarseFineBias(sshsNode biasNode, libusb_device_handle *devHandle, uint16_t biasAddress,
	const char *biasName);
static void sendShiftedSourceBias(sshsNode biasNode, libusb_device_handle *devHandle, uint16_t biasAddress,
	const char *biasName);
static void sendBiases(sshsNode biasNode, libusb_device_handle *devHandle);
static void sendChipSR(sshsNode chipNode, libusb_device_handle *devHandle);

static bool caerInputDAVISFX2Init(caerModuleData moduleData) {
	caerLog(LOG_DEBUG, "Initializing DAVISFX2 module ...");

	// First, always create all needed setting nodes, set their default values
	// and add their listeners.
	// Set default biases, from SBRet20s_gs.xml settings.
	sshsNode biasNode = sshsGetRelativeNode(moduleData->moduleNode, "bias/");
	createAddressedCoarseFineBiasSetting(biasNode, "DiffBn", "Normal", "N", 3, 72, true);
	createAddressedCoarseFineBiasSetting(biasNode, "OnBn", "Normal", "N", 2, 112, true);
	createAddressedCoarseFineBiasSetting(biasNode, "OffBn", "Normal", "N", 3, 6, true);
	createAddressedCoarseFineBiasSetting(biasNode, "ApsCasEpc", "Cascode", "N", 2, 144, true);
	createAddressedCoarseFineBiasSetting(biasNode, "DiffCasBnc", "Cascode", "N", 2, 115, true);
	createAddressedCoarseFineBiasSetting(biasNode, "ApsROSFBn", "Normal", "N", 1, 188, true);
	createAddressedCoarseFineBiasSetting(biasNode, "LocalBufBn", "Normal", "N", 2, 164, true);
	createAddressedCoarseFineBiasSetting(biasNode, "PixInvBn", "Normal", "N", 1, 129, true);
	createAddressedCoarseFineBiasSetting(biasNode, "PrBp", "Normal", "P", 6, 255, true);
	createAddressedCoarseFineBiasSetting(biasNode, "PrSFBp", "Normal", "P", 5, 2, true);
	createAddressedCoarseFineBiasSetting(biasNode, "RefrBp", "Normal", "P", 3, 19, true);
	createAddressedCoarseFineBiasSetting(biasNode, "AEPdBn", "Normal", "N", 0, 140, true);
	createAddressedCoarseFineBiasSetting(biasNode, "LcolTimeoutBn", "Normal", "N", 6, 132, true);
	createAddressedCoarseFineBiasSetting(biasNode, "AEPuXBp", "Normal", "P", 1, 80, true);
	createAddressedCoarseFineBiasSetting(biasNode, "AEPuYBp", "Normal", "P", 1, 152, true);
	createAddressedCoarseFineBiasSetting(biasNode, "IFThrBn", "Normal", "N", 2, 255, true);
	createAddressedCoarseFineBiasSetting(biasNode, "IFRefrBn", "Normal", "N", 2, 255, true);
	createAddressedCoarseFineBiasSetting(biasNode, "PadFollBn", "Normal", "N", 0, 211, true);
	createAddressedCoarseFineBiasSetting(biasNode, "apsOverflowLevel", "Normal", "N", 0, 36, true);
	createAddressedCoarseFineBiasSetting(biasNode, "biasBuffer", "Normal", "N", 1, 251, true);

	createShiftedSourceBiasSetting(biasNode, "SSP", 33, 1, "TiedToRail", "SplitGate");
	createShiftedSourceBiasSetting(biasNode, "SSN", 33, 2, "ShiftedSource", "SplitGate");

	sshsNode chipNode = sshsGetRelativeNode(moduleData->moduleNode, "chip/");
	sshsNodePutBoolIfAbsent(chipNode, "globalShutter", true);
	sshsNodePutBoolIfAbsent(chipNode, "useAout", false);
	sshsNodePutBoolIfAbsent(chipNode, "nArow", false);
	sshsNodePutBoolIfAbsent(chipNode, "hotPixelSuppression", false);
	sshsNodePutBoolIfAbsent(chipNode, "resetTestpixel", true);
	sshsNodePutBoolIfAbsent(chipNode, "typeNCalib", false);
	sshsNodePutBoolIfAbsent(chipNode, "resetCalib", true);

	sshsNode fpgaNode = sshsGetRelativeNode(moduleData->moduleNode, "fpga/");
	// TODO: sshsNodePutShortIfAbsent(fpgaNode, "TODO", 0);

	// USB port settings/restrictions.
	sshsNodePutByteIfAbsent(moduleData->moduleNode, "usbBusNumber", 0);
	sshsNodePutByteIfAbsent(moduleData->moduleNode, "usbDevAddress", 0);

	// USB buffer settings.
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "bufferNumber", 8);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "bufferSize", 8192);

	// Packet settings (size (in events) and time interval (in µs)).
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "polarityPacketMaxSize", 4096);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "polarityPacketMaxInterval", 5000);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "framePacketMaxSize", 4);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "framePacketMaxInterval", 20000);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "imu6PacketMaxSize", 32);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "imu6PacketMaxInterval", 4000);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "specialPacketMaxSize", 128);
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "specialPacketMaxInterval", 1000);

	// Ring-buffer setting (only changes value on module init/shutdown cycles).
	sshsNodePutIntIfAbsent(moduleData->moduleNode, "dataExchangeBufferSize", 64);

	// Install default listener to signal configuration updates asynchronously.
	sshsNodeAddAttrListener(biasNode, moduleData, &caerInputDAVISFX2ConfigListener);
	sshsNodeAddAttrListener(chipNode, moduleData, &caerInputDAVISFX2ConfigListener);
	sshsNodeAddAttrListener(fpgaNode, moduleData, &caerInputDAVISFX2ConfigListener);
	sshsNodeAddAttrListener(moduleData->moduleNode, moduleData, &caerInputDAVISFX2ConfigListener);

	davisFX2State state = moduleData->moduleState;

	// Data source is the same as the module ID (but accessible in state-space).
	state->sourceID = moduleData->moduleID;

	// Put global source information into SSHS.
	sshsNode sourceInfoNode = sshsGetRelativeNode(moduleData->moduleNode, "sourceInfo/");
	sshsNodePutShort(sourceInfoNode, "dvsSizeX", DAVIS_ARRAY_SIZE_X);
	sshsNodePutShort(sourceInfoNode, "dvsSizeY", DAVIS_ARRAY_SIZE_Y);
	sshsNodePutShort(sourceInfoNode, "frameSizeX", DAVIS_ARRAY_SIZE_X);
	sshsNodePutShort(sourceInfoNode, "frameSizeY", DAVIS_ARRAY_SIZE_Y);
	sshsNodePutShort(sourceInfoNode, "frameOriginalDepth", DAVIS_ADC_DEPTH);
	sshsNodePutShort(sourceInfoNode, "frameOriginalChannels", DAVIS_COLOR_CHANNELS);

	// Initialize state fields.
	state->maxPolarityPacketSize = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxSize");
	state->maxPolarityPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxInterval");

	state->maxFramePacketSize = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxSize");
	state->maxFramePacketInterval = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxInterval");

	state->maxIMU6PacketSize = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxSize");
	state->maxIMU6PacketInterval = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxInterval");

	state->maxSpecialPacketSize = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxSize");
	state->maxSpecialPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxInterval");

	state->currentPolarityPacket = caerPolarityEventPacketAllocate(state->maxPolarityPacketSize, state->sourceID);
	state->currentPolarityPacketPosition = 0;

	state->currentFramePacket = caerFrameEventPacketAllocate(state->maxFramePacketSize, state->sourceID,
	DAVIS_ARRAY_SIZE_Y, DAVIS_ARRAY_SIZE_X, DAVIS_COLOR_CHANNELS);
	state->currentFramePacketPosition = 0;

	state->currentIMU6Packet = caerIMU6EventPacketAllocate(state->maxIMU6PacketSize, state->sourceID);
	state->currentIMU6PacketPosition = 0;

	state->currentSpecialPacket = caerSpecialEventPacketAllocate(state->maxSpecialPacketSize, state->sourceID);
	state->currentSpecialPacketPosition = 0;

	state->wrapAdd = 0;
	state->lastTimestamp = 0;
	state->currentTimestamp = 0;
	state->dvsTimestamp = 0;
	state->imuTimestamp = 0;
	state->lastY = 0;
	state->gotY = false;
	state->apsGlobalShutter = true; // TODO: external control.
	state->apsCurrentReadoutType = APS_READOUT_RESET;
	for (size_t i = 0; i < APS_READOUT_TYPES_NUM; i++) {
		state->apsCountX[i] = 0;
		state->apsCountY[i] = 0;
	}
	memset(state->apsCurrentResetFrame, 0, DAVIS_ARRAY_SIZE_X * DAVIS_ARRAY_SIZE_Y);

	// Store reference to parent mainloop, so that we can correctly notify
	// the availability or not of data to consume.
	state->mainloopNotify = caerMainloopGetReference();

	// Create data exchange buffers.
	state->dataExchangeBuffer = ringBufferInit(sshsNodeGetInt(moduleData->moduleNode, "dataExchangeBufferSize"));
	if (state->dataExchangeBuffer == NULL) {
		freeAllPackets(state);

		caerLog(LOG_CRITICAL, "Failed to initialize data exchange buffer.");
		return (false);
	}

	// Initialize libusb using a separate context for each device.
	// This is to correctly support one thread per device.
	if ((errno = libusb_init(&state->deviceContext)) != LIBUSB_SUCCESS) {
		freeAllPackets(state);
		ringBufferFree(state->dataExchangeBuffer);

		caerLog(LOG_CRITICAL, "Failed to initialize libusb context. Error: %s (%d).", libusb_strerror(errno), errno);
		return (false);
	}

	// Try to open a DAVISFX2 device on a specific USB port.
	state->deviceHandle = deviceOpen(state->deviceContext, sshsNodeGetByte(moduleData->moduleNode, "usbBusNumber"),
		sshsNodeGetByte(moduleData->moduleNode, "usbDevAddress"));
	if (state->deviceHandle == NULL) {
		freeAllPackets(state);
		ringBufferFree(state->dataExchangeBuffer);
		libusb_exit(state->deviceContext);

		caerLog(LOG_CRITICAL, "Failed to open DAVISFX2 device.");
		return (false);
	}

	// Start data acquisition thread.
	if ((errno = pthread_create(&state->dataAcquisitionThread, NULL, &dataAcquisitionThread, moduleData)) != 0) {
		freeAllPackets(state);
		ringBufferFree(state->dataExchangeBuffer);
		deviceClose(state->deviceHandle);
		libusb_exit(state->deviceContext);

		caerLog(LOG_CRITICAL, "Failed to start data acquisition thread. Error: %s (%d).", caerLogStrerror(errno),
		errno);
		return (false);
	}

	caerLog(LOG_DEBUG, "Initialized DAVISFX2 module successfully with device Bus=%" PRIu8 ":Addr=%" PRIu8 ".",
		libusb_get_bus_number(libusb_get_device(state->deviceHandle)),
		libusb_get_device_address(libusb_get_device(state->deviceHandle)));
	return (true);
}

static void caerInputDAVISFX2Exit(caerModuleData moduleData) {
	caerLog(LOG_DEBUG, "Shutting down DAVISFX2 module ...");

	davisFX2State state = moduleData->moduleState;

	// Wait for data acquisition thread to terminate...
	if ((errno = pthread_join(state->dataAcquisitionThread, NULL)) != 0) {
		// This should never happen!
		caerLog(LOG_CRITICAL, "Failed to join data acquisition thread. Error: %s (%d).", caerLogStrerror(errno),
		errno);
	}

	// Finally, close the device fully.
	deviceClose(state->deviceHandle);

	// Destroy libusb context.
	libusb_exit(state->deviceContext);

	// Empty ringbuffer.
	void *packet;
	while ((packet = ringBufferGet(state->dataExchangeBuffer)) != NULL) {
		caerMainloopDataAvailableDecrease(state->mainloopNotify);
		free(packet);
	}

	// And destroy it.
	ringBufferFree(state->dataExchangeBuffer);

	// Free remaining incomplete packets.
	freeAllPackets(state);

	caerLog(LOG_DEBUG, "Shutdown DAVISFX2 module successfully.");
}

static void *dataAcquisitionThread(void *inPtr) {
	caerLog(LOG_DEBUG, "DAVISFX2: initializing data acquisition thread ...");

	// inPtr is a pointer to module data.
	caerModuleData data = inPtr;
	davisFX2State state = data->moduleState;

	// Send default start-up biases and config values to device before enabling it.
	sendBiases(sshsGetRelativeNode(data->moduleNode, "bias/"), state->deviceHandle);
	sendChipSR(sshsGetRelativeNode(data->moduleNode, "chip/"), state->deviceHandle);
	// TODO: fpga config here.

	// Create buffers as specified in config file.
	//allocateDebugTransfers(state);
	allocateDataTransfers(state, sshsNodeGetInt(data->moduleNode, "bufferNumber"),
		sshsNodeGetInt(data->moduleNode, "bufferSize"));

	// Enable AER data transfer on USB end-point.
	sendSpiConfigCommand(state->deviceHandle, 0x00, 0x00, 0x01);
	sendSpiConfigCommand(state->deviceHandle, 0x00, 0x01, 0x01);
	sendSpiConfigCommand(state->deviceHandle, 0x01, 0x00, 0x00);
	sendSpiConfigCommand(state->deviceHandle, 0x03, 0x00, 0x00);

	// APS tests.
	sendSpiConfigCommand(state->deviceHandle, 0x02, 7, 30000 * 1); // Exposure control.
	sendSpiConfigCommand(state->deviceHandle, 0x02, 8, 30000); // Wait 1ms between frames.
	sendSpiConfigCommand(state->deviceHandle, 0x02, 14, 1); // Wait on transfer stall.
	sendSpiConfigCommand(state->deviceHandle, 0x02, 2, 1); // Global shutter.
	sendSpiConfigCommand(state->deviceHandle, 0x02, 0, 1); // Run APS.

	// Handle USB events (1 second timeout).
	struct timeval te = { .tv_sec = 0, .tv_usec = 1000000 };

	caerLog(LOG_DEBUG, "DAVISFX2: data acquisition thread ready to process events.");

	while (atomic_ops_uint_load(&data->running, ATOMIC_OPS_FENCE_NONE) != 0
		&& atomic_ops_uint_load(&state->dataTransfersLength, ATOMIC_OPS_FENCE_NONE) > 0) {
		// Check config refresh, in this case to adjust buffer sizes.
		if (atomic_ops_uint_load(&data->configUpdate, ATOMIC_OPS_FENCE_NONE) != 0) {
			dataAcquisitionThreadConfig(data);
		}

		libusb_handle_events_timeout(state->deviceContext, &te);
	}

	caerLog(LOG_DEBUG, "DAVISFX2: shutting down data acquisition thread ...");

	// Disable AER data transfer on USB end-point (reverse order than enabling).
	sendSpiConfigCommand(state->deviceHandle, 0x03, 0x00, 0x00);
	sendSpiConfigCommand(state->deviceHandle, 0x01, 0x00, 0x00);
	sendSpiConfigCommand(state->deviceHandle, 0x00, 0x01, 0x00);
	sendSpiConfigCommand(state->deviceHandle, 0x00, 0x00, 0x00);

	// Cancel all transfers and handle them.
	deallocateDataTransfers(state);
	//deallocateDebugTransfers(state);

	// Ensure parent also shuts down (on disconnected device for example).
	sshsNodePutBool(data->moduleNode, "shutdown", true);

	caerLog(LOG_DEBUG, "DAVISFX2: data acquisition thread shut down.");

	return (NULL);
}

static void dataAcquisitionThreadConfig(caerModuleData moduleData) {
	davisFX2State state = moduleData->moduleState;

	// Get the current value to examine by atomic exchange, since we don't
	// want there to be any possible store between a load/store pair.
	uintptr_t configUpdate = atomic_ops_uint_swap(&moduleData->configUpdate, 0, ATOMIC_OPS_FENCE_NONE);

	if (configUpdate & (0x01 << 0)) {
		// Bias update required.
		sendBiases(sshsGetRelativeNode(moduleData->moduleNode, "bias/"), state->deviceHandle);
	}

	if (configUpdate & (0x01 << 1)) {
		// Chip config update required.
		sendChipSR(sshsGetRelativeNode(moduleData->moduleNode, "chip/"), state->deviceHandle);
	}

	if (configUpdate & (0x01 << 2)) {
		// FPGA config update required.
		// TODO: figure this out.
	}

	if (configUpdate & (0x01 << 3)) {
		// Do buffer size change: cancel all and recreate them.
		deallocateDataTransfers(state);
		allocateDataTransfers(state, sshsNodeGetInt(moduleData->moduleNode, "bufferNumber"),
			sshsNodeGetInt(moduleData->moduleNode, "bufferSize"));
	}

	if (configUpdate & (0x01 << 4)) {
		// Update maximum size and interval settings for packets.
		state->maxPolarityPacketSize = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxSize");
		state->maxPolarityPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "polarityPacketMaxInterval");

		state->maxFramePacketSize = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxSize");
		state->maxFramePacketInterval = sshsNodeGetInt(moduleData->moduleNode, "framePacketMaxInterval");

		state->maxIMU6PacketSize = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxSize");
		state->maxIMU6PacketInterval = sshsNodeGetInt(moduleData->moduleNode, "imu6PacketMaxInterval");

		state->maxSpecialPacketSize = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxSize");
		state->maxSpecialPacketInterval = sshsNodeGetInt(moduleData->moduleNode, "specialPacketMaxInterval");
	}
}

static void sendAddressedCoarseFineBias(sshsNode biasNode, libusb_device_handle *devHandle, uint16_t biasAddress,
	const char *biasName) {
	// Get integer bias value.
	uint16_t biasValue = generateAddressedCoarseFineBias(biasNode, biasName);

	// All biases are two byte quantities.
	uint8_t bias[2];

	// Put the value in.
	bias[0] = U8T(biasValue >> 8);
	bias[1] = U8T(biasValue >> 0);

	libusb_control_transfer(devHandle, LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
	VR_CHIP_BIAS, biasAddress, 0, bias, sizeof(bias), 0);
}

static void sendShiftedSourceBias(sshsNode biasNode, libusb_device_handle *devHandle, uint16_t biasAddress,
	const char *biasName) {
	// Get integer bias value.
		uint16_t biasValue = generateShiftedSourceBias(biasNode, biasName);

	// All biases are two byte quantities.
	uint8_t bias[2];

	// Put the value in.
	bias[0] = U8T(biasValue >> 8);
	bias[1] = U8T(biasValue >> 0);

	libusb_control_transfer(devHandle, LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
	VR_CHIP_BIAS, biasAddress, 0, bias, sizeof(bias), 0);
}

static void sendBiases(sshsNode biasNode, libusb_device_handle *devHandle) {
	// Biases are addressable now!
	sendAddressedCoarseFineBias(biasNode, devHandle, 0, "DiffBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 1, "OnBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 2, "OffBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 3, "ApsCasEpc");
	sendAddressedCoarseFineBias(biasNode, devHandle, 4, "DiffCasBnc");
	sendAddressedCoarseFineBias(biasNode, devHandle, 5, "ApsROSFBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 6, "LocalBufBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 7, "PixInvBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 8, "PrBp");
	sendAddressedCoarseFineBias(biasNode, devHandle, 9, "PrSFBp");
	sendAddressedCoarseFineBias(biasNode, devHandle, 10, "RefrBp");
	sendAddressedCoarseFineBias(biasNode, devHandle, 11, "AEPdBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 12, "LcolTimeoutBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 13, "AEPuXBp");
	sendAddressedCoarseFineBias(biasNode, devHandle, 14, "AEPuYBp");
	sendAddressedCoarseFineBias(biasNode, devHandle, 15, "IFThrBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 16, "IFRefrBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 17, "PadFollBn");
	sendAddressedCoarseFineBias(biasNode, devHandle, 18, "apsOverflowLevel");
	sendAddressedCoarseFineBias(biasNode, devHandle, 19, "biasBuffer");
	sendShiftedSourceBias(biasNode, devHandle, 20, "SSP");
	sendShiftedSourceBias(biasNode, devHandle, 21, "SSN");
}

static void sendChipSR(sshsNode chipNode, libusb_device_handle *devHandle) {
	// A total of 56 bits (7 bytes) of configuration
	uint8_t chipSR[7] = { 0 };

	// Muxes are all kept at zero for now (no control). (TODO)

	// Bytes 2-4 contain the actual 24 configuration bits. 17 are unused.
	bool globalShutter = sshsNodeGetBool(chipNode, "globalShutter");
	if (globalShutter) {
		// Flip bit on if enabled.
		chipSR[4] |= (1 << 6);
	}

	bool useAout = sshsNodeGetBool(chipNode, "useAout");
	if (useAout) {
		// Flip bit on if enabled.
		chipSR[4] |= (1 << 5);
	}

	bool nArow = sshsNodeGetBool(chipNode, "nArow");
	if (nArow) {
		// Flip bit on if enabled.
		chipSR[4] |= (1 << 4);
	}

	bool hotPixelSuppression = sshsNodeGetBool(chipNode, "hotPixelSuppression");
	if (hotPixelSuppression) {
		// Flip bit on if enabled.
		chipSR[4] |= (1 << 3);
	}

	bool resetTestpixel = sshsNodeGetBool(chipNode, "resetTestpixel");
	if (resetTestpixel) {
		// Flip bit on if enabled.
		chipSR[4] |= (1 << 2);
	}

	bool typeNCalib = sshsNodeGetBool(chipNode, "typeNCalib");
	if (typeNCalib) {
		// Flip bit on if enabled.
		chipSR[4] |= (1 << 1);
	}

	bool resetCalib = sshsNodeGetBool(chipNode, "resetCalib");
	if (resetCalib) {
		// Flip bit on if enabled.
		chipSR[4] |= (1 << 0);
	}

	libusb_control_transfer(devHandle, LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE,
	VR_CHIP_DIAG, 0, 0, chipSR, sizeof(chipSR), 0);
}
