/*
 * common.c
 *
 *  Created on: May 25, 2015
 *      Author: llongi
 */

#include "libcaer.h"
#include <stdatomic.h>
#include <stdarg.h>
#include <time.h>
#include <unistd.h>

static atomic_uint_least8_t caerLogLevel = ATOMIC_VAR_INIT(LOG_ERROR);

void caerLogLevelSet(uint8_t logLevel) {
	atomic_store(&caerLogLevel, logLevel);
}

uint8_t caerLogLevelGet(void) {
	return (atomic_load(&caerLogLevel));
}

void caerLog(uint8_t logLevel, const char *subSystem, const char *format, ...) {
	// Check that subSystem and format are defined correctly.
	if (subSystem == NULL || format == NULL) {
		caerLog(LOG_ERROR, "Logger", "Missing subSystem or format strings. Neither can be NULL.");
		return;
	}

	// Only log messages above the specified level.
	if (logLevel <= atomic_load(&caerLogLevel)) {
		// First prepend the time.
		time_t currentTimeEpoch = time(NULL);

		struct tm currentTime;
		localtime_r(&currentTimeEpoch, &currentTime);

		// Following time format uses exactly 19 characters (5 separators,
		// 4 year, 2 month, 2 day, 2 hours, 2 minutes, 2 seconds).
		size_t currentTimeStringLength = 19;
		char currentTimeString[currentTimeStringLength + 1]; // + 1 for terminating NUL byte.
		strftime(currentTimeString, currentTimeStringLength + 1, "%Y-%m-%d %H:%M:%S", &currentTime);

		// Prepend debug level as a string to format.
		const char *logLevelString;
		switch (logLevel) {
			case LOG_EMERGENCY:
				logLevelString = "EMERGENCY";
				break;

			case LOG_ALERT:
				logLevelString = "ALERT";
				break;

			case LOG_CRITICAL:
				logLevelString = "CRITICAL";
				break;

			case LOG_ERROR:
				logLevelString = "ERROR";
				break;

			case LOG_WARNING:
				logLevelString = "WARNING";
				break;

			case LOG_NOTICE:
				logLevelString = "NOTICE";
				break;

			case LOG_INFO:
				logLevelString = "INFO";
				break;

			case LOG_DEBUG:
				logLevelString = "DEBUG";
				break;

			default:
				logLevelString = "UNKNOWN";
				break;
		}

		// Copy all strings into one and ensure NUL termination.
		size_t logLength = (size_t) snprintf(NULL, 0, "%s: %s: %s: %s\n", currentTimeString, logLevelString, subSystem, format);
		char logString[logLength + 1];
		snprintf(logString, logLength + 1, "%s: %s: %s: %s\n", currentTimeString, logLevelString, subSystem, format);

		va_list argptr;

		va_start(argptr, format);
		vfprintf(stderr, logString, argptr);
		va_end(argptr);
	}
}

void caerBitArrayCopy(uint8_t *src, size_t srcPos, uint8_t *dest, size_t destPos, size_t length) {
	size_t copyOffset = 0;

	while (copyOffset < length) {
		size_t srcBytePos = (srcPos + copyOffset) >> 3;
		size_t srcBitPos = (srcPos + copyOffset) & 0x07;
		uint8_t srcBitMask = U8T(0x80 >> srcBitPos);

		size_t destBytePos = (destPos + copyOffset) >> 3;
		size_t destBitPos = (destPos + copyOffset) & 0x07;
		uint8_t destBitMask = U8T(0x80 >> destBitPos);

		if ((src[srcBytePos] & srcBitMask) != 0) {
			// Set bit.
			dest[destBytePos] |= destBitMask;
		}
		else {
			// Clear bit.
			dest[destBytePos] &= U8T(~destBitMask);
		}

		copyOffset++;
	}
}
