#ifndef _INCLUDED_FX3_SELECT_H_
#define _INCLUDED_FX3_SELECT_H_ 1

#include "devices/fx3_config.h"

// List of supported devices, select the appropriate one
// If no specific device is selected, the default configuration will be used, consisting of:
// 16-bit Slave FIFO; I2C, SPI and GPIO disabled; support for common vendor requests only
#define EXAMPLE 0
#define SRC_SINK 0
#define DAVISFX3 1
#define COCHLEAFX3 0

// Device specific configuration inclusion
#if EXAMPLE == 1
#include "devices/example/example_config.h"
#endif

#if SRC_SINK == 1
#include "devices/src_sink/src_sink_config.h"
#endif

#if DAVISFX3 == 1
#include "devices/davisfx3/davisfx3_config.h"
#endif

#if COCHLEAFX3 == 1
#include "devices/cochleafx3/cochleafx3_config.h"
#endif

#endif /* _INCLUDED_FX3_SELECT_H_ */
