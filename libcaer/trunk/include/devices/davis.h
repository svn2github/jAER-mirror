/*
 * davis.h
 *
 *  Created on: May 25, 2015
 *      Author: llongi
 */

#ifndef LIBCAER_DEVICES_DAVIS_H_
#define LIBCAER_DEVICES_DAVIS_H_

#include "events/packetContainer.h"
#include "events/polarity.h"
#include "events/special.h"
#include "events/frame.h"
#include "events/imu6.h"

#define DAVIS_CONFIG_MUX      0
#define DAVIS_CONFIG_DVS      1
#define DAVIS_CONFIG_APS      2
#define DAVIS_CONFIG_IMU      3
#define DAVIS_CONFIG_EXTINPUT 4
#define DAVIS_CONFIG_BIAS     5
#define DAVIS_CONFIG_SYSINFO  6
#define DAVIS_CONFIG_USB      9

#define DAVIS_CHIP_DAVIS240A 0
#define DAVIS_CHIP_DAVIS240B 1
#define DAVIS_CHIP_DAVIS240C 2
#define DAVIS_CHIP_DAVIS128  3
#define DAVIS_CHIP_DAVIS346A 4
#define DAVIS_CHIP_DAVIS346B 5
#define DAVIS_CHIP_DAVIS640  6
#define DAVIS_CHIP_DAVISRGB  7
#define DAVIS_CHIP_DAVIS208  8
#define DAVIS_CHIP_DAVIS346C 9

struct caer_davis_info {
	uint16_t deviceID;
	char *deviceString;
	// System information fields
	uint16_t logicVersion;
	bool deviceIsMaster;
	uint16_t logicClock;
	uint16_t adcClock;
	// Chip information fields
	uint16_t chipID;
	// DVS specific fields
	uint16_t dvsSizeX;
	uint16_t dvsSizeY;
	bool dvsHasPixelFilter;
	bool dvsHasBackgroundActivityFilter;
	// APS specific fields
	uint16_t apsSizeX;
	uint16_t apsSizeY;
	uint8_t apsColorFilter;
	bool apsHasGlobalShutter;
	bool apsHasQuadROI;
	bool apsHasExternalADC;
	bool apsHasInternalADC;
	// ExtInput specific fields
	bool extInputHasGenerator;
};

typedef struct caer_davis_info *caerDavisInfo;

#endif /* LIBCAER_DEVICES_DAVIS_H_ */
