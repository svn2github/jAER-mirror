/*
 * sleep.h
 *
 *  Created on: Mar 9, 2013
 *      Author: raraujo
 */

#ifndef SLEEP_H_
#define SLEEP_H_

/**
 * Enter Deep Power Down mode
 * The chip will reset after waking up.
 */
extern void enterSleepMode(void);

/**
 * It set the DAC output to 1V which is an input to the waking up circuit
 */
extern void DacInit(void);
#endif /* SLEEP_H_ */
