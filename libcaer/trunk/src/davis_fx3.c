#include "davis_common.h"
#include "davis_fx3.h"
#include <pthread.h>
#include <unistd.h>

#define DAVIS_FX3_VID 0x152A
#define DAVIS_FX3_PID 0x841A
#define DAVIS_FX3_DID_TYPE 0x01

#define DEBUG_ENDPOINT 0x81
#define DEBUG_TRANSFER_NUM 4
#define DEBUG_TRANSFER_SIZE 64

struct caer_davis_fx3_handle {
	// Common info and state structure (handle).
	struct davis_handle h;
	// Debug transfer support (FX3 only).
	struct libusb_transfer *debugTransfers[DEBUG_TRANSFER_NUM];
	size_t activeDebugTransfers;
};

caerDavisFX3Handle caerDavisFX3Open(uint8_t busNumberRestrict, uint8_t devAddressRestrict,
	const char *serialNumberRestrict) {
	// Allocate memory for device structures.
	caerDavisFX3Handle handle = ccalloc(1, sizeof(*handle));
	if (handle == NULL) {
		caerLog(LOG_CRITICAL, "DAVIS FX3", "Failed to allocate memory.");
		return (NULL);
	}

	// Open device.
	davisOpen(&handle->h, DAVIS_FX3_VID, DAVIS_FX3_PID, DAVIS_FX3_DID_TYPE,
		busNumberRestrict, devAddressRestrict, serialNumberRestrict);

	// Fill out info data structure.
	davisInfoInitialize(&handle->h);

	// Initialize state and configuration.
	davisStateInitialize(&handle->h);

	return (handle);
}

bool caerDavisFX3Close(caerDavisFX3Handle handle);
caerDavisInfo caerDavisFX3InfoGet(caerDavisFX3Handle handle);
bool caerDavisFX3ConfigSet(caerDavisFX3Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t param);
bool caerDavisFX3ConfigGet(caerDavisFX3Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t *param);
bool caerDavisFX3DataStart(caerDavisFX3Handle handle);
bool caerDavisFX3DataStop(caerDavisFX3Handle handle);
caerEventPacketContainer caerDavisFX3DataGet(caerDavisFX3Handle handle);

static void *dataAcquisitionThread(void *inPtr);
static void allocateDebugTransfers(davisFX3State state);
static void deallocateDebugTransfers(davisFX3State state);
static void LIBUSB_CALL libUsbDebugCallback(struct libusb_transfer *transfer);
static void debugTranslator(davisFX3State state, uint8_t *buffer, size_t bytesSent);
static void sendBiases(sshsNode moduleNode, davisCommonState cstate);
static void sendChipSR(sshsNode moduleNode, davisCommonState cstate);
static void BiasesListener(sshsNode node, void *userData, enum sshs_node_attribute_events event, const char *changeKey,
	enum sshs_node_attr_value_type changeType, union sshs_node_attr_value changeValue);
static void ChipSRListener(sshsNode node, void *userData, enum sshs_node_attribute_events event, const char *changeKey,
	enum sshs_node_attr_value_type changeType, union sshs_node_attr_value changeValue);
static void sendDVSFilterConfig(sshsNode moduleNode, libusb_device_handle *devHandle);
static void sendAPSQuadROIConfig(sshsNode moduleNode, libusb_device_handle *devHandle);
static void sendExternalInputGeneratorConfig(sshsNode moduleNode, libusb_device_handle *devHandle);
static void DVSFilterConfigListener(sshsNode node, void *userData, enum sshs_node_attribute_events event,
	const char *changeKey, enum sshs_node_attr_value_type changeType, union sshs_node_attr_value changeValue);
static void APSQuadROIConfigListener(sshsNode node, void *userData, enum sshs_node_attribute_events event,
	const char *changeKey, enum sshs_node_attr_value_type changeType, union sshs_node_attr_value changeValue);
static void ExternalInputGeneratorConfigListener(sshsNode node, void *userData, enum sshs_node_attribute_events event,
	const char *changeKey, enum sshs_node_attr_value_type changeType, union sshs_node_attr_value changeValue);

static bool caerInputDAVISFX3Init(caerModuleData moduleData) {
	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString, "Initializing module ...");

	davisFX3State state = moduleData->moduleState;
	davisCommonState cstate = &state->cstate;

	// Data source is the same as the module ID (but accessible in cstate-space).
	// Same thing for subSystemString.
	cstate->sourceID = moduleData->moduleID;
	cstate->sourceSubSystemString = moduleData->moduleSubSystemString;

	// First, we need to connect to the device and ask it what chip it's got,
	// and retain that information for later stages.
	if (!deviceOpenInfo(moduleData, cstate, DAVIS_FX3_VID, DAVIS_FX3_PID, DAVIS_FX3_DID_TYPE)) {
		return (false);
	}

	// Create common default value configuration.
	createCommonConfiguration(moduleData, cstate);

	// Subsystem 1: DVS AER (Pixel and BA filtering support present only in FX3)
	sshsNode dvsNode = sshsGetRelativeNode(moduleData->moduleNode, "dvs/");

	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel0Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel0Column", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel1Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel1Column", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel2Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel2Column", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel3Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel3Column", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel4Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel4Column", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel5Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel5Column", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel6Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel6Column", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel7Row", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(dvsNode, "FilterPixel7Column", cstate->apsSizeX);
	sshsNodePutBoolIfAbsent(dvsNode, "FilterBackgroundActivity", 0);
	sshsNodePutIntIfAbsent(dvsNode, "FilterBackgroundActivityDeltaTime", 20000);

	// Subsystem 2: APS ADC (Quad-ROI support present only in FX3)
	sshsNode apsNode = sshsGetRelativeNode(moduleData->moduleNode, "aps/");

	sshsNodePutShortIfAbsent(apsNode, "StartColumn1", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(apsNode, "StartRow1", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(apsNode, "EndColumn1", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(apsNode, "EndRow1", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(apsNode, "StartColumn2", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(apsNode, "StartRow2", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(apsNode, "EndColumn2", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(apsNode, "EndRow2", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(apsNode, "StartColumn3", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(apsNode, "StartRow3", cstate->apsSizeY);
	sshsNodePutShortIfAbsent(apsNode, "EndColumn3", cstate->apsSizeX);
	sshsNodePutShortIfAbsent(apsNode, "EndRow3", cstate->apsSizeY);

	// Subsystem 4: External Input (Generator module present only in FX3)
	sshsNode extNode = sshsGetRelativeNode(moduleData->moduleNode, "externalInput/");

	sshsNodePutBoolIfAbsent(extNode, "RunGenerator", 0);
	sshsNodePutBoolIfAbsent(extNode, "GenerateUseCustomSignal", 0);
	sshsNodePutBoolIfAbsent(extNode, "GeneratePulsePolarity", 1);
	sshsNodePutIntIfAbsent(extNode, "GeneratePulseInterval", 10);
	sshsNodePutIntIfAbsent(extNode, "GeneratePulseLength", 5);

	// Install default listeners to signal configuration updates asynchronously.
	sshsNodeAddAttrListener(dvsNode, cstate->deviceHandle, &DVSFilterConfigListener);
	sshsNodeAddAttrListener(apsNode, cstate->deviceHandle, &APSQuadROIConfigListener);
	sshsNodeAddAttrListener(extNode, cstate->deviceHandle, &ExternalInputGeneratorConfigListener);
	sshsNodeAddAttrListener(sshsGetRelativeNode(moduleData->moduleNode, "chip/"), cstate, &ChipSRListener);
	// The chip SR needs to be updated also when GlobalShutter in APS changes.
	sshsNodeAddAttrListener(sshsGetRelativeNode(moduleData->moduleNode, "aps/"), cstate, &ChipSRListener);

	// Walk all bias nodes and install the default handler for changes.
	size_t numBiasNodes;
	sshsNode *biasNodes = sshsNodeGetChildren(sshsGetRelativeNode(moduleData->moduleNode, "bias/"), &numBiasNodes);

	for (size_t i = 0; i < numBiasNodes; i++) {
		sshsNodeAddAttrListener(biasNodes[i], cstate, &BiasesListener);
	}

	free(biasNodes);

	if (!initializeCommonConfiguration(moduleData, cstate, &dataAcquisitionThread)) {
		return (false);
	}

	caerLog(LOG_DEBUG, moduleData->moduleSubSystemString, "Initialized DAVISFX3 module successfully.");
	return (true);
}

static void *dataAcquisitionThread(void *inPtr) {
	// inPtr is a pointer to module data.
	caerModuleData data = inPtr;
	davisFX3State state = data->moduleState;
	davisCommonState cstate = &state->cstate;

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "Initializing data acquisition thread ...");

	// Send default start-up biases and config values to device before enabling it.
	sendBiases(data->moduleNode, cstate);
	sendChipSR(data->moduleNode, cstate);
	sendDVSFilterConfig(data->moduleNode, cstate->deviceHandle); // FX3 only.
	sendAPSQuadROIConfig(data->moduleNode, cstate->deviceHandle); // FX3 only.
	sendExternalInputGeneratorConfig(data->moduleNode, cstate->deviceHandle); // FX3 only.
	sendEnableDataConfig(data->moduleNode, cstate->deviceHandle);

	// Create buffers as specified in config file.
	sshsNode usbNode = sshsGetRelativeNode(data->moduleNode, "usb/");
	allocateDebugTransfers(state);
	allocateDataTransfers(cstate, sshsNodeGetInt(usbNode, "BufferNumber"), sshsNodeGetInt(usbNode, "BufferSize"));

	// Handle USB events (1 second timeout).
	struct timeval te = { .tv_sec = 0, .tv_usec = 1000000 };

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "Data acquisition thread ready to process events.");

	while (atomic_ops_uint_load(&data->running, ATOMIC_OPS_FENCE_NONE) != 0 && cstate->activeDataTransfers > 0) {
		// Check config refresh, in this case to adjust buffer sizes.
		if (atomic_ops_uint_load(&data->configUpdate, ATOMIC_OPS_FENCE_NONE) != 0) {
			dataAcquisitionThreadConfig(data);
		}

		libusb_handle_events_timeout(cstate->deviceContext, &te);
	}

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "Shutting down data acquisition thread ...");

	// Cancel all transfers and handle them.
	deallocateDataTransfers(cstate);
	deallocateDebugTransfers(state);

	// Ensure parent also shuts down (on disconnected device for example).
	sshsNodePutBool(data->moduleNode, "shutdown", true);

	caerLog(LOG_DEBUG, data->moduleSubSystemString, "Data acquisition thread shut down.");

	return (NULL);
}

static void allocateDebugTransfers(davisFX3State state) {
	// Set number of transfers and allocate memory for the main transfer array.

	// Allocate transfers and set them up.
	for (size_t i = 0; i < DEBUG_TRANSFER_NUM; i++) {
		state->debugTransfers[i] = libusb_alloc_transfer(0);
		if (state->debugTransfers[i] == NULL) {
			caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
				"Unable to allocate further libusb transfers (debug channel, %zu of %" PRIu32 ").", i,
				DEBUG_TRANSFER_NUM);
			continue;
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

			continue;
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
			state->activeDebugTransfers++;
		}
		else {
			caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
				"Unable to submit libusb transfer %zu (debug channel). Error: %s (%d).", i, libusb_strerror(errno),
				errno);

			// The transfer buffer is freed automatically here thanks to
			// the LIBUSB_TRANSFER_FREE_BUFFER flag set above.
			libusb_free_transfer(state->debugTransfers[i]);
			state->debugTransfers[i] = NULL;

			continue;
		}
	}

	if (state->activeDebugTransfers == 0) {
		// Didn't manage to allocate any USB transfers, log failure.
		caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString, "Unable to allocate any libusb transfers.");
	}
}

static void deallocateDebugTransfers(davisFX3State state) {
	// Cancel all current transfers first.
	for (size_t i = 0; i < DEBUG_TRANSFER_NUM; i++) {
		if (state->debugTransfers[i] != NULL) {
			errno = libusb_cancel_transfer(state->debugTransfers[i]);
			if (errno != LIBUSB_SUCCESS && errno != LIBUSB_ERROR_NOT_FOUND) {
				caerLog(LOG_CRITICAL, state->cstate.sourceSubSystemString,
					"Unable to cancel libusb transfer %zu (debug channel). Error: %s (%d).", i, libusb_strerror(errno),
					errno);
				// Proceed with trying to cancel all transfers regardless of errors.
			}
		}
	}

	// Wait for all transfers to go away (0.1 seconds timeout).
	struct timeval te = { .tv_sec = 0, .tv_usec = 100000 };

	while (state->activeDebugTransfers > 0) {
		libusb_handle_events_timeout(state->cstate.deviceContext, &te);
	}
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
	state->activeDebugTransfers--;
	for (size_t i = 0; i < DEBUG_TRANSFER_NUM; i++) {
		// Remove from list, so we don't try to cancel it later on.
		if (state->debugTransfers[i] == transfer) {
			state->debugTransfers[i] = NULL;
		}
	}
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

static void BiasesListener(sshsNode node, void *userData, enum sshs_node_attribute_events event, const char *changeKey,
	enum sshs_node_attr_value_type changeType, union sshs_node_attr_value changeValue) {
	UNUSED_ARGUMENT(changeKey);
	UNUSED_ARGUMENT(changeType);
	UNUSED_ARGUMENT(changeValue);

	davisCommonState cstate = userData;

	if (event == ATTRIBUTE_MODIFIED) {
		// Search through all biases for a matching one and send it out.
		for (size_t i = 0; i < BIAS_MAX_NUM_DESC; i++) {
			if (cstate->chipBiases[i] == NULL) {
				// Reached end of valid biases.
				break;
			}

			if (str_equals(sshsNodeGetName(node), cstate->chipBiases[i]->name)) {
				// Found it, send it.
				spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, cstate->chipBiases[i]->address,
					(*cstate->chipBiases[i]->generatorFunction)(sshsNodeGetParent(node), cstate->chipBiases[i]->name));
				break;
			}
		}
	}
}

static void sendBiases(sshsNode moduleNode, davisCommonState cstate) {
	sshsNode biasNode = sshsGetRelativeNode(moduleNode, "bias/");

	// Go through all the biases and send them all out.
	for (size_t i = 0; i < BIAS_MAX_NUM_DESC; i++) {
		if (cstate->chipBiases[i] == NULL) {
			// Reached end of valid biases.
			break;
		}

		spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, cstate->chipBiases[i]->address,
			(*cstate->chipBiases[i]->generatorFunction)(biasNode, cstate->chipBiases[i]->name));
	}
}

static void ChipSRListener(sshsNode node, void *userData, enum sshs_node_attribute_events event, const char *changeKey,
	enum sshs_node_attr_value_type changeType, union sshs_node_attr_value changeValue) {
	davisCommonState cstate = userData;

	if (event == ATTRIBUTE_MODIFIED) {
		if (str_equals(sshsNodeGetName(node), "aps")) {
			if (changeType == BOOL && str_equals(changeKey, "GlobalShutter")) {
				spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, 142, changeValue.boolean);
			}
		}
		else {
			// If not called from 'aps' node, must be 'chip' node.
			// Search through all config-chain settings for a matching one and send it out.
			for (size_t i = 0; i < CONFIGCHAIN_MAX_NUM_DESC; i++) {
				if (cstate->chipConfigChain[i] == NULL) {
					// Reached end of valid config-chain settings.
					break;
				}

				if (str_equals(changeKey, cstate->chipConfigChain[i]->name)) {
					// Found it, send it.
					if (cstate->chipConfigChain[i]->type == BYTE) {
						spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, cstate->chipConfigChain[i]->address,
							changeValue.ubyte);
					}
					else {
						spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, cstate->chipConfigChain[i]->address,
							changeValue.boolean);
					}
					break;
				}
			}
		}
	}
}

static void sendChipSR(sshsNode moduleNode, davisCommonState cstate) {
	sshsNode chipNode = sshsGetRelativeNode(moduleNode, "chip/");
	sshsNode apsNode = sshsGetRelativeNode(moduleNode, "aps/");

	// Go through all the config-chain settings and send them all out.
	for (size_t i = 0; i < CONFIGCHAIN_MAX_NUM_DESC; i++) {
		if (cstate->chipConfigChain[i] == NULL) {
			// Reached end of valid config-chain settings.
			break;
		}

		// Either boolean or byte-wise config-chain settings.
		if (cstate->chipConfigChain[i]->type == BYTE) {
			spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, cstate->chipConfigChain[i]->address,
				sshsNodeGetByte(chipNode, cstate->chipConfigChain[i]->name));
		}
		else {
			spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, cstate->chipConfigChain[i]->address,
				sshsNodeGetBool(chipNode, cstate->chipConfigChain[i]->name));
		}
	}

	// The GlobalShutter setting is sent separately, as it resides
	// in another configuration node (the APS one) to avoid duplication.
	// GS may not exist on chips that don't have it.
	if (sshsNodeAttrExists(apsNode, "GlobalShutter", BOOL)) {
		spiConfigSend(cstate->deviceHandle, FPGA_CHIPBIAS, 142, sshsNodeGetBool(apsNode, "GlobalShutter"));
	}
}
