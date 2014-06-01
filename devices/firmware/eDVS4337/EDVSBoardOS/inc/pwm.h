/*
 * pwm.h
 *
 *  Created on: Apr 11, 2014
 *      Author: raraujo
 */

#ifndef PWM_H_
#define PWM_H_
#include <stdint.h>

/**
 * Initializes the PWM subsystem
 */
extern void PWMInit(void);

/**
 * Sets the period for the PWM wave for a channel
 * @param channel Selected channel, should be between 0 and 2
 * @param period Period for the channel
 * @return 0 if there are no errors
 */
extern uint32_t PWMSetPeriod(uint8_t channel, uint32_t period);

/**
 * Sets the duty cycle with a percentage
 * @param channel Selected channel, should be between 0 and 2
 * @param output Selected output, should be between 0 and 1
 * @param dutycycle a duty cycle for the PWM wave, should be between 0 and 100
 * @return 0 if there are no errors
 */
extern uint32_t PWMSetDutyCycle(uint8_t channel, uint8_t output, uint32_t dutycycle);

/**
 * Allow to set the width of the PWM wave in microseconds. This width
 * is for the logic high component.
 * @param channel Selected channel, should be between 0 and 2
 * @param output Selected output, should be between 0 and 1
 * @param width The width of the high pulse in microseconds
 * @return 0 if there are no errors
 */
extern uint32_t PWMSetWidth(uint8_t channel, uint8_t output, uint32_t width);
#endif /* PWM_H_ */
