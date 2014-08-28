/*
 * sdcard.h
 *
 *  Created on: May 28, 2014
 *      Author: raraujo
 */

#ifndef SDCARD_H_
#define SDCARD_H_
#include "ff.h"
#include <stdint.h>

#define STA_OK			0x00

#define SD_ERROR 		1

#define FILE_BUFFER_SIZE		(_MAX_SS * 8)

struct sdcard {
	uint32_t timeStampMemory;
	uint32_t timeStampDelta;
	uint32_t fileBufferIndex;
	uint32_t bytesWrittenPerSecond;
	uint32_t eventsRecordedPerSecond;
	uint8_t shouldRecord; //flag to start recording events in the SD card
	uint8_t isRecording;
	FATFS fs;
	char filename[19];
	UINT bytesWritten;
	FIL outputFile;
	DIR dir;
	uint8_t fileBuffer[FILE_BUFFER_SIZE];				// events recording
};

/**
 * Initialized the SD card pins
 */
extern void SDCardInit(void);

extern struct sdcard sdcard;
/**
 * It enables or disables the flag to start recording events in the SD card.
 * If recording fails for any reason, this variable will not change
 * and it will need to be unset and then set again to retry the recording data.
 * @param flag ENABLE or DISABLE
 */
void setSDCardRecord(uint32_t flag);

/**
 * This function generates a new filename for a file using the RTC current time and a random number.
 *
 * @param filename char array with at least 19 characters
 */
extern void getFilename(char filename[19]);

#endif /* SDCARD_H_ */
