/*
 * minirob.c
 *
 *  Created on: 13/04/2014
 *      Author: ruka
 */

#include "chip.h"
#include "sensors.h"
#include "pushbot.h"
#include "config.h"
#include "xprintf.h"

#if USE_PUSHBOT

#define RIGHT_SENSOR_A_POSITION		(1)
#define RIGHT_SENSOR_A_PORT			(4)
#define RIGHT_SENSOR_A_PIN			(5)
#define RIGHT_SENSOR_A_PORT_GPIO	(2)
#define RIGHT_SENSOR_A_PIN_GPIO		(5)

#define RIGHT_SENSOR_B_POSITION		(0)
#define RIGHT_SENSOR_B_PORT			(4)
#define RIGHT_SENSOR_B_PIN			(6)
#define RIGHT_SENSOR_B_PORT_GPIO	(2)
#define RIGHT_SENSOR_B_PIN_GPIO		(6)

#define LEFT_SENSOR_A_POSITION		(2)
#define LEFT_SENSOR_A_PORT			(4)
#define LEFT_SENSOR_A_PIN			(2)
#define LEFT_SENSOR_A_PORT_GPIO		(2)
#define LEFT_SENSOR_A_PIN_GPIO		(2)

#define LEFT_SENSOR_B_POSITION		(3)
#define LEFT_SENSOR_B_PORT			(4)
#define LEFT_SENSOR_B_PIN			(8)
#define LEFT_SENSOR_B_PORT_GPIO		(5)
#define LEFT_SENSOR_B_PIN_GPIO		(12)

struct wheel leftWheel, rightWheel;

#if LOW_POWER_MODE
#warning Sensor readings must be wrong!
#endif

void refreshMiniRobSensors() {
	uint32_t currentState;
	if (Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, LEFT_SENSOR_A_PORT_GPIO, LEFT_SENSOR_A_PIN_GPIO)) {
		currentState = Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, LEFT_SENSOR_B_PORT_GPIO, LEFT_SENSOR_B_PIN_GPIO) ? 2 : 3;
	} else {
		currentState = Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, LEFT_SENSOR_B_PORT_GPIO, LEFT_SENSOR_B_PIN_GPIO) ? 1 : 0;
	}
	if (currentState == ((leftWheel.previousState + 1) & 0x3)) {
		leftWheel.wheelStatus++;
	} else if (leftWheel.previousState == ((currentState + 1) & 0x3)) {
		leftWheel.wheelStatus--;
	} else if (currentState != leftWheel.previousState) {
		leftWheel.errorCount++;
	}
	leftWheel.previousState = currentState;

	if (Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, RIGHT_SENSOR_A_PORT_GPIO, RIGHT_SENSOR_A_PIN_GPIO)) {
		currentState = Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, RIGHT_SENSOR_B_PORT_GPIO, RIGHT_SENSOR_B_PIN_GPIO) ? 2 : 3;
	} else {
		currentState = Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, RIGHT_SENSOR_B_PORT_GPIO, RIGHT_SENSOR_B_PIN_GPIO) ? 1 : 0;
	}
	if (currentState == ((rightWheel.previousState + 1) & 0x3)) {
		rightWheel.wheelStatus++;
	} else if (rightWheel.previousState == ((currentState + 1) & 0x3)) {
		rightWheel.wheelStatus--;
	} else if (currentState != rightWheel.previousState) {
		rightWheel.errorCount++;
	}
	rightWheel.previousState = currentState;
}

void reportValues() {
	xprintf("-S%d %d %d\n", MOTOR_SENSORS, leftWheel.wheelStatus, rightWheel.wheelStatus);
}

void MiniRobInit() {
//Register init function
	sensorsTimers[MOTOR_SENSORS].refresh = reportValues;

	leftWheel.wheelStatus = 0;
	leftWheel.errorCount = 0;

	rightWheel.wheelStatus = 0;
	rightWheel.errorCount = 0;

	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, RIGHT_SENSOR_A_PORT_GPIO, RIGHT_SENSOR_A_PIN_GPIO);
	Chip_SCU_PinMuxSet(RIGHT_SENSOR_A_PORT, RIGHT_SENSOR_A_PIN, SCU_MODE_PULLUP | SCU_MODE_INBUFF_EN | FUNC0);

	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, RIGHT_SENSOR_B_PORT_GPIO, RIGHT_SENSOR_B_PIN_GPIO);
	Chip_SCU_PinMuxSet(RIGHT_SENSOR_B_PORT, RIGHT_SENSOR_B_PIN, SCU_MODE_PULLUP | SCU_MODE_INBUFF_EN | FUNC0);

	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, LEFT_SENSOR_A_PORT_GPIO, LEFT_SENSOR_A_PIN_GPIO);
	Chip_SCU_PinMuxSet(LEFT_SENSOR_A_PORT, LEFT_SENSOR_A_PIN, SCU_MODE_PULLUP | SCU_MODE_INBUFF_EN | FUNC0);

	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, LEFT_SENSOR_B_PORT_GPIO, LEFT_SENSOR_B_PIN_GPIO);
	Chip_SCU_PinMuxSet(LEFT_SENSOR_B_PORT, LEFT_SENSOR_B_PIN, SCU_MODE_PULLUP | SCU_MODE_INBUFF_EN | FUNC0);

	if (Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, LEFT_SENSOR_A_PORT_GPIO, LEFT_SENSOR_A_PIN_GPIO)) {
		leftWheel.previousState =
				Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, LEFT_SENSOR_B_PORT_GPIO, LEFT_SENSOR_B_PIN_GPIO) ? 2 : 3;
	} else {
		leftWheel.previousState =
				Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, LEFT_SENSOR_B_PORT_GPIO, LEFT_SENSOR_B_PIN_GPIO) ? 1 : 0;
	}

	if (Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, RIGHT_SENSOR_A_PORT_GPIO, RIGHT_SENSOR_A_PIN_GPIO)) {
		rightWheel.previousState =
				Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, RIGHT_SENSOR_B_PORT_GPIO, RIGHT_SENSOR_B_PIN_GPIO) ? 2 : 3;
	} else {
		rightWheel.previousState =
				Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, RIGHT_SENSOR_B_PORT_GPIO, RIGHT_SENSOR_B_PIN_GPIO) ? 1 : 0;
	}

}

#endif

