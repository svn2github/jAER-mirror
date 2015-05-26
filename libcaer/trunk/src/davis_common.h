#ifndef DAVIS_COMMON_H_
#define DAVIS_COMMON_H_

#include "devices/davis.h"
#include "ringbuffer/ringbuffer.h"
#include <libusb.h>
#include <stdatomic.h>

#define APS_READOUT_TYPES_NUM 3
#define APS_READOUT_RESET 0
#define APS_READOUT_SIGNAL 1
#define APS_READOUT_CPRESET 2

#define IMU6_COUNT 15
#define IMU9_COUNT 21

#define DATA_ENDPOINT 0x82

#define VR_FPGA_CONFIG 0xBF

struct davis_state {
	// Data Acquisition Thread -> Mainloop Exchange
	RingBuffer dataExchangeBuffer;
	atomic_ulong dataNotify;
	// USB Device State
	libusb_context *deviceContext;
	libusb_device_handle *deviceHandle;
	// Data Acquisition Thread
	pthread_t dataAcquisitionThread;
	struct libusb_transfer **dataTransfers;
	size_t dataTransfersLength;
	size_t activeDataTransfers;
	// Timestamp fields
	uint32_t wrapAdd;
	uint32_t lastTimestamp;
	uint32_t currentTimestamp;
	// DVS specific fields
	uint32_t dvsTimestamp;
	uint16_t dvsLastY;
	bool dvsGotY;
	bool dvsInvertXY;
	// APS specific fields
	bool apsInvertXY;
	bool apsFlipX;
	bool apsFlipY;
	bool apsIgnoreEvents;
	uint16_t apsWindow0SizeX;
	uint16_t apsWindow0SizeY;
	bool apsGlobalShutter;
	bool apsResetRead;
	bool apsRGBPixelOffsetDirection; // 0 is increasing, 1 is decreasing.
	int16_t apsRGBPixelOffset;
	uint16_t apsCurrentReadoutType;
	uint16_t apsCountX[APS_READOUT_TYPES_NUM];
	uint16_t apsCountY[APS_READOUT_TYPES_NUM];
	uint16_t *apsCurrentResetFrame;
	uint16_t *apsCurrentSignalFrame; // Only used for DAVIS RGB currently.
	// IMU specific fields
	bool imuIgnoreEvents;
	uint8_t imuCount;
	uint8_t imuTmpData;
	float imuAccelScale;
	float imuGyroScale;
	// Packet Container state
	caerEventPacketContainer currentPacketContainer;
	uint32_t maxPacketContainerSize;
	uint32_t maxPacketContainerInterval;
	// Polarity Packet state
	caerPolarityEventPacket currentPolarityPacket;
	uint32_t currentPolarityPacketPosition;
	uint32_t maxPolarityPacketSize;
	uint32_t maxPolarityPacketInterval;
	// Frame Packet state
	caerFrameEventPacket currentFramePacket;
	uint32_t currentFramePacketPosition;
	uint32_t maxFramePacketSize;
	uint32_t maxFramePacketInterval;
	// IMU6 Packet state
	caerIMU6EventPacket currentIMU6Packet;
	uint32_t currentIMU6PacketPosition;
	uint32_t maxIMU6PacketSize;
	uint32_t maxIMU6PacketInterval;
	// Special Packet state
	caerSpecialEventPacket currentSpecialPacket;
	uint32_t currentSpecialPacketPosition;
	uint32_t maxSpecialPacketSize;
	uint32_t maxSpecialPacketInterval;
};

typedef struct davis_state *davisState;

struct davis_handle {
	// Information fields
	struct caer_davis_info info;
	// State for data management, common to all DAVISes.
	struct davis_state state;
};

typedef struct davis_handle *davisHandle;

void spiConfigSend(libusb_device_handle *devHandle, uint8_t moduleAddr, uint8_t paramAddr, uint32_t param);
uint32_t spiConfigReceive(libusb_device_handle *devHandle, uint8_t moduleAddr, uint8_t paramAddr);
bool davisOpen(davisHandle handle, uint16_t VID, uint16_t PID, uint8_t DID_TYPE, uint8_t busNumberRestrict,
	uint8_t devAddressRestrict, const char *serialNumberRestrict);
bool davisInfoInitialize(davisHandle handle);
bool davisStateInitialize(davisHandle handle);

#endif /* DAVIS_COMMON_H_ */
