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
#include "minirob.h"
#include "utils.h"
#include "cr_start_m0.h"
#include "build_defs.h"
//Uncomment the line below to activate test mode.
//#include "test.h"

#include <NXP/crp.h>

// Variable to store CRP value in. Will be placed automatically
// by the linker when "Enable Code Read Protect" selected.
// See crp.h header for more information
__CRP const unsigned int CRP_WORD = CRP_NO_CRP;


RTC_TIME_T buildTime;//Holds the build time to set the RTC after enabling it

int main(void) {
#if EXTENDED_TIMESTAMP && USE_SDCARD
	uint16_t DVSEventTimeHigh;
#endif
	uint32_t DVSEventPointer;
	uint32_t DVSEventTimeLow;
	uint16_t DVSEvent;
	uint32_t timeStampMemory = 0;
	uint32_t timeStampDelta = 0;
	ExtraPinsInit();
	disablePeripherals();
	Chip_RIT_Init(LPC_RITIMER);
	RTC_TIME_T build = { .time = { BUILD_SEC_INT, BUILD_MIN_INT, BUILD_HOUR_INT, BUILD_DAY_INT, 0, 1, BUILD_MONTH_INT, BUILD_YEAR_INT } };
	buildTime = build;
#if USE_IMU_DATA
	MPU9105Init();
#endif
#if USE_SDCARD
	SDCardInit();
#endif
	DVS128ChipInit();
	DacInit();
	UARTInit(LPC_UART, BAUD_RATE_DEFAULT); /* baud rate setting */
	initMotors();
	PWMInit();
	sensorsInit();
#if USE_MINIROB
	MiniRobInit();
#endif

#ifdef TEST_RUN
	test();
	//This will not return
#endif

	LED1SetOn();
	// Start M0APP slave processor
	cr_start_m0(&__core_m0app_START__);
	LED1SetOff();

	LED0SetOn();
	LED0SetBlinking(ENABLE);
	UARTShowVersion();
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
#if USE_MINIROB
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

		if (bytesToSend(&uart)) {				// wait for TX to finish sending!
#if LOW_POWER_MODE
				uart.txSleepingFlag = 1;
				__WFE();
#endif
			continue;
		}
		// *****************************************************************************
		//    processEventsIterate();
		// *****************************************************************************
		if (events.eventBufferWritePointer == events.eventBufferReadPointer) {		// more events in buffer to process?
			continue;
		}
		events.ringBufferLock = true;
		events.eventBufferReadPointer = ((events.eventBufferReadPointer + 1) & DVS_EVENTBUFFER_MASK);// increase read pointer
		DVSEventPointer = events.eventBufferReadPointer;  // cache the value to be faster
		DVSEvent = events.eventBufferA[DVSEventPointer];		 // fetch event from buffer
		DVSEventTimeLow = events.eventBufferTimeLow[DVSEventPointer];	// fetch event from buffer
#if EXTENDED_TIMESTAMP && USE_SDCARD
		DVSEventTimeHigh = events.eventBufferTimeHigh[DVSEventPointer];
#endif
		events.ringBufferLock = false;
		if (enableEventSending) {
			if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN) {
				pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80); // 1st byte to send (Y-address)
				pushByteToTransmission(&uart, DVSEvent & 0xFF);	// 2nd byte to send (X-address)
			} else if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN_TSVB) {
				// Calculate delta...
				timeStampDelta = DVSEventTimeLow - timeStampMemory;

				// check whether to send one, two or three bytes...
				if (timeStampDelta < 0x7F) {
					// Only 7 TS bits need to be sent
					pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80);      // 1st byte to send (Y-address)
					pushByteToTransmission(&uart, DVSEvent & 0xFF);                      // 2nd byte to send (X-address)
					pushByteToTransmission(&uart, ((timeStampDelta) & 0x7F) | 0x80); // 3rd byte to send (7bit Delta TS, MSBit set to 1)
				} else {
					if (timeStampDelta < 0x3FFF) {
						// Only 14 TS bits need to be sent
						pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80);  // 1st byte to send (Y-address)
						pushByteToTransmission(&uart, (DVSEvent) & 0xFF);                // 2nd byte to send (X-address)
						pushByteToTransmission(&uart, (timeStampDelta >> 7) & 0x7F); // 3rd byte to send (upper 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, ((timeStampDelta) & 0x7F) | 0x80); // 4th byte to send (lower 7bit Delta TS, MSBit set to 1)
					} else {
						// 21 TS bits need to be sent
						pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80);  // 1st byte to send (Y-address)
						pushByteToTransmission(&uart, (DVSEvent) & 0xFF);                // 2nd byte to send (X-address)
						pushByteToTransmission(&uart, (timeStampDelta >> 14) & 0x7F); // 3rd byte to send (upper 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, (timeStampDelta >> 7) & 0x7F); // 4th byte to send (middle 7bit Delta TS, MSBit set to 0)
						pushByteToTransmission(&uart, ((timeStampDelta) & 0x7F) | 0x80); // 5th byte to send (lower 7bit Delta TS, MSBit set to 1)
					}
				}
				timeStampMemory = DVSEventTimeLow;              // Save the current TS in delta
			} else if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN_TS2B) {
				pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80); // 1st byte to send (Y-address)
				pushByteToTransmission(&uart, DVSEvent & 0xFF);	// 2nd byte to send (X-address)
				pushByteToTransmission(&uart, (DVSEventTimeLow >> 8) & 0xFF);// 3rd byte to send (time stamp high byte)
				pushByteToTransmission(&uart, DVSEventTimeLow & 0xFF);	// 4th byte to send (time stamp low byte)
			} else if (eDVSDataFormat == EDVS_DATA_FORMAT_BIN_TS3B) {
				pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80); // 1st byte to send (Y-address)
				pushByteToTransmission(&uart, DVSEvent & 0xFF);	// 2nd byte to send (X-address)
				pushByteToTransmission(&uart, (DVSEventTimeLow >> 16) & 0xFF);// 3rd byte to send (time stamp high byte)
				pushByteToTransmission(&uart, (DVSEventTimeLow >> 8) & 0xFF);	// 4th byte to send (time stamp)
				pushByteToTransmission(&uart, DVSEventTimeLow & 0xFF);	// 5th byte to send (time stamp low byte)
			} else {
				pushByteToTransmission(&uart, (DVSEvent >> 8) | 0x80); // 1st byte to send (Y-address)
				pushByteToTransmission(&uart, DVSEvent & 0xFF);	// 2nd byte to send (X-address)
				pushByteToTransmission(&uart, (DVSEventTimeLow >> 24) & 0xFF);// 3rd byte to send (time stamp high byte)
				pushByteToTransmission(&uart, (DVSEventTimeLow >> 16) & 0xFF);// 4th byte to send (time stamp high byte)
				pushByteToTransmission(&uart, (DVSEventTimeLow >> 8) & 0xFF);	// 5th byte to send (time stamp)
				pushByteToTransmission(&uart, DVSEventTimeLow & 0xFF);	// 6th byte to send (time stamp low byte)
			}
		}
#if USE_SDCARD
		//Recording session in SD using the SPI slot
		if (sdcard.isRecording == 1) {
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = (DVSEvent >> 8) & 0x7F;
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = DVSEvent & 0xFF;
#if EXTENDED_TIMESTAMP
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = (DVSEventTimeHigh >> 8) & 0xFF;
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = DVSEventTimeHigh & 0xFF;
#endif
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = (DVSEventTimeLow >> 24) & 0xFF;
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = (DVSEventTimeLow >> 16) & 0xFF;
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = (DVSEventTimeLow >> 8) & 0xFF;
			sdcard.fileBuffer[sdcard.fileBufferIndex++] = DVSEventTimeLow & 0xFF;
			//We ensure that fileBuffer is never overrun because FILE_BUFFER_SIZE is a multiple of the number of bytes needed
			if (sdcard.fileBufferIndex >= FILE_BUFFER_SIZE) {
				f_write(&sdcard.outputFile, sdcard.fileBuffer, sdcard.fileBufferIndex, &sdcard.bytesWritten); //write data
				sdcard.bytesWrittenPerSecond += sdcard.bytesWritten;
				sdcard.fileBufferIndex = 0;
			}
		}
#endif
	}

}
