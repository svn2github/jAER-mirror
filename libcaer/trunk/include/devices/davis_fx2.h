/*
 * davis_fx2.h
 *
 *  Created on: May 26, 2015
 *      Author: llongi
 */

#ifndef LIBCAER_DEVICES_DAVIS_FX2_H_
#define LIBCAER_DEVICES_DAVIS_FX2_H_

#include "davis.h"

typedef struct caer_davis_fx2_handle *caerDavisFX2Handle;

caerDavisFX2Handle caerDavisFX2Open(uint8_t busNumberRestrict, uint8_t devAddressRestrict,
	const char *serialNumberRestrict);
bool caerDavisFX2Close(caerDavisFX2Handle handle);
caerDavisInfo caerDavisFX2InfoGet(caerDavisFX2Handle handle);
bool caerDavisFX2ConfigSet(caerDavisFX2Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t param);
bool caerDavisFX2ConfigGet(caerDavisFX2Handle handle, int8_t modAddr, uint8_t paramAddr, uint32_t *param);
bool caerDavisFX2DataStart(caerDavisFX2Handle handle);
bool caerDavisFX2DataStop(caerDavisFX2Handle handle);
caerEventPacketContainer caerDavisFX2DataGet(caerDavisFX2Handle handle);

#endif /* LIBCAER_DEVICES_DAVIS_FX2_H_ */
