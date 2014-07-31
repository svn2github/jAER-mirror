/*
 * motors.h
 *
 *  Created on: 4 de Dez de 2012
 *      Author: ruka
 */

#ifndef MOTORS_H_
#define MOTORS_H_

#include <stdint.h>
#include <stdbool.h>
#include "config.h"

#define DIRECT_MODE 				(1<<0)
#define VELOCITY_MODE 				(1<<1)
#define DECAY_MODE 					(1<<2)

#define MOTOR0						(0)
#define MOTOR1						(1)

struct motor_status {
	int32_t currentDutycycle; /* Last dutycycle applied to the motor*/
	int32_t requestedWidth; /* Decaying dutycyle */
	volatile uint32_t decayCounter; /* Decaying dutycyle */
	uint32_t controlMode; /* It sets which control mode is applied*/
#if USE_PUSHBOT
	uint16_t velocityPrescaler;
	uint16_t velocityPrescalerCounter;
	int32_t requestedVelocity; /* the requested velocity, ie, position increment*/
	int32_t requestedPosition; /* The expected position*/
	int32_t proportionalGain;
	int32_t integralGain;
	int32_t derivativeGain;
	int32_t lastError;
	int32_t errorIntegral;
	int32_t velocityWindUpGuard;
	int32_t controllerWindUpGuard;
	volatile bool updateRequired; /* Flag set to 1 when the position control should be updated*/
#endif
};

extern struct motor_status motor0; /* Instance for the left motor*/
extern struct motor_status motor1; /* Instance for the right motor*/

/**
 * It initializes the Motor PWM and
 */
extern void initMotors(void);
/**
 * It updates the motor PWM frequency.
 * @param motor Motor ID selected, it should between 0 and 1
 * @param frequency New frequency to be applied
 * @return 0 if there are no errors
 */extern uint32_t updateMotorPWMPeriod(uint32_t motor, uint32_t frequency);

#if USE_PUSHBOT
extern uint32_t updateMotorPID(uint32_t motor, int32_t pGain, int32_t iGain, int32_t dGain);
/**
 * Updates the motor velocity.
 * This sets the motor control mode to VELOCITY_MODE.
 * @param motor Motor ID selected, it should between 0 and 1
 * @param speed the selected speed
 * @return 0 if there are no errors
 */
extern uint32_t updateMotorVelocity(uint32_t motor, int32_t speed);

/**
 * It updates the motor controller, changing the duty cycle
 * @param motor Motor ID selected, it should between 0 and 1
 * @return 0 if there are no errors
 */
extern uint32_t updateMotorController(uint32_t motor);

extern uint32_t updateMotorVelocityDecay(uint32_t motor, int32_t speed);
#endif

/**
 * Updates the motor duty cycle, the selected duty cycle will decay to 0 with in a second.
 * This sets the motor control mode to DIRECT_MODE.
 * @param motor Motor ID selected, it should between 0 and 1
 * @param speed the decaying duty cycle applied to the motor, it should be between -100 and 100.
 * @return 0 if there are no errors
 */
extern uint32_t updateMotorDutyCycleDecay(uint32_t motor, int32_t speed);

extern uint32_t updateMotorWidthUsDecay(uint32_t motor, int32_t widthUs);

/**
 * Updates the motor duty cycle, the selected duty cycle will decay to 0 with in a second.
 * This sets the motor control mode to DIRECT_MODE.
 * @param motor Motor ID selected, it should between 0 and 1
 * @param speed the decaying duty cycle applied to the motor, it should be between -100 and 100.
 * @return 0 if there are no errors
 */
extern uint32_t updateMotorWidthDecay(uint32_t motor, int32_t width);

/**
 * Change the motor control mode.
 * @param motor Motor ID selected, it should between 0 and 1
 * @param mode Selected mode, it should be DIRECT_MODE or VELOCITY_MODE
 * @return 0 if there are no errors
 */
extern uint32_t updateMotorMode(uint32_t motor, uint32_t mode);

extern int32_t getMotorDutycycle(uint32_t motor);
extern int32_t getMotorWidth(uint32_t motor);

/**
 * Updates the motor duty cycle
 * @param motor Motor ID selected, it should between 0 and 1
 * @param duty_cycle the duty cycle applied to the motor, it should be between -100 and 100.
 * @return 0 if there are no errors
 */
extern uint32_t updateMotorDutyCycle(uint32_t motor, int32_t duty_cycle);

extern uint32_t updateMotorWidthUs(uint32_t motor, int32_t widthUs);
/**
 * Updates the motor PWM width
 * @param motor Motor ID selected, it should between 0 and 1
 * @param width The width of the high pulse in microseconds
 * @return 0 if there are no errors
 */
extern uint32_t updateMotorWidth(uint32_t motor, int32_t width);

/**
 *	Enable or disable the motor driver
 * @param enable ENABLE or DISABLE
 */
extern void enableMotorDriver(uint8_t enable);
#endif /* MOTORS_H_ */
