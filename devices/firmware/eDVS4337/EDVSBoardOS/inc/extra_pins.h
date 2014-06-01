/*
 * extra_pins.h
 *
 *  Created on: 5 de Ago de 2013
 *      Author: ruka
 */

#ifndef EXTRA_PINS_H_
#define EXTRA_PINS_H_
#include "chip.h"

/* The bit of port 0 that the LPCXpresso LPC43xx LED0 is connected. */
#define LED0_PORT_GPIO  			(0)
#define LED0_PIN_GPIO  				(0)
#define LED0_PORT  					(0)
#define LED0_PIN	 				(0)
/* The bit of port 0 that the LPCXpresso LPC43xx LED1 is connected. */
#define LED1_PORT_GPIO  			(0)
#define LED1_PIN_GPIO  				(1)
#define LED1_PORT  					(0)
#define LED1_PIN	 				(1)

extern volatile uint32_t toggleLed0;
extern uint8_t ledBlinking;
/**
 * It initializes the FTDI reset pin,
 */
void ExtraPinsInit();

/**
 * It disables the green LED
 */
static inline void LED0SetOff(void) {
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO); //Turn on the LED
}
/**
 * It enables the green LED
 */
static inline void LED0SetOn(void) {
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO); //Turn off the LED
}
/**
 * It toggles the green LED
 */
static inline void LED0Toggle(void) {
	Chip_GPIO_SetPinToggle(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO); //Toggle the LED
}
/**
 * It disables the red LED
 */
static inline void LED1SetOff(void) {
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, LED1_PORT_GPIO, LED1_PIN_GPIO); //Turn on the LED
}
/**
 * It enables the red LED
 */
static inline void LED1SetOn(void) {
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, LED1_PORT_GPIO, LED1_PIN_GPIO); //Turn off the LED
}
/**
 * It toggles the red LED
 */
static inline void LED1Toggle(void) {
	Chip_GPIO_SetPinToggle(LPC_GPIO_PORT, LED1_PORT_GPIO, LED1_PIN_GPIO); //Toggle the LED
}
/**
 * It enables or disables the automatic 0.5Hz green LED blinking.
 * @param flag ENABLE or DISABLE
 */
static inline void LED0SetBlinking(uint8_t flag) {
	ledBlinking = flag ? 1 : 0;
}
#endif /* EXTRA_PINS_H_ */
