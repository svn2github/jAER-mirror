/*
 * extra_pins.c
 *
 *  Created on: 06/04/2014
 *      Author: ruka
 */
#include "extra_pins.h"
#include "chip.h"

volatile uint32_t toggleLed0 = 0;
uint8_t ledBlinking = 0;


// P1.17 VBAT reset signal
#define VBAT_GND_PORT_GPIO  		(0)
#define VBAT_GND_PIN_GPIO  			(12)
#define VBAT_GND_PORT  				(1)
#define VBAT_GND_PIN  				(17)

// P1.15 FTDI reset signal
#define FTDI_RESET_PORT_GPIO  		(0)
#define FTDI_RESET_PIN_GPIO  		(2)
#define FTDI_RESET_PORT  			(1)
#define FTDI_RESET_PIN  			(15)


void ExtraPinsInit(void) {
	toggleLed0 = 0;
	ledBlinking = 0;
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, VBAT_GND_PORT_GPIO, VBAT_GND_PIN_GPIO); /* set P1.17 as output */
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, VBAT_GND_PORT_GPIO, VBAT_GND_PIN_GPIO); //drive to ground
	Chip_SCU_PinMuxSet(VBAT_GND_PORT, VBAT_GND_PIN, MD_PLN_FAST | FUNC0);

	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, FTDI_RESET_PORT_GPIO, FTDI_RESET_PIN_GPIO); //enable the FTDI
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, FTDI_RESET_PORT_GPIO, FTDI_RESET_PIN_GPIO); /* set P1.15 as output */
	Chip_SCU_PinMuxSet(FTDI_RESET_PORT, FTDI_RESET_PIN, MD_PLN_FAST | FUNC0);

	// set P0.0 as output
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO); //Turn on the LED
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO);
	Chip_SCU_PinMuxSet(LED0_PORT, LED0_PIN, MD_PLN_FAST | FUNC0);

	// set P0.1 as output
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, LED1_PORT_GPIO, LED1_PIN_GPIO); // Keep it Off
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, LED1_PORT_GPIO, LED1_PIN_GPIO);
	Chip_SCU_PinMuxSet(LED1_PORT, LED1_PIN, MD_PLN_FAST | FUNC0);
}

