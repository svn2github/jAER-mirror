/*
 * sensors.h
 *
 *  Created on: Apr 10, 2014
 *      Author: raraujo
 */

#ifndef SENSORS_H_
#define SENSORS_H_
#include <stdint.h>
#include "config.h"

#define MAX_SENSORS							(32)

enum SensorIDs {
	BATTERY = 0,
	ADC0,
	ADC1,
	ADC2,
	ADC3,
	ADC4,
	ADC5,
	RAW_GYRO,
	RAW_ACCEL,
	RAW_COMPASS,
	CAL_GYRO,
	CAL_ACCEL,
	CAL_COMPASS,
	QUARTERNION,
	EULER_ANGLES,
	ROTATION_MATRIX,
	HEADING,
	LINEAR_ACCEL,
	STATUS,
	PWM_SIGNALS,
	MOTOR_CURRENTS,
	EVENT_RATE,
	MOTOR_SENSORS = 28
};

struct sensorTimer {
	uint8_t initialized;
	volatile uint8_t triggered; /* Flag which is set to 1 when counter reaches zero. Must be cleared manually.*/
	int16_t position; /* Position in the enabled sensors queue */
	volatile uint32_t reload; /* Reload value for the counter */
	volatile uint32_t counter; /* Counter which is decremented every ms*/
	void (*init)(void); /* pointer to a possible init function (optional) */
	void (*refresh)(void); /* pointer to the refresh function where the values are printed*/
};

extern volatile uint8_t sensorRefreshRequested; //Flag set to one when a possible refresh of the sensors is required
extern struct sensorTimer sensorsTimers[MAX_SENSORS]; //Sensor array
extern struct sensorTimer * enabledSensors[MAX_SENSORS]; //Enabled sensor queue
extern uint32_t sensorsEnabledCounter; //Counter of the enabled sensors

/**
 * Initializes the sensor array with pointers for their functions
 * and it sets up the Systick interupt which will be used as a timer.
 */
extern void sensorsInit(void);

/**
 * It enables or disables a number of sensors based on the @flag and the @mask used.
 * @param mask bitfield where each bit corresponds to a different sensor
 * @param flag ENABLE or DISABLE
 * @param period the period used for the print out
 */
extern void enableSensors(uint32_t mask, uint8_t flag, uint32_t period);

/**
 * It enabled or disabled a single sensor.
 * @param sensorId Number between 0 and 31
 * @param flag ENABLE or DISABLE
 * @param period the period used for the print out
 */
extern void enableSensor(uint8_t sensorId, uint8_t flag, uint32_t period);

/**
 * Invokes the refresh function of each sensor manually.
 * @param mask bitfield where each bit corresponds to a different sensor
 */
extern void getSensorsOutput(uint32_t mask);

#endif /* SENSORS_H_ */
