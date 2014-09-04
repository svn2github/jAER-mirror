/*
 ===============================================================================
 Name        : main.c
 Author      : $(author)
 Version     :
 Copyright   : $(copyright)
 Description : main definition
 ===============================================================================
 */
#include <stdint.h>
#include "chip.h"
#include "EDVS128_LPC43xx.h"
#include "uart.h"
#include "extra_pins.h"
#include "config.h"
#include <cr_section_macros.h>

//Using the NOINIT macros allows the flashed image size to be greatly reduced.
__NOINIT(RAM4) volatile struct eventRingBuffer events;
__NOINIT(RAM5) volatile struct uart_hal uart;
__NOINIT(RAM6) volatile uint32_t __core_m0_has_started__;

#define TIMER_EXT_MATCH_2_SET		(1<<2)
__RAMFUNC(RAM) int main(void) {
	//The M4 core is in a tight loop waiting for the variable to be set to 1.
	__core_m0_has_started__ = 1;
	uint32_t DVSEventPointer;
	uint32_t DVSEventTime, DVSEventTimeOld;
	uint16_t DVSEvent;
	DVSEventTime = DVSEventTimeOld = Chip_TIMER_ReadCapture(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);
	while (1) {
		//Chip_GPIO_SetPinToggle(LPC_GPIO_PORT, 0, 1); //Only for checking quickly this loops speed
		/**
		 * An event is fetched by comparing the captured timestamp from the timer
		 * If there is a new timestamp, the event buffer write pointer is incremented
		 * and a new event recorded along with its timestamp.
		 */
		DVSEventTime = Chip_TIMER_ReadCapture(LPC_TIMER1, TIMER_CAPTURE_CHANNEL);
		if (DVSEventTime != DVSEventTimeOld) {
			DVSEvent = Chip_GPIO_GetPortValue(LPC_GPIO_PORT, EVENT_PORT) & PIN_ALL_ADDR;
			events.currentEventRate++;
			DVSEventPointer = ((events.eventBufferWritePointer + 1) & DVS_EVENTBUFFER_MASK);
			int32_t freeSpace = (events.eventBufferReadPointer - DVSEventPointer) & DVS_EVENTBUFFER_MASK;
			if (freeSpace < 4) {
				while (events.ringBufferLock) {
					__NOP(); //Wait for the M4 to finish with the queue
				}
				events.eventBufferReadPointer = ((events.eventBufferReadPointer + 1) & DVS_EVENTBUFFER_MASK);
			}
			events.eventBufferA[DVSEventPointer] = DVSEvent; // store event
			events.eventBufferTimeLow[DVSEventPointer] = DVSEventTime; // store event time
			events.eventBufferWritePointer = DVSEventPointer; // Only update the write pointer after being finished with the write operation
			DVSEventTimeOld = DVSEventTime;
		}
		/*
		 * UART1 should handle CTs and RTS in hardware
		 * TODO: this is an open issue
		 */
#if UART_PORT_DEFAULT == 0
		if (Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, CTS0_GPIO_PORT, CTS0_GPIO_PIN) == 0
				&& (LPC_UART->LSR & UART_LSR_THRE)) { // no rts stop signal
#endif
			int i = 15; //Use the TX FIFO
			while (bytesToSend(&uart) && i) {
				LPC_UART->THR = popByteFromTransmissionBuffer(&uart);
				--i;
			}
#if LOW_POWER_MODE
			if (!byteToSend(&uart) && M4Sleeping(&uart)) { // signal M4 TX is done
				uart.txSleepingFlag = 0;
				/**
				 * Initiate interrupt on other processor
				 * Upon calling this function generates and interrupt on the other
				 * core. Ex. if called from M0 core it generates interrupt on M4 core
				 * and vice versa.
				 */
				__DSB();
				__SEV();
			}
#endif
#if UART_PORT_DEFAULT == 0
		}
#endif

		if ( LPC_UART->LSR & UART_LSR_RDR) {
			uint32_t freeSpace = freeSpaceForReception(&uart);
			//We leave the character in the UART buffer
			if (freeSpace > 0) {
				pushByteToReception(&uart, LPC_UART->RBR);
				if (freeSpace <= RX_WARNING) {
					//If we get to here the M4 is taking too much time to parse the input
					Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, RTS0_GPIO_PORT, RTS0_GPIO_PIN); //Signal busy to the DTE
					Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, LED1_PORT_GPIO, LED1_PIN_GPIO); //Turn on the LED
				} else {
					Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, RTS0_GPIO_PORT, RTS0_GPIO_PIN); //Signal ready to the DTE
				}
			}
		}
		/**
		 * This is a work around for the hardware limitations
		 * of the timer in the LPc4337.
		 * The match 2 channel of each channels is used for setting the timer period
		 * and when it resets, it sets the external match bit.
		 * This core is checking for this bit and it sets the two output channels to high
		 * while keeping the default configuration of the external match actions.
		 */
		if ( LPC_TIMER0->EMR & TIMER_EXT_MATCH_2_SET) {
			//The timer0 is using channels 0 and 3 for the outputs.
			LPC_TIMER0->EMR = (((uint32_t) 9) << 0) | (((uint32_t) TIMER_EXTMATCH_CLEAR) << 4)
					| (((uint32_t) TIMER_EXTMATCH_SET) << 8) | (((uint32_t) TIMER_EXTMATCH_CLEAR) << 10);
		}
		if ( LPC_TIMER2->EMR & TIMER_EXT_MATCH_2_SET) {
			//The timer2 is using channels 0 and 1 for the outputs.
			LPC_TIMER2->EMR = (((uint32_t) 3) << 0) | (((uint32_t) TIMER_EXTMATCH_CLEAR) << 4)
					| (((uint32_t) TIMER_EXTMATCH_CLEAR) << 6) | (((uint32_t) TIMER_EXTMATCH_SET) << 8);
		}
		if ( LPC_TIMER3->EMR & TIMER_EXT_MATCH_2_SET) {
			//The timer3 is using channels 0 and 1 for the outputs.
			LPC_TIMER3->EMR = (((uint32_t) 3) << 0) | (((uint32_t) TIMER_EXTMATCH_CLEAR) << 4)
					| (((uint32_t) TIMER_EXTMATCH_CLEAR) << 6) | (((uint32_t) TIMER_EXTMATCH_SET) << 8);
		}
	}

	return 0;
}
