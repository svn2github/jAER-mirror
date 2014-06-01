/*
 * test.c
 *
 *  Created on: Apr 9, 2013
 *      Author: raraujo
 */
#include "test.h"
#include "ff.h"
#include "chip.h"
#include "uart.h"
#include "motors.h"
#include "utils.h"
#include "sleep.h"
#include "xprintf.h"

/* The bit of port 0 that the LPCXpresso LPC43xx LED is connected. */
#define LED0_PORT_GPIO  			(0)
#define LED0_PIN_GPIO  				(0)
#define LED0_PORT  					(0)
#define LED0_PIN	 				(0)

/* The queue used by both tasks. */
/*-----------------------------------------------------------*/
static FRESULT test_sd_card() {
	FRESULT res = FR_OK;
	DIR dir;
	char buf[1024];
	int variableName = 5;
	res = f_opendir(&dir, "/");
	if (res != FR_OK) {
		return FR_DISK_ERR;
	}
	xputs("SD OK\n");
	FIL testOutput, testInput;

	if (f_open(&testOutput, "/foo.txt",
	FA_WRITE | FA_CREATE_NEW | FA_OPEN_ALWAYS) == FR_OK) {
		f_printf(&testOutput, "\nbar %d\n", variableName);
		f_close(&testOutput);
	}
	if (f_open(&testInput, "/hello", FA_READ) == FR_OK) {
		f_gets(buf, sizeof(buf), &testInput);
		f_close(&testInput);
	}
	return FR_OK;
}

void manual_test() {
	updateMotorDutyCycle(0, 1);
	test_sd_card();
	Chip_SCU_PinMuxSet(LED0_PORT, LED0_PIN, MD_PLN_FAST | FUNC0);
	// set P0.0 as output
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO);
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO);

	for (;;) {
		timerDelayMs(1000);
		xprintf("Alive\n");
		Chip_GPIO_SetPinToggle(LPC_GPIO_PORT, LED0_PORT_GPIO, LED0_PIN_GPIO);
	}
}
