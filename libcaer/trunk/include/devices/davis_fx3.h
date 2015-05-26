/*
 * davis_fx3.h
 *
 *  Created on: May 26, 2015
 *      Author: llongi
 */

#ifndef LIBCAER_DEVICES_DAVIS_FX3_H_
#define LIBCAER_DEVICES_DAVIS_FX3_H_

#include "davis.h"

typedef struct caer_davis_fx3_handle *caerDavisFX3Handle;

caerDavisFX3Handle caerDavisFX3Open(uint8_t busNumberRestrict, uint8_t devAddressRestrict,
	const char *serialNumberRestrict);
bool caerDavisFX3Close(caerDavisFX3Handle handle);
caerDavisInfo caerDavisFX3InfoGet(caerDavisFX3Handle handle);
bool caerDavisFX3ConfigSet(caerDavisFX3Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t param);
bool caerDavisFX3ConfigGet(caerDavisFX3Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t *param);
bool caerDavisFX3DataStart(caerDavisFX3Handle handle);
bool caerDavisFX3DataStop(caerDavisFX3Handle handle);
caerEventPacketContainer caerDavisFX3DataGet(caerDavisFX3Handle handle);

#endif /* LIBCAER_DEVICES_DAVIS_FX3_H_ */
