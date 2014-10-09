/* Kernel includes. */
#include <cr_section_macros.h>
#include "chip.h"
#include "config.h"
#include "motors.h"
#include "sleep.h"
#include "sensors.h"
#include "uart.h"
#include "EDVS128_LPC43xx.h"
#include "mpu9105.h"
#include "sdcard.h"
#include "extra_pins.h"
#include "pwm.h"
#include "pushbot.h"
#include "utils.h"
#include "cr_start_m0.h"
#include "build_defs.h"
#include "xprintf.h"
//Uncomment the line below to activate test mode.
//#include "test.h"

#include <NXP/crp.h>

// Variable to store CRP value in. Will be placed automatically
// by the linker when "Enable Code Read Protect" selected.
// See crp.h header for more information
__CRP const unsigned int CRP_WORD = CRP_NO_CRP;

RTC_TIME_T buildTime; //Holds the build time to set the RTC after enabling it

int main(void) {
	uint32_t DVSEventPointer;
	uint32_t DVSEventTimeLow;
	uint16_t DVSEvent;
	uint32_t timeStampMemory = 0, timeStampDelta = 0;
	ExtraPinsInit();
	disablePeripherals();
	Chip_RIT_Init(LPC_RITIMER);
	RTC_TIME_T build = { .time = { BUILD_SEC_INT, BUILD_MIN_INT, BUILD_HOUR_INT, BUILD_DAY_INT, 0, 1, BUILD_MONTH_INT,
	BUILD_YEAR_INT } };
	buildTime = build;
	//This should be one of the first initializations routines to run.
	sensorsInit();
	DVS128ChipInit();
	DacInit();
	UARTInit(LPC_UART, BAUD_RATE_DEFAULT); /* baud rate setting */
	initMotors();
	PWMInit();

	LED1SetOn();
	// Start M0APP slave processor
	cr_start_m0(&__core_m0app_START__);
	LED1SetOff();

	LED0SetOn();
	LED0SetBlinking(ENABLE);
	UARTShowVersion();

#if USE_IMU_DATA
	timerDelayMs(100);
	int32_t initReturn = MPU9105Init();
	if ( initReturn == MPU_ERROR ){
		xputs("Error initializing the IMU!\nNo motion data\n");
	} else if (initReturn == MPL_ERROR){
		xputs("Error initializing the MPL!\nNo calibrated or fused data\n");
	}
#endif
#if USE_SDCARD
	SDCardInit();
#endif
#if USE_PUSHBOT
	MiniRobInit();
#endif

#ifdef TEST_RUN
	test();
	//This will not return
#endif

	for (;;) {
		if (ledBlinking && toggleLed0) {
			LED0Toggle();
			toggleLed0 = 0;
		}
		// *****************************************************************************
		//    UARTIterate();
		// *****************************************************************************
		while (bytesReceived(&uart)) {  // incoming char available?
			UART0ParseNewChar(popByteFromReceptionBuffer(&uart));
		}
#if USE_IMU_DATA
		updateIMUData();
#endif
#if USE_PUSHBOT
		refreshMiniRobSensors();
		if (motor0.updateRequired) {
			motor0.updateRequired = 0;
			updateMotorController(MOTOR0);
		}
		if (motor1.updateRequired) {
			motor1.updateRequired = 0;
			updateMotorController(MOTOR1);
		}
#endif
		if (sensorRefreshRequested) {
			sensorRefreshRequested = 0;
			for (int i = 0; i < sensorsEnabledCounter; ++i) {
				if (enabledSensors[i]->triggered) {
					enabledSensors[i]->refresh();
					enabledSensors[i]->triggered = 0;
				}
			}
		}
		// *****************************************************************************
		//    processEventsIterate();
		// *****************************************************************************
		if (events.eventBufferWritePointer == events.eventBufferReadPointer) {		// more events in buffer to process?
			continue;
		}
		if (eDVSProcessingMode < EDVS_PROCESS_EVENTS) { //Not processing events
			if (freeSpaceForTranmission(&uart) < (TX_BUFFER_SIZE - 32) || !(eDVSProcessingMode & EDVS_STREAM_EVENTS)) {
#if LOW_POWER_MODE
				uart.txSleepingFlag = 1;
				__WFE();
#endif
				continue; //Wait until the buffer is empty.
			}
		}
		/*We are either processing events or streaming them.
		 * If streaming the buffer must be empty at this point
		 */
		events.ringBufferLock = true;
		events.eventBufferReadPointer = ((events.eventBufferReadPointer + 1) & DVS_EVENTBUFFER_MASK); // increase read pointer
		DVSEventPointer = events.eventBufferReadPointer;  // cache the value to be faster
		DVSEvent = events.eventBufferA[DVSEventPointer];		 // fetch event from buffer
		DVSEventTimeLow = events.eventBufferTimeLow[DVSEventPointer];	// fetch event from buffer
		events.ringBufferLock = false;
		if (eDVSProcessingMode & EDVS_STREAM_EVENTS) {
			if (freeSpaceForTranmission(&uart) > 6) {	// wait for TX to finish sending!
				pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80);      // 1st byte to send (Y-address)
				pushByteToTransmission(&uart, DVSEvent & 0xFF);                  // 2nd byte to send (X-address)
				if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN_TSVB) {
					// Calculate delta...
					timeStampDelta = DVSEventTimeLow - timeStampMemory;
					timeStampMemory = DVSEventTimeLow;              // Save the current TS in delta
					// check how many bytes we need to send
					if (timeStampDelta < 0x7F) {
						// Only 7 TS bits need to be sent
						pushByteToTransmission(&uart, (timeStampDelta & 0x7F) | 0x80); // 3rd byte to send (7bit Delta TS, MSBit set to 1)
					} else if (timeStampDelta < 0x3FFF) {
						// Only 14 TS bits need to be sent
						pushByteToTransmission(&uart, (timeStampDelta >> 7) & 0x7F); // 3rd byte to send (upper 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, (timeStampDelta & 0x7F) | 0x80); // 4th byte to send (lower 7bit Delta TS, MSBit set to 1)
					} else if (timeStampDelta < 0x1FFFFF) {
						// Only 21 TS bits need to be sent
						pushByteToTransmission(&uart, (timeStampDelta >> 14) & 0x7F); // 3rd byte to send (upper 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, (timeStampDelta >> 7) & 0x7F); // 4th byte to send (middle 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, (timeStampDelta & 0x7F) | 0x80); // 5th byte to send (lower 7bit Delta TS, MSBit set to 1)
					} else {
						// 28 TS bits need to be sent
						pushByteToTransmission(&uart, (timeStampDelta >> 21) & 0x7F); // 3rd byte to send (upper 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, (timeStampDelta >> 14) & 0x7F); // 4rd byte to send (upper 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, (timeStampDelta >> 7) & 0x7F); // 5th byte to send (middle 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, (timeStampDelta & 0x7F) | 0x80); // 6th byte to send (lower 7bit Delta TS, MSBit set to 1)
					}
				} else if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN_TS2B) {
					pushByteToTransmission(&uart, (DVSEventTimeLow >> 8) & 0xFF); // 3rd byte to send (time stamp high byte)
					pushByteToTransmission(&uart, DVSEventTimeLow & 0xFF);	// 4th byte to send (time stamp low byte)
				} else if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN_TS3B) {
					pushByteToTransmission(&uart, (DVSEventTimeLow >> 16) & 0xFF);// 3rd byte to send (time stamp high byte)
					pushByteToTransmission(&uart, (DVSEventTimeLow >> 8) & 0xFF);	// 4th byte to send (time stamp)
					pushByteToTransmission(&uart, DVSEventTimeLow & 0xFF);	// 5th byte to send (time stamp low byte)
				} else if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN_TS4B) {
					pushByteToTransmission(&uart, (DVSEventTimeLow >> 24) & 0xFF);// 3rd byte to send (time stamp high byte)
					pushByteToTransmission(&uart, (DVSEventTimeLow >> 16) & 0xFF);// 4th byte to send (time stamp high byte)
					pushByteToTransmission(&uart, (DVSEventTimeLow >> 8) & 0xFF);	// 5th byte to send (time stamp)
					pushByteToTransmission(&uart, DVSEventTimeLow & 0xFF);	// 6th byte to send (time stamp low byte)
				}
			}
		}
#if USE_SDCARD
		//Recording session in SD using the SPI slot
		if (sdcard.isRecording == 1) {
			sdcard.eventsRecordedPerSecond++;
			// Calculate delta...
			sdcard.timeStampDelta = DVSEventTimeLow - sdcard.timeStampMemory;
			sdcard.timeStampMemory = DVSEventTimeLow;	// Save the current TS in delta
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = (DVSEvent >> 8) & 0x7F;
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = DVSEvent & 0xFF;
			// check how many bytes we need to record
			if (sdcard.timeStampDelta < 0x7F) {
				// Only 7 TS bits need to be saved
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta & 0x7F) | 0x80;//7bit Delta TS, MSBit set to 1
			} else if (sdcard.timeStampDelta < 0x3FFF) {
				// Only 14 TS bits need to be saved
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta >> 7) & 0x7F;//upper 7bit Delta TS, MSBit set to 0
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta & 0x7F) | 0x80;//lower 7bit Delta TS, MSBit set to 1
			} else if (timeStampDelta < 0x1FFFFF) {
				// Only 21 TS bits need to be saved
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta >> 14) & 0x7F;	//upper 7bit Delta TS, MSBit set to 0
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta >> 7) & 0x7F;//middle 7bit Delta TS, MSBit set to 0
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta & 0x7F) | 0x80;//lower 7bit Delta TS, MSBit set to 1
			} else {
				// 28 TS bits need to be saved
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta >> 21) & 0x7F;	//upper 7bit Delta TS, MSBit set to 0
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta >> 14) & 0x7F;	//upper 7bit Delta TS, MSBit set to 0
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta >> 7) & 0x7F;//middle 7bit Delta TS, MSBit set to 0
				sdcard.fileBuffer[sdcard.fileBufferIndex++] = (sdcard.timeStampDelta & 0x7F) | 0x80;//lower 7bit Delta TS, MSBit set to 1
			}
			if ((FILE_BUFFER_SIZE - sdcard.fileBufferIndex) < 6) {
				//write data	.
				LED1SetOn();
				if (f_write(&sdcard.outputFile, sdcard.fileBuffer, sdcard.fileBufferIndex, &sdcard.bytesWritten)) {
					setSDCardRecord(DISABLE); //There was an error. No need to record anymore.
				}
				LED1SetOff();
				sdcard.bytesWrittenPerSecond += sdcard.bytesWritten;
				sdcard.fileBufferIndex = 0;
			}
		}
#endif
	}

}
