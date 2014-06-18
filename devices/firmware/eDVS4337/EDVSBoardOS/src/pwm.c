/*
 * pwm.c
 *
 *  Created on: Apr 11, 2014
 *      Author: raraujo
 */
#include "pwm.h"
#include "EDVS128_LPC43xx.h"
#include "chip.h"

#define MAX_OUTPUTS 2

#define CHANNEL_A_TIMER   		LPC_TIMER3
#define CHANNEL_A_TIMER_INDEX	(0)
#define CHANNEL_A_0_PORT		(2)
#define CHANNEL_A_0_PIN			(3)
#define CHANNEL_A_1_PORT		(2)
#define CHANNEL_A_1_PIN			(4)
#define CHANNEL_A_0_PORT_GPIO	(5)
#define CHANNEL_A_0_PIN_GPIO	(3)
#define CHANNEL_A_1_PORT_GPIO	(5)
#define CHANNEL_A_1_PIN_GPIO	(4)

#define CHANNEL_B_TIMER   		LPC_TIMER2
#define CHANNEL_B_TIMER_INDEX	(1)
#define CHANNEL_B_0_PORT		(6)
#define CHANNEL_B_0_PIN			(7)
#define CHANNEL_B_1_PORT		(6)
#define CHANNEL_B_1_PIN			(8)
#define CHANNEL_B_0_PORT_GPIO	(5)
#define CHANNEL_B_0_PIN_GPIO	(15)
#define CHANNEL_B_1_PORT_GPIO	(5)
#define CHANNEL_B_1_PIN_GPIO	(16)

#define CHANNEL_C_TIMER   		LPC_TIMER0
#define CHANNEL_C_TIMER_INDEX	(2)
#define CHANNEL_C_0_PORT		(2)
#define CHANNEL_C_0_PIN			(8)
#define CHANNEL_C_1_PORT		(2)
#define CHANNEL_C_1_PIN			(9)
#define CHANNEL_C_0_PORT_GPIO	(5)
#define CHANNEL_C_0_PIN_GPIO	(7)
#define CHANNEL_C_1_PORT_GPIO	(1)
#define CHANNEL_C_1_PIN_GPIO	(10)

struct hal {
	LPC_TIMER_T * timer; /* Pointer to the timer registers*/
	uint32_t witdh[2]; /*Current width apply to each output of the channel*/
	uint8_t port[2];/* ports used in the outputs*/
	uint8_t pin[2];/* pins used in the outputs*/
	uint8_t portGpio[2];/* gpio ports used in the outputs*/
	uint8_t pinGpio[2];/* gpio pins used in the outputs*/
	uint16_t gpioMode[2];/* pins SCU mode for the gpio mode, used in 0 and 100% */
	uint16_t timerMode[2]; /* pins SCU mode for the timer mode */
	uint16_t timerChannel[2]; /* map output[0-1] to the timer match channel */
	uint16_t enabled[2];/*1 if the output is enable*/
	uint32_t period; /* base period of the timer in microseconds*/
} halTimers[3]; /*one instance for the each of the channels*/

void PWMInit(void) {
	halTimers[CHANNEL_A_TIMER_INDEX].timer = CHANNEL_A_TIMER;
	halTimers[CHANNEL_A_TIMER_INDEX].port[0] = CHANNEL_A_0_PORT;
	halTimers[CHANNEL_A_TIMER_INDEX].port[1] = CHANNEL_A_1_PORT;
	halTimers[CHANNEL_A_TIMER_INDEX].pin[0] = CHANNEL_A_0_PIN;
	halTimers[CHANNEL_A_TIMER_INDEX].pin[1] = CHANNEL_A_1_PIN;
	halTimers[CHANNEL_A_TIMER_INDEX].portGpio[0] = CHANNEL_A_0_PORT_GPIO;
	halTimers[CHANNEL_A_TIMER_INDEX].portGpio[1] = CHANNEL_A_1_PORT_GPIO;
	halTimers[CHANNEL_A_TIMER_INDEX].pinGpio[0] = CHANNEL_A_0_PIN_GPIO;
	halTimers[CHANNEL_A_TIMER_INDEX].pinGpio[1] = CHANNEL_A_1_PIN_GPIO;
	halTimers[CHANNEL_A_TIMER_INDEX].timerMode[0] = MD_PUP | FUNC6;
	halTimers[CHANNEL_A_TIMER_INDEX].timerMode[1] = MD_PUP | FUNC6;
	halTimers[CHANNEL_A_TIMER_INDEX].gpioMode[0] = MD_PUP | FUNC4;
	halTimers[CHANNEL_A_TIMER_INDEX].gpioMode[1] = MD_PUP | FUNC4;
	halTimers[CHANNEL_A_TIMER_INDEX].timerChannel[0] = 0;
	halTimers[CHANNEL_A_TIMER_INDEX].timerChannel[1] = 1;
	halTimers[CHANNEL_A_TIMER_INDEX].witdh[0] = 0;
	halTimers[CHANNEL_A_TIMER_INDEX].witdh[1] = 0;
	halTimers[CHANNEL_A_TIMER_INDEX].enabled[0] = 0;
	halTimers[CHANNEL_A_TIMER_INDEX].enabled[1] = 0;
	halTimers[CHANNEL_A_TIMER_INDEX].period = 0;
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, CHANNEL_A_0_PORT_GPIO, CHANNEL_A_0_PIN_GPIO);
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, CHANNEL_A_1_PORT_GPIO, CHANNEL_A_1_PIN_GPIO);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, CHANNEL_A_0_PORT_GPIO, CHANNEL_A_0_PIN_GPIO);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, CHANNEL_A_1_PORT_GPIO, CHANNEL_A_1_PIN_GPIO);
	Chip_SCU_PinMuxSet(CHANNEL_A_0_PORT, CHANNEL_A_0_PIN, halTimers[CHANNEL_A_TIMER_INDEX].gpioMode[0]);
	Chip_SCU_PinMuxSet(CHANNEL_A_1_PORT, CHANNEL_A_1_PIN, halTimers[CHANNEL_A_TIMER_INDEX].gpioMode[1]);

	halTimers[CHANNEL_B_TIMER_INDEX].timer = CHANNEL_B_TIMER;
	halTimers[CHANNEL_B_TIMER_INDEX].port[0] = CHANNEL_B_0_PORT;
	halTimers[CHANNEL_B_TIMER_INDEX].port[1] = CHANNEL_B_1_PORT;
	halTimers[CHANNEL_B_TIMER_INDEX].pin[0] = CHANNEL_B_0_PIN;
	halTimers[CHANNEL_B_TIMER_INDEX].pin[1] = CHANNEL_B_1_PIN;
	halTimers[CHANNEL_B_TIMER_INDEX].portGpio[0] = CHANNEL_B_0_PORT_GPIO;
	halTimers[CHANNEL_B_TIMER_INDEX].portGpio[1] = CHANNEL_B_1_PORT_GPIO;
	halTimers[CHANNEL_B_TIMER_INDEX].pinGpio[0] = CHANNEL_B_0_PIN_GPIO;
	halTimers[CHANNEL_B_TIMER_INDEX].pinGpio[1] = CHANNEL_B_1_PIN_GPIO;
	halTimers[CHANNEL_B_TIMER_INDEX].timerMode[0] = MD_PUP | FUNC5;
	halTimers[CHANNEL_B_TIMER_INDEX].timerMode[1] = MD_PUP | FUNC5;
	halTimers[CHANNEL_B_TIMER_INDEX].gpioMode[0] = MD_PUP | FUNC4;
	halTimers[CHANNEL_B_TIMER_INDEX].gpioMode[1] = MD_PUP | FUNC4;
	halTimers[CHANNEL_B_TIMER_INDEX].timerChannel[0] = 0;
	halTimers[CHANNEL_B_TIMER_INDEX].timerChannel[1] = 1;
	halTimers[CHANNEL_B_TIMER_INDEX].witdh[0] = 0;
	halTimers[CHANNEL_B_TIMER_INDEX].witdh[1] = 0;
	halTimers[CHANNEL_B_TIMER_INDEX].enabled[0] = 0;
	halTimers[CHANNEL_B_TIMER_INDEX].enabled[1] = 0;
	halTimers[CHANNEL_B_TIMER_INDEX].period = 0;
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, CHANNEL_B_0_PORT_GPIO, CHANNEL_B_0_PIN_GPIO);
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, CHANNEL_B_1_PORT_GPIO, CHANNEL_B_1_PIN_GPIO);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, CHANNEL_B_0_PORT_GPIO, CHANNEL_B_0_PIN_GPIO);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, CHANNEL_B_1_PORT_GPIO, CHANNEL_B_1_PIN_GPIO);
	Chip_SCU_PinMuxSet(CHANNEL_B_0_PORT, CHANNEL_B_0_PIN, halTimers[CHANNEL_B_TIMER_INDEX].gpioMode[0]);
	Chip_SCU_PinMuxSet(CHANNEL_B_1_PORT, CHANNEL_B_1_PIN, halTimers[CHANNEL_B_TIMER_INDEX].gpioMode[1]);

	halTimers[CHANNEL_C_TIMER_INDEX].timer = CHANNEL_C_TIMER;
	halTimers[CHANNEL_C_TIMER_INDEX].port[0] = CHANNEL_C_0_PORT;
	halTimers[CHANNEL_C_TIMER_INDEX].port[1] = CHANNEL_C_1_PORT;
	halTimers[CHANNEL_C_TIMER_INDEX].pin[0] = CHANNEL_C_0_PIN;
	halTimers[CHANNEL_C_TIMER_INDEX].pin[1] = CHANNEL_C_1_PIN;
	halTimers[CHANNEL_C_TIMER_INDEX].portGpio[0] = CHANNEL_C_0_PORT_GPIO;
	halTimers[CHANNEL_C_TIMER_INDEX].portGpio[1] = CHANNEL_C_1_PORT_GPIO;
	halTimers[CHANNEL_C_TIMER_INDEX].pinGpio[0] = CHANNEL_C_0_PIN_GPIO;
	halTimers[CHANNEL_C_TIMER_INDEX].pinGpio[1] = CHANNEL_C_1_PIN_GPIO;
	halTimers[CHANNEL_C_TIMER_INDEX].timerMode[0] = MD_PUP | FUNC1;
	halTimers[CHANNEL_C_TIMER_INDEX].timerMode[1] = MD_PUP | FUNC1;
	halTimers[CHANNEL_C_TIMER_INDEX].gpioMode[0] = MD_PUP | FUNC4;
	halTimers[CHANNEL_C_TIMER_INDEX].gpioMode[1] = MD_PUP | FUNC0;
	halTimers[CHANNEL_C_TIMER_INDEX].timerChannel[0] = 0;
	halTimers[CHANNEL_C_TIMER_INDEX].timerChannel[1] = 3; // Special mapping for the Channel C_1
	halTimers[CHANNEL_C_TIMER_INDEX].witdh[0] = 0;
	halTimers[CHANNEL_C_TIMER_INDEX].witdh[1] = 0;
	halTimers[CHANNEL_C_TIMER_INDEX].enabled[0] = 0;
	halTimers[CHANNEL_C_TIMER_INDEX].enabled[1] = 0;
	halTimers[CHANNEL_C_TIMER_INDEX].period = 0;
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, CHANNEL_C_0_PORT_GPIO, CHANNEL_C_0_PIN_GPIO);
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, CHANNEL_C_1_PORT_GPIO, CHANNEL_C_1_PIN_GPIO);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, CHANNEL_C_0_PORT_GPIO, CHANNEL_C_0_PIN_GPIO);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, CHANNEL_C_1_PORT_GPIO, CHANNEL_C_1_PIN_GPIO);
	Chip_SCU_PinMuxSet(CHANNEL_C_0_PORT, CHANNEL_C_0_PIN, halTimers[CHANNEL_C_TIMER_INDEX].gpioMode[0]);
	Chip_SCU_PinMuxSet(CHANNEL_C_1_PORT, CHANNEL_C_1_PIN, halTimers[CHANNEL_C_TIMER_INDEX].gpioMode[1]);
	for (int i = 0; i < 3; ++i) {
		for (int j = 0; j < 2; ++j) {
			Chip_TIMER_ResetOnMatchDisable(halTimers[i].timer, halTimers[i].timerChannel[j]);
			Chip_TIMER_StopOnMatchDisable(halTimers[i].timer, halTimers[i].timerChannel[j]);
			Chip_TIMER_MatchDisableInt(halTimers[i].timer, halTimers[i].timerChannel[j]);
			Chip_TIMER_ExtMatchControlSet(halTimers[i].timer, 1, TIMER_EXTMATCH_CLEAR, halTimers[i].timerChannel[j]);
		}
	}

}

uint32_t PWMSetPeriod(uint8_t channel, uint32_t period) {
	if (channel > CHANNEL_C_TIMER_INDEX) {
		return 1;
	}
	if (eDVSMode != EDVS_MODE_INTERNAL && channel == 0) {
		return 1; // channel 0 taken for master/slave mode
	}
	LPC_TIMER_T * timer = halTimers[channel].timer;
	halTimers[channel].period = period;
	/**
	 * If the period equal 0, the timer is disable and its outputs are set as GPIO and driven low.
	 */
	if (period == 0) {
		Chip_TIMER_DeInit(timer); //Stop the timer
		Chip_TIMER_SetMatch(timer, 2, 0);
		halTimers[channel].enabled[0] = DISABLE;
		halTimers[channel].enabled[1] = DISABLE;
		Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, halTimers[channel].portGpio[0], halTimers[channel].pinGpio[0]);
		Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, halTimers[channel].portGpio[1], halTimers[channel].pinGpio[1]);
		Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, halTimers[channel].portGpio[0], halTimers[channel].pinGpio[0]);
		Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, halTimers[channel].portGpio[1], halTimers[channel].pinGpio[1]);
		Chip_SCU_PinMuxSet(halTimers[channel].port[0], halTimers[channel].pin[0], halTimers[channel].gpioMode[0]);
		Chip_SCU_PinMuxSet(halTimers[channel].port[1], halTimers[channel].pin[1], halTimers[channel].gpioMode[1]);
	} else {
		/**
		 * The channel match 2 is used as the controller of the base frequency.
		 * When there is a match on this channel, the timer is reset and the external match bit
		 * is set to 1.
		 * The M0 core is looking for this change and it sets the output of the channels to high.
		 */
		Chip_TIMER_Init(timer);
		Chip_TIMER_Disable(timer);
		Chip_TIMER_Reset(timer);
		/**
		 * The Main clock is running at 192Mhz so set the Prescaler in order to have
		 * a 1 Mhz timer. Timer_CLK = Main_CLK/ (PR+1)
		 */
		Chip_TIMER_PrescaleSet(timer, 191);
		Chip_TIMER_ResetOnMatchEnable(timer, 2);
		Chip_TIMER_StopOnMatchDisable(timer, 2);
		Chip_TIMER_MatchDisableInt(timer, 2);
		Chip_TIMER_SetMatch(timer, 2, period);
		//Reconfigure match channels!
		if (halTimers[channel].enabled[0]) {
			PWMSetWidth(channel, 0, halTimers[channel].witdh[0]);
		}
		if (halTimers[channel].enabled[1]) {
			PWMSetWidth(channel, 1, halTimers[channel].witdh[1]);
		}
		Chip_TIMER_ExtMatchControlSet(timer, 0, TIMER_EXTMATCH_SET, 2);
		// Clear interrupt pending
		timer->IR = 0xFFFFFFFF;
		Chip_TIMER_Enable(timer);
	}
	return 0;
}

uint32_t PWMSetDutyCycle(uint8_t channel, uint8_t output, uint32_t dutycycle) {
	if (output >= MAX_OUTPUTS || channel > CHANNEL_C_TIMER_INDEX) {
		return 1;
	}
	if (eDVSMode != EDVS_MODE_INTERNAL && channel == 0) {
		return 1; // channel 0 taken for master/slave mode
	}
	if (dutycycle > 100) {
		dutycycle = 100;
	}
	return PWMSetWidth(channel, output, (dutycycle * halTimers[channel].period) / 100);
}

uint32_t PWMSetWidth(uint8_t channel, uint8_t output, uint32_t width) {
	if (output >= MAX_OUTPUTS || channel > CHANNEL_C_TIMER_INDEX) {
		return 1;
	}
	if (eDVSMode != EDVS_MODE_INTERNAL && channel == 0) {
		return 1; // channel 0 taken for master/slave mode
	}
	LPC_TIMER_T * timer = halTimers[channel].timer;
	halTimers[channel].witdh[output] = width;
	halTimers[channel].enabled[output] = ENABLE;
	/**
	 * Since we have to use the Core M0 to overcome hardware limitations
	 * when the width is 0 or bigger than the period of the wave,
	 * the output is set as GPIO and driven accordingly.
	 */
	if (width == 0) { //Set GPIO Low
		Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, halTimers[channel].portGpio[output],
				halTimers[channel].pinGpio[output]);
		Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, halTimers[channel].portGpio[output], halTimers[channel].pinGpio[output]);
		Chip_SCU_PinMuxSet(halTimers[channel].port[output], halTimers[channel].pin[output],
				halTimers[channel].gpioMode[output]);
	} else if (width >= timer->MR[2]) { //Set GPIO High
		Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, halTimers[channel].portGpio[output],
				halTimers[channel].pinGpio[output]);
		Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, halTimers[channel].portGpio[output], halTimers[channel].pinGpio[output]);
		Chip_SCU_PinMuxSet(halTimers[channel].port[output], halTimers[channel].pin[output],
				halTimers[channel].gpioMode[output]);
	} else {
		Chip_TIMER_SetMatch(timer, halTimers[channel].timerChannel[output], width);
		Chip_SCU_PinMuxSet(halTimers[channel].port[output], halTimers[channel].pin[output],
				halTimers[channel].timerMode[output]);
	}
	return 0;
}
