/*
 * minirob.h
 *
 *  Created on: 13/04/2014
 *      Author: ruka
 */

#ifndef PUSHBOT_H_
#define PUSHBOT_H_

#include <stdint.h>

struct wheel{
	int32_t wheelStatus; /* State transition count */
	uint32_t errorCount; /* Invalid state transitions counts, should be 0 */
	uint16_t previousState; /*Previous state of the encoder*/
};


extern struct wheel leftWheel, rightWheel; //An instance for each wheel

/**
 * Initializes the MiniRob sensors
 */
extern void MiniRobInit();

/**
 * Checks the two wheels encoders for updates
 */
extern void refreshMiniRobSensors();
#endif /* MINIROB_H_ */
