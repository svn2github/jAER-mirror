/*
 * utils.h
 *
 *  Created on: Apr 24, 2014
 *      Author: raraujo
 */

#ifndef UTILS_H_
#define UTILS_H_
#include "chip.h"
#include <stdint.h>

extern RTC_TIME_T buildTime;


/**
 * Busy looping using the RI timer in the LPC4337
 * @param[in] us microseconds for the delay
 */
void timerDelayUs(uint32_t us);
/**
 * Busy looping using the RI timer in the LPC4337
 * It uses
 * @param[in] ms milliseconds to delays
 */
void timerDelayMs(uint32_t ms);

/**
 * It gets the timestamp in milliseconds of the TIMER1 which is collecting the
 * retine events.
 * This function was added for the IMU InvenSense driver.
 * @param[out] ms pointer where to write the timestamp
 */
void getTimerMs(uint32_t * ms);

/**
 * It disable the unused peripherals' clocks and PLL
 */
void disablePeripherals();

/**
 * It reset the entire LPC4337 chip
 */
void resetDevice();

/**
 * It enters reprogramming mode, i.e., ISP mode.
 * It mimics the condition of the LP4337 after reset in ISP mode.
 */
void enterReprogrammingMode();

/**
 * @brief	Check if RTC clock is running
 * @return	zero if the RTC clock is not running.
 */
STATIC INLINE uint32_t Chip_RTC_Clock_Running(void) {
	return (LPC_CREG->CREG0 & 0x3) == 0x03;
}

#endif /* UTILS_H_ */
