#include "motors.h"
#include "chip.h"
#include "extra_pins.h"

//192Mhz / 7680 = 25kHz
#define BASE_PWM_DIVIDER				(7680)

#define MOTOR_DRIVER_ENABLE_PORT 		(6)
#define MOTOR_DRIVER_ENABLE_PIN			(6)
#define MOTOR_DRIVER_ENABLE_PORT_GPIO	(0)
#define MOTOR_DRIVER_ENABLE_PIN_GPIO	(5)

#define MOTOR_DRIVER_FAULT_PORT 		(1)
#define MOTOR_DRIVER_FAULT_PIN			(18)
#define MOTOR_DRIVER_FAULT_PORT_GPIO	(0)
#define MOTOR_DRIVER_FAULT_PIN_GPIO		(13)

#define MOTOR0_PWM_CHANNEL 			(2)
#define MOTOR0_PWM_1_PORT 			(5)
#define MOTOR0_PWM_1_PIN 			(7)
#define MOTOR0_PWM_1_PORT_GPIO		(2)
#define MOTOR0_PWM_1_PIN_GPIO		(7)
#define MOTOR0_PWM_2_PORT 			(5)
#define MOTOR0_PWM_2_PIN			(0)
#define MOTOR0_PWM_2_PORT_GPIO		(2)
#define MOTOR0_PWM_2_PIN_GPIO		(9)

#define MOTOR1_PWM_CHANNEL 			(1)
#define MOTOR1_PWM_1_PORT 			(5)
#define MOTOR1_PWM_1_PIN 			(5)
#define MOTOR1_PWM_1_PORT_GPIO		(2)
#define MOTOR1_PWM_1_PIN_GPIO		(14)
#define MOTOR1_PWM_2_PORT 			(5)
#define MOTOR1_PWM_2_PIN			(6)
#define MOTOR1_PWM_2_PORT_GPIO		(2)
#define MOTOR1_PWM_2_PIN_GPIO		(15)

/** Edge aligned mode for channel in MCPWM */
#define MCPWM_CHANNEL_EDGE_MODE			((uint32_t)(0))
/** Center aligned mode for channel in MCPWM */
#define MCPWM_CHANNEL_CENTER_MODE		((uint32_t)(1))

/** Polarity of the MCOA and MCOB pins: Passive state is LOW, active state is HIGH */
#define MCPWM_CHANNEL_PASSIVE_LO		((uint32_t)(0))
/** Polarity of the MCOA and MCOB pins: Passive state is HIGH, active state is LOW */
#define MCPWM_CHANNEL_PASSIVE_HI		((uint32_t)(1))

/* Output Patent in 3-phase DC mode, the internal MCOA0 signal is routed to any or all of
 * the six output pins under the control of the bits in this register */
#define MCPWM_PATENT_A0		((uint32_t)(1<<0))	/**< MCOA0 tracks internal MCOA0 */
#define MCPWM_PATENT_B0		((uint32_t)(1<<1))	/**< MCOB0 tracks internal MCOA0 */
#define MCPWM_PATENT_A1		((uint32_t)(1<<2))	/**< MCOA1 tracks internal MCOA0 */
#define MCPWM_PATENT_B1		((uint32_t)(1<<3))	/**< MCOB1 tracks internal MCOA0 */
#define MCPWM_PATENT_A2		((uint32_t)(1<<4))	/**< MCOA2 tracks internal MCOA0 */
#define MCPWM_PATENT_B2		((uint32_t)(1<<5))	/**< MCOB2 tracks internal MCOA0 */

/*********************************************************************//**
 * Macro defines for MCPWM Interrupt register
 **********************************************************************/
/* Interrupt registers, these macro definitions below can be applied for these
 * register type:
 * - MCPWM Interrupt Enable read address
 * - MCPWM Interrupt Enable set address
 * - MCPWM Interrupt Enable clear address
 * - MCPWM Interrupt Flags read address
 * - MCPWM Interrupt Flags set address
 * - MCPWM Interrupt Flags clear address
 */
/** Limit interrupt for channel (n) */
#define MCPWM_INT_ILIM(n)	(((n>=0)&&(n<=2)) ? ((uint32_t)(1<<((n*4)+0))) : (0))
/** Match interrupt for channel (n) */
#define MCPWM_INT_IMAT(n)	(((n>=0)&&(n<=2)) ? ((uint32_t)(1<<((n*4)+1))) : (0))
/** Capture interrupt for channel (n) */
#define MCPWM_INT_ICAP(n)	(((n>=0)&&(n<=2)) ? ((uint32_t)(1<<((n*4)+2))) : (0))
/** Fast abort interrupt */
#define MCPWM_INT_ABORT		((uint32_t)(1<<15))

/*********************************************************************//**
 * Macro defines for MCPWM Capture clear address register
 **********************************************************************/
/** Clear the MCCAP (n) register */
#define MCPWM_CAPCLR_CAP(n)		(((n<=2)) ? ((uint32_t)(1<<n)) : (0))

/* Interrupt type in MCPWM */
/** Limit interrupt for channel (0) */
#define MCPWM_INTFLAG_LIM0	MCPWM_INT_ILIM(0)
/** Match interrupt for channel (0) */
#define MCPWM_INTFLAG_MAT0	MCPWM_INT_IMAT(0)
/** Capture interrupt for channel (0) */
#define MCPWM_INTFLAG_CAP0	MCPWM_INT_ICAP(0)

/** Limit interrupt for channel (1) */
#define MCPWM_INTFLAG_LIM1	MCPWM_INT_ILIM(1)
/** Match interrupt for channel (1) */
#define MCPWM_INTFLAG_MAT1	MCPWM_INT_IMAT(1)
/** Capture interrupt for channel (1) */
#define MCPWM_INTFLAG_CAP1	MCPWM_INT_ICAP(1)

/** Limit interrupt for channel (2) */
#define MCPWM_INTFLAG_LIM2	MCPWM_INT_ILIM(2)
/** Match interrupt for channel (2) */
#define MCPWM_INTFLAG_MAT2	MCPWM_INT_IMAT(2)
/** Capture interrupt for channel (2) */
#define MCPWM_INTFLAG_CAP2	MCPWM_INT_ICAP(2)

/** Fast abort interrupt */
#define MCPWM_INTFLAG_ABORT	MCPWM_INT_ABORT

/*********************************************************************//**
 * Macro defines for MCPWM Control register
 **********************************************************************/
/* MCPWM Control register, these macro definitions below can be applied for these
 * register type:
 * - MCPWM Control read address
 * - MCPWM Control set address
 * - MCPWM Control clear address
 */
/**< Stops/starts timer channel n */
#define MCPWM_CON_RUN(n)		((uint32_t)(1<<((n*8)+0)))
/**< Edge/center aligned operation for channel n */
#define MCPWM_CON_CENTER(n)		((uint32_t)(1<<((n*8)+1)))
/**< Select polarity of the MCOAn and MCOBn pin */
#define MCPWM_CON_POLAR(n)		((uint32_t)(1<<((n*8)+2)))
/**< Control the dead-time feature for channel n */
#define MCPWM_CON_DTE(n)		((uint32_t)(1<<((n*8)+3)))
/**< Enable/Disable update of functional register for channel n */
#define MCPWM_CON_DISUP(n)		((uint32_t)(1<<((n*8)+4)))
/**< Control the polarity for all 3 channels */
#define MCPWM_CON_INVBDC		((uint32_t)(1<<29))
/**< 3-phase AC mode select */
#define MCPWM_CON_ACMODE		((uint32_t)(1<<30))
/**< 3-phase DC mode select */
#define MCPWM_CON_DCMODE		(((uint32_t)1<<31))

volatile struct motor_status motor0;
volatile struct motor_status motor1;

static uint32_t motorDriverEnabled;

uint32_t updateMotorPWMPeriod(uint32_t motor, uint32_t period) {
	if (period == 0) {
		return 1;
	}
	uint64_t calculatedLimit = (((uint64_t) period * (uint64_t) Chip_Clock_GetRate(CLK_APB1_MOTOCON)) / (1000000UL));
	if (calculatedLimit & 0xFFFFFFFF) { //Check for overflow
		return 1;
	}
	if (motor == MOTOR0) {
		LPC_MCPWM->LIM[MOTOR0_PWM_CHANNEL] = (uint32_t) calculatedLimit;
	} else if (motor == MOTOR1) {
		LPC_MCPWM->LIM[MOTOR1_PWM_CHANNEL] = (uint32_t) calculatedLimit;
	} else {
		return 1;
	}
	return 0;
}
uint32_t updateMotorMode(uint32_t motor, uint32_t mode) {
	if (motor == MOTOR0) {
		motor0.controlMode = mode;
	} else if (motor == MOTOR1) {
		motor1.controlMode = mode;
	} else {
		return 1;
	}
	return 0;
}

#if USE_MINIROB
#include "minirob.h"

#define CONTROL_LOOP_FREQ				(1000)
#define MAX_SPEED						(92)

uint32_t updateMotorVelocity(uint32_t motor, int32_t speed) {
	if (motor == MOTOR0) {
		motor0.requestedVelocity = speed;
		//leftWheel.wheelStatus = 0;
		if (motor0.controlMode & DIRECT_MODE) {
			motor0.requestedPosition = leftWheel.wheelStatus*20;
		} else {
			//Restrict the error for new reference points
			//motor0.requestedPosition = speed*CONTROL_LOOP_FREQ>>2;
		}
		motor0.controlMode = VELOCITY_MODE;
	} else if (motor == MOTOR1) {
		motor1.requestedVelocity = speed;
		//rightWheel.wheelStatus = 0;
		if (motor1.controlMode & DIRECT_MODE) {
			motor1.requestedPosition = rightWheel.wheelStatus*20;
		} else {
			//Restrict the error for new reference points
			//motor1.requestedPosition = speed*CONTROL_LOOP_FREQ>>2;
		}
		motor1.controlMode = VELOCITY_MODE;
	} else {
		return 1;
	}
	return 0;
}

//TODO: This needs a bit more work to be a proper controller
uint32_t updateMotorController(uint32_t motor) {
	if (motor == MOTOR0) {
		motor0.requestedPosition += motor0.requestedVelocity;
		//TODO: scaling down vabs
		updateMotorWidth(MOTOR0, Kp * ((motor0.requestedPosition / 20) - leftWheel.wheelStatus));
	} else if (motor == MOTOR1) {
		motor1.requestedPosition += motor1.requestedVelocity;
		updateMotorWidth(MOTOR1, Kp * ((motor1.requestedPosition / 20) - rightWheel.wheelStatus));
	} else {
		return 1;
	}
	return 0;
}

uint32_t updateMotorVelocityDecay(uint32_t motor, int32_t speed) {
	if (updateMotorVelocity(motor, speed)) {
		return 1;
	}
	if (motor == MOTOR0) {
		motor0.decayCounter = 10;
	} else {
		motor1.decayCounter = 10;
	}
	return updateMotorMode(motor, DECAY_MODE | VELOCITY_MODE);
}

#endif

uint32_t updateMotorDutyCycleDecay(uint32_t motor, int32_t duty_cycle) {
	if (duty_cycle > 100) {
		duty_cycle = 100;
	} else if (duty_cycle < -100) {
		duty_cycle = -100;
	}
//This cast from uint32_t to int32_t is safe
	if (motor == MOTOR0) {
		int32_t lim = (int32_t) LPC_MCPWM->LIM[MOTOR0_PWM_CHANNEL];
		return updateMotorWidthDecay(MOTOR0, ((duty_cycle * lim) / 100));
	} else if (motor == MOTOR1) {
		int32_t lim = (int32_t) LPC_MCPWM->LIM[MOTOR1_PWM_CHANNEL];
		return updateMotorWidthDecay(MOTOR1, ((duty_cycle * lim) / 100));
	}
	return 1;
}

uint32_t updateMotorWidthDecay(uint32_t motor, int32_t width) {
	int32_t lim = 0;
	if (motor == MOTOR0) {
		lim = (int32_t) LPC_MCPWM->LIM[MOTOR0_PWM_CHANNEL];
	} else {
		lim = (int32_t) LPC_MCPWM->LIM[MOTOR1_PWM_CHANNEL];
	}

	if (width > lim) {
		width = lim;
	} else if (width < -lim) {
		width = -lim;
	}
	if (motor == MOTOR0) {
		motor0.decayCounter = 10;
		motor0.requestedWidth = width;
	} else if (motor == MOTOR1) {
		motor1.decayCounter = 10;
		motor1.requestedWidth = width;
	} else {
		return 1;
	}
	if (updateMotorWidth(motor, width)) {
		return 1;
	}
	return updateMotorMode(motor, DECAY_MODE | DIRECT_MODE);
}

uint32_t updateMotorDutyCycle(uint32_t motor, int32_t duty_cycle) {
	if (duty_cycle > 100) {
		duty_cycle = 100;
	} else if (duty_cycle < -100) {
		duty_cycle = -100;
	}
//This cast from uint32_t to int32_t is safe
	if (motor == MOTOR0) {
		int32_t lim = (int32_t) LPC_MCPWM->LIM[MOTOR0_PWM_CHANNEL];
		return updateMotorWidth(MOTOR0, ((duty_cycle * lim) / 100));
	} else if (motor == MOTOR1) {
		int32_t lim = (int32_t) LPC_MCPWM->LIM[MOTOR1_PWM_CHANNEL];
		return updateMotorWidth(MOTOR1, ((duty_cycle * lim) / 100));
	}
	return 1;
}

uint32_t updateMotorWidth(uint32_t motor, int32_t width) {
	if (motor == MOTOR0) {
		int32_t lim = (int32_t) LPC_MCPWM->LIM[MOTOR0_PWM_CHANNEL];
		if (width > lim) {
			width = lim;
		} else if (width < -lim) {
			width = -lim;
		}
		motor0.currentDutycycle = width;
		if (width == 0) {
			//Brake
			Chip_SCU_PinMuxSet(MOTOR0_PWM_1_PORT, MOTOR0_PWM_1_PIN, MD_PLN_FAST | FUNC0);
			Chip_SCU_PinMuxSet(MOTOR0_PWM_2_PORT, MOTOR0_PWM_2_PIN, MD_PLN_FAST | FUNC0);
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR0_PWM_1_PORT_GPIO, MOTOR0_PWM_1_PIN_GPIO);
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR0_PWM_2_PORT_GPIO, MOTOR0_PWM_2_PIN_GPIO);
		}
		//Moving forward
		else if (width > 0) {
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR0_PWM_1_PORT_GPIO, MOTOR0_PWM_1_PIN_GPIO);
			LPC_MCPWM->MAT[MOTOR0_PWM_CHANNEL] = LPC_MCPWM->LIM[MOTOR0_PWM_CHANNEL] - width;
			Chip_SCU_PinMuxSet(MOTOR0_PWM_1_PORT, MOTOR0_PWM_1_PIN, MD_PLN_FAST | FUNC0);
			Chip_SCU_PinMuxSet(MOTOR0_PWM_2_PORT, MOTOR0_PWM_2_PIN, MD_PLN_FAST | FUNC1);
		} //Moving backwards
		else {
			width = -width;
			//Speed is negative
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR0_PWM_2_PORT_GPIO, MOTOR0_PWM_2_PIN_GPIO);
			LPC_MCPWM->MAT[MOTOR0_PWM_CHANNEL] = width;
			Chip_SCU_PinMuxSet(MOTOR0_PWM_1_PORT, MOTOR0_PWM_1_PIN, MD_PLN_FAST | FUNC1);
			Chip_SCU_PinMuxSet(MOTOR0_PWM_2_PORT, MOTOR0_PWM_2_PIN, MD_PLN_FAST | FUNC0);

		}
	} else if (motor == MOTOR1) {
		int32_t lim = (int32_t) LPC_MCPWM->LIM[MOTOR1_PWM_CHANNEL];
		if (width > lim) {
			width = lim;
		} else if (width < -lim) {
			width = -lim;
		}
		motor1.currentDutycycle = width;
		if (width == 0) {
			//Brake
			Chip_SCU_PinMuxSet(MOTOR1_PWM_1_PORT, MOTOR1_PWM_1_PIN, MD_PLN_FAST | FUNC0);
			Chip_SCU_PinMuxSet(MOTOR1_PWM_2_PORT, MOTOR1_PWM_2_PIN, MD_PLN_FAST | FUNC0);
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR1_PWM_1_PORT_GPIO, MOTOR1_PWM_1_PIN_GPIO);
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR1_PWM_2_PORT_GPIO, MOTOR1_PWM_2_PIN_GPIO);
		}
		//Moving forward
		else if (width > 0) {
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR1_PWM_1_PORT_GPIO, MOTOR1_PWM_1_PIN_GPIO);
			LPC_MCPWM->MAT[MOTOR1_PWM_CHANNEL] = LPC_MCPWM->LIM[MOTOR1_PWM_CHANNEL] - width;
			Chip_SCU_PinMuxSet(MOTOR1_PWM_1_PORT, MOTOR1_PWM_1_PIN, MD_PLN_FAST | FUNC0);
			Chip_SCU_PinMuxSet(MOTOR1_PWM_2_PORT, MOTOR1_PWM_2_PIN, MD_PLN_FAST | FUNC1);
		} //Moving backwards
		else {
			width = -width;
			//Speed is negative
			Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR1_PWM_2_PORT_GPIO, MOTOR1_PWM_2_PIN_GPIO);
			LPC_MCPWM->MAT[MOTOR1_PWM_CHANNEL] = width;
			Chip_SCU_PinMuxSet(MOTOR1_PWM_1_PORT, MOTOR1_PWM_1_PIN, MD_PLN_FAST | FUNC1);
			Chip_SCU_PinMuxSet(MOTOR1_PWM_2_PORT, MOTOR1_PWM_2_PIN, MD_PLN_FAST | FUNC0);
		}
	} else {
		return 1;
	}
	return 0;

}

void enableMotorDriver(uint8_t enable) {
	motorDriverEnabled = enable;
	if (enable) {
		motorDriverEnabled = 1;
		Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR_DRIVER_ENABLE_PORT_GPIO, MOTOR_DRIVER_ENABLE_PIN_GPIO);
	} else {
		motorDriverEnabled = 0;
		Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, MOTOR_DRIVER_ENABLE_PORT_GPIO, MOTOR_DRIVER_ENABLE_PIN_GPIO);
		motor0.controlMode = DIRECT_MODE;
		motor1.controlMode = DIRECT_MODE;
	}
}

void initMotors(void) {
	Chip_Clock_Enable(CLK_APB1_MOTOCON);

	LPC_MCPWM->CAP_CLR = MCPWM_CAPCLR_CAP(0) | MCPWM_CAPCLR_CAP(1) | MCPWM_CAPCLR_CAP(2);

	LPC_MCPWM->INTF_CLR =
			MCPWM_INT_ILIM(
					0) | MCPWM_INT_ILIM(1) | MCPWM_INT_ILIM(2) | MCPWM_INT_IMAT(0) | MCPWM_INT_IMAT(1) | MCPWM_INT_IMAT(2) | MCPWM_INT_ICAP(0) | MCPWM_INT_ICAP(1)
					| MCPWM_INT_ICAP(2);

	LPC_MCPWM->INTEN_CLR =
			MCPWM_INT_ILIM(
					0) | MCPWM_INT_ILIM(1) | MCPWM_INT_ILIM(2) | MCPWM_INT_IMAT(0) | MCPWM_INT_IMAT(1) | MCPWM_INT_IMAT(2) | MCPWM_INT_ICAP(0) | MCPWM_INT_ICAP(1)
					| MCPWM_INT_ICAP(2);
	LPC_MCPWM->CON_CLR = MCPWM_CON_CENTER(MOTOR0_PWM_CHANNEL) | MCPWM_CON_CENTER(MOTOR1_PWM_CHANNEL);
	LPC_MCPWM->CON_CLR = MCPWM_CON_POLAR(MOTOR0_PWM_CHANNEL) | MCPWM_CON_POLAR(MOTOR1_PWM_CHANNEL);
	LPC_MCPWM->CON_CLR = MCPWM_CON_DTE(MOTOR0_PWM_CHANNEL) | MCPWM_CON_DTE(MOTOR1_PWM_CHANNEL);
	LPC_MCPWM->CON_CLR = MCPWM_CON_DISUP(MOTOR0_PWM_CHANNEL) | MCPWM_CON_DISUP(MOTOR1_PWM_CHANNEL);

	LPC_MCPWM->TC[MOTOR0_PWM_CHANNEL] = 0;
	LPC_MCPWM->TC[MOTOR1_PWM_CHANNEL] = 0;
	LPC_MCPWM->LIM[MOTOR0_PWM_CHANNEL] = BASE_PWM_DIVIDER; //192MHz/25KHz = 7680
	LPC_MCPWM->LIM[MOTOR1_PWM_CHANNEL] = BASE_PWM_DIVIDER; //192MHz/25KHz = 7680
	LPC_MCPWM->MAT[MOTOR0_PWM_CHANNEL] = BASE_PWM_DIVIDER;
	LPC_MCPWM->MAT[MOTOR1_PWM_CHANNEL] = BASE_PWM_DIVIDER;

	Chip_SCU_PinMuxSet(MOTOR0_PWM_1_PORT, MOTOR0_PWM_1_PIN, MD_PLN_FAST | FUNC0);
	Chip_SCU_PinMuxSet(MOTOR1_PWM_1_PORT, MOTOR1_PWM_1_PIN, MD_PLN_FAST | FUNC0);
	Chip_SCU_PinMuxSet(MOTOR0_PWM_2_PORT, MOTOR0_PWM_2_PIN, MD_PLN_FAST | FUNC0);
	Chip_SCU_PinMuxSet(MOTOR1_PWM_2_PORT, MOTOR1_PWM_2_PIN, MD_PLN_FAST | FUNC0);
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR0_PWM_1_PORT_GPIO, MOTOR0_PWM_1_PIN_GPIO);
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR1_PWM_1_PORT_GPIO, MOTOR1_PWM_1_PIN_GPIO);
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR0_PWM_2_PORT_GPIO, MOTOR0_PWM_2_PIN_GPIO);
	Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, MOTOR1_PWM_2_PORT_GPIO, MOTOR1_PWM_2_PIN_GPIO);
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, MOTOR0_PWM_1_PORT_GPIO, MOTOR0_PWM_1_PIN_GPIO);
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, MOTOR1_PWM_1_PORT_GPIO, MOTOR1_PWM_1_PIN_GPIO);
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, MOTOR0_PWM_2_PORT_GPIO, MOTOR0_PWM_2_PIN_GPIO);
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, MOTOR1_PWM_2_PORT_GPIO, MOTOR1_PWM_2_PIN_GPIO);

	motorDriverEnabled = 0;
	Chip_SCU_PinMuxSet(MOTOR_DRIVER_ENABLE_PORT, MOTOR_DRIVER_ENABLE_PIN, MD_PLN_FAST | FUNC0);
	Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, MOTOR_DRIVER_ENABLE_PORT_GPIO, MOTOR_DRIVER_ENABLE_PIN_GPIO);
	Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, MOTOR_DRIVER_ENABLE_PORT_GPIO, MOTOR_DRIVER_ENABLE_PIN_GPIO);

	Chip_SCU_PinMuxSet(MOTOR_DRIVER_FAULT_PORT, MOTOR_DRIVER_FAULT_PIN, MD_BUK | MD_EZI | FUNC0);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, MOTOR_DRIVER_FAULT_PORT_GPIO, MOTOR_DRIVER_FAULT_PIN_GPIO);

	LPC_MCPWM->CON_SET = MCPWM_CON_RUN(MOTOR1_PWM_CHANNEL) | MCPWM_CON_RUN(MOTOR0_PWM_CHANNEL);
//Initialize the control structure
	motor0.currentDutycycle = 0;
	motor0.controlMode = DIRECT_MODE;
	motor0.requestedWidth = 0;

	motor1.currentDutycycle = 0;
	motor1.controlMode = DIRECT_MODE;
	motor1.requestedWidth = 0;
#if USE_MINIROB
	motor0.requestedVelocity = 0;
	motor0.requestedPosition = 0;
	motor0.updateRequired = 0;

	motor1.requestedVelocity = 0;
	motor1.requestedPosition = 0;
	motor1.updateRequired = 0;
#endif
}
