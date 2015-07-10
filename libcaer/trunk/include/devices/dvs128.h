/*
 * dvs128.h
 *
 *  Created on: May 26, 2015
 *      Author: llongi
 */

#ifndef LIBCAER_DEVICES_DVS128_H_
#define LIBCAER_DEVICES_DVS128_H_

#include "events/packetContainer.h"
#include "events/polarity.h"
#include "events/special.h"

#define DVS128_CONFIG_DVS  0
#define DVS128_CONFIG_BIAS 1

#define DVS128_CONFIG_DVS_RUN             0
#define DVS128_CONFIG_DVS_TIMESTAMP_RESET 1
#define DVS128_CONFIG_DVS_ARRAY_RESET     2

#define DVS128_CONFIG_BIAS_CAS     0
#define DVS128_CONFIG_BIAS_INJGND  1
#define DVS128_CONFIG_BIAS_PUX     2
#define DVS128_CONFIG_BIAS_PUY     3
#define DVS128_CONFIG_BIAS_REQPD   4
#define DVS128_CONFIG_BIAS_REQ     5
#define DVS128_CONFIG_BIAS_FOLL    6
#define DVS128_CONFIG_BIAS_PR      7
#define DVS128_CONFIG_BIAS_REFR    8
#define DVS128_CONFIG_BIAS_DIFF    9
#define DVS128_CONFIG_BIAS_DIFFON  10
#define DVS128_CONFIG_BIAS_DIFFOFF 11

struct caer_dvs128_info {
	uint16_t deviceID;
	char *deviceString;
	// System information fields
	uint16_t logicVersion;
	bool deviceIsMaster;
	// DVS specific fields
	uint16_t dvsSizeX;
	uint16_t dvsSizeY;
};

typedef struct caer_dvs128_info *caerDVS128Info;

typedef struct caer_dvs128_handle *caerDVS128Handle;

caerDVS128Handle caerDVS128Open(uint8_t busNumberRestrict, uint8_t devAddressRestrict,
	const char *serialNumberRestrict);
bool caerDVS128Close(caerDVS128Handle handle);
caerDVS128Info caerDVS128InfoGet(caerDVS128Handle handle);
bool caerDVS128ConfigSet(caerDVS128Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t param);
bool caerDVS128ConfigGet(caerDVS128Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t *param);
bool caerDVS128DataStart(caerDVS128Handle);
bool caerDVS128DataStop(caerDVS128Handle handle);
caerEventPacketContainer caerDVS128DataGet(caerDVS128Handle handle);

#endif /* LIBCAER_DEVICES_DVS128_H_ */
