/*
 * sensors.c
 *
 *  Created on: Apr 10, 2014
 *      Author: raraujo
 */

#include "chip.h"
#include "fixedptc.h"
#include "sensors.h"
#include "config.h"
#include "motors.h"
#include "EDVS128_LPC43xx.h"
#include "mpu9105.h"
#include "extra_pins.h"
#include "sdcard.h"
#include "xprintf.h"

#define ADC_ACCURACY						(10)
#define ADC_FREQ							(50000)

#define MOTOR_DRIVER_CURRENT1_SENSOR_PORT	(4)
#define MOTOR_DRIVER_CURRENT1_SENSOR_PIN	(1)
#define MOTOR_DRIVER_CURRENT2_SENSOR_PORT	(4)
#define MOTOR_DRIVER_CURRENT2_SENSOR_PIN	(3)

uint32_t sensorsEnabledCounter;
struct sensorTimer sensorsTimers[MAX_SENSORS];
volatile uint8_t sensorRefreshRequested;

volatile uint32_t lastEventCount = 0;
volatile uint32_t lastByteCount = 0;

static ADC_CLOCK_SETUP_T adcConfig;
struct sensorTimer * enabledSensors[MAX_SENSORS];

STATIC INLINE void printADCRead(uint8_t sensorId, uint8_t channel) {
	uint16_t data;
	if (Chip_ADC_ReadValue(LPC_ADC1, channel, &data) == SUCCESS) {
		xprintf("-S%d %u\n", sensorId, data);
	} else {
		xprintf("-S%d -1\n", sensorId);
	}
}

void batteryInit() {
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC1, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC1, 1, ENABLE);
}
void batteryReport() {
	printADCRead(0, 1);
}

void ADC0Init() {
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC1, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC1, 2, ENABLE);
}
void ADC0Report() {
	printADCRead(1, 2);
}
void ADC1Init() {
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC1, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC1, 3, ENABLE);
}
void ADC1Report() {
	printADCRead(2, 3);
}

void ADC2Init() {
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC1, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC1, 4, ENABLE);
}
void ADC2Report() {
	printADCRead(3, 4);
}
void ADC3Init() {
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC1, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC1, 5, ENABLE);
}
void ADC3Report() {
	printADCRead(4, 5);
}
void ADC4Init() {
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC1, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC1, 6, ENABLE);
}
void ADC4Report() {
	printADCRead(5, 6);
}
void ADC5Init() {
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC1, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC1, 7, ENABLE);
}
void ADC5Report() {
	printADCRead(6, 7);
}

#if USE_IMU_DATA
void GyroReport() {
	xprintf("-S7 %d %d %d\n", gyrometer_data[0], gyrometer_data[1], gyrometer_data[2]);
}
void AccelerometerReport() {
	xprintf("-S8 %d %d %d\n", accelerometer_data[0], accelerometer_data[1], accelerometer_data[2]);
}
void CompassReport() {
	xprintf("-S9 %d %d %d\n", magnometer_data[0], magnometer_data[1], magnometer_data[2]);
}

void TemperatureReport() {
	static char temperaturestr[25];
	fixedpt_str(temperature, temperaturestr, 2);
	xprintf("-S10 %s\n", temperaturestr);
}

void QuaternionReport() {
	xprintf("-S11 %d %d %d %d\n", quaternion[0], quaternion[1], quaternion[2], quaternion[3]);
}

#endif

void MotorCurrentsInit() {
	Chip_SCU_PinMuxSet(MOTOR_DRIVER_CURRENT1_SENSOR_PORT, MOTOR_DRIVER_CURRENT1_SENSOR_PIN, SCU_MODE_INACT | FUNC7);
	Chip_SCU_PinMuxSet(MOTOR_DRIVER_CURRENT2_SENSOR_PORT, MOTOR_DRIVER_CURRENT2_SENSOR_PIN, SCU_MODE_INACT | FUNC7);
	LPC_SCU->ENAIO[0] |= 0x3; //Enable Analog function on these GPIO pins.
	Chip_ADC_SetStartMode(LPC_ADC0, ADC_START_NOW, ADC_TRIGGERMODE_RISING); //This must be before the burst cmd
	Chip_ADC_SetBurstCmd(LPC_ADC0, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC0, 0, ENABLE);
	Chip_ADC_EnableChannel(LPC_ADC0, 1, ENABLE);
}

void MotorPWMReport() {
	xprintf("-S12 %d %d\n", motor0.currentDutycycle, motor1.currentDutycycle);
}

void MotorCurrentsReport() {
	uint16_t motor0, motor1;
	if (Chip_ADC_ReadValue(LPC_ADC0, 0, &motor0) == SUCCESS) {
		if (Chip_ADC_ReadValue(LPC_ADC0, 1, &motor1) == SUCCESS) {
			xprintf("-S13 %u %u\n", motor0, motor1);
		} else {
			xprintf("-S13 %u -1\n", motor0);
		}
	} else {
		if (Chip_ADC_ReadValue(LPC_ADC0, 1, &motor1) == SUCCESS) {
			xprintf("-S13 -1 %u\n", motor1);
		} else {
			xprintf("-S13 -1 -1\n");
		}
	}
}

void EventCountReport() {
	xprintf("-S14 %d\n", lastEventCount);
}

#if USE_SDCARD
void SDCardReport() {
	xprintf("-S15 %d\n", lastByteCount);
}
#endif
void sensorsInit(void) {
	Chip_ADC_Init(LPC_ADC0, &adcConfig);
	Chip_ADC_SetStartMode(LPC_ADC0, ADC_NO_START, ADC_TRIGGERMODE_RISING);
	Chip_ADC_Init(LPC_ADC1, &adcConfig);
	Chip_ADC_SetStartMode(LPC_ADC1, ADC_NO_START, ADC_TRIGGERMODE_RISING);

	sensorRefreshRequested = 0;
	sensorsEnabledCounter = 0;
	for (int i = 0; i < MAX_SENSORS; ++i) {
		enabledSensors[i] = NULL;
		sensorsTimers[i].triggered = 0;
		sensorsTimers[i].reload = 0;
		sensorsTimers[i].counter = 0;
		sensorsTimers[i].position = -1;
		switch (i) {
		case 0:
			sensorsTimers[i].init = batteryInit;
			sensorsTimers[i].refresh = batteryReport;
			break;
		case 1:
			sensorsTimers[i].init = ADC0Init;
			sensorsTimers[i].refresh = ADC0Report;
			break;
		case 2:
			sensorsTimers[i].init = ADC1Init;
			sensorsTimers[i].refresh = ADC1Report;
			break;
		case 3:
			sensorsTimers[i].init = ADC2Init;
			sensorsTimers[i].refresh = ADC2Report;
			break;
		case 4:
			sensorsTimers[i].init = ADC3Init;
			sensorsTimers[i].refresh = ADC3Report;
			break;
		case 5:
			sensorsTimers[i].init = ADC4Init;
			sensorsTimers[i].refresh = ADC4Report;
			break;
		case 6:
			sensorsTimers[i].init = ADC5Init;
			sensorsTimers[i].refresh = ADC5Report;
			break;
#if USE_IMU_DATA
			case 7:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = GyroReport;
			break;
			case 8:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = AccelerometerReport;
			break;
			case 9:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = CompassReport;
			break;
			case 10:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = TemperatureReport;
			break;
			case 11:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = QuaternionReport;
			break;
#endif
		case 12:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = MotorPWMReport;
			break;
		case 13:
			sensorsTimers[i].init = MotorCurrentsInit;
			sensorsTimers[i].refresh = MotorCurrentsReport;
			break;
		case 14:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = EventCountReport;
			break;
#if USE_SDCARD
		case 15:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = SDCardReport;
			break;
#endif
		default:
			sensorsTimers[i].init = NULL;
			sensorsTimers[i].refresh = NULL;
			break;
		}
	}
	uint32_t load = Chip_Clock_GetRate(CLK_MX_MXCORE) / 1000 - 1;
	if (load > 0xFFFFFF) {
		load = 0xFFFFFF;
	}
	SysTick->LOAD = load;
	SysTick->CTRL |= 0x7;	//enable the Systick
}

void enableSensors(uint32_t mask, uint8_t flag, uint32_t period) {
	for (int i = 0; i < MAX_SENSORS; ++i) {
		if (mask & (1 << i)) {
			enableSensor(i, flag, period);
		}
	}
}

void enableSensor(uint8_t sensorId, uint8_t flag, uint32_t period) {
	if (sensorId >= MAX_SENSORS) {
		return;
	}
	if (sensorsTimers[sensorId].refresh == NULL) {
		return;
	}
	SysTick->CTRL &= ~0x1;	//disable the Systick
	if (flag) {
		if (sensorsTimers[sensorId].position == -1) {
			sensorsTimers[sensorId].counter = period;
			sensorsTimers[sensorId].reload = period;
			enabledSensors[sensorsEnabledCounter++] = &sensorsTimers[sensorId];
			sensorsTimers[sensorId].position = sensorsEnabledCounter - 1;
			if (sensorsTimers[sensorId].init != NULL) {
				sensorsTimers[sensorId].init();
			}
		}
	} else {
		if (sensorsTimers[sensorId].position != -1) {
			//if removing the last one, no need to iterate or do anything besides reducing the counter
			if (sensorsTimers[sensorId].position != sensorsEnabledCounter - 1) {
				for (int i = sensorsTimers[sensorId].position; i < sensorsEnabledCounter; ++i) {
					enabledSensors[i] = enabledSensors[i + 1];
				}
			}
			sensorsTimers[sensorId].position = -1;
			sensorsTimers[sensorId].triggered = 0;
			sensorsEnabledCounter--;
		}
	}
	SysTick->CTRL |= 0x1;	//enable the Systick
}

void getSensorsOutput(uint32_t mask) {
	for (int i = 0; i < MAX_SENSORS; ++i) {
		if (mask & (1 << i)) {
			if (sensorsTimers[i].refresh != NULL) {
				sensorsTimers[i].refresh();
			}
		}
	}
}

#if USE_SDCARD
extern void disk_timerproc(void);
#endif

/**
 * The Systick handler is used for a lot more tasks than sensor timing.
 * It also provides a timer for decaying for the motor velocity, motor control
 * and second timer used for the LED blinking and Retina event rate.
 */
void SysTick_Handler(void) {
#if USE_MINIROB
	//static uint16_t motor_velocity = 0;
#endif
	static uint16_t decay_motor_velocity = 0;
	static uint16_t second_timer = 0;
	if (++decay_motor_velocity >= 100) {
		decay_motor_velocity = 0;
		if (motor0.requestedDutycycle != 0 && (motor0.controlMode == DIRECT_MODE)) {
			motor0.requestedDutycycle = (motor0.requestedDutycycle * 90) / 100;
			updateMotorDutyCycle(0, motor0.requestedDutycycle);
		}
		if (motor1.requestedDutycycle != 0 && (motor1.controlMode == DIRECT_MODE)) {
			motor1.requestedDutycycle = (motor1.requestedDutycycle * 90) / 100;
			updateMotorDutyCycle(1, motor1.requestedDutycycle);
		}
	}
#if USE_MINIROB
	//if (++motor_velocity >= 5) {
	//motor_velocity = 0;
	if (motor0.controlMode == VELOCITY_MODE) {
		motor0.updateRequired = 1;
	}
	if (motor1.controlMode == VELOCITY_MODE) {
		motor1.updateRequired = 1;
	}
	//}
#endif
	if (++second_timer >= 1000) {
		second_timer = 0;
		toggleLed0 = 1;
		lastEventCount = events.currentEventRate;
#if USE_SDCARD
		lastByteCount = sdcard.bytesWrittenPerSecond;
#endif
		__DSB(); //Ensure it has been saved
		events.currentEventRate = 0;
#if USE_SDCARD
		sdcard.bytesWrittenPerSecond = 0;
#endif
	}
	sensorRefreshRequested = 1;
	for (int i = 0; i < sensorsEnabledCounter; ++i) {
		if (--enabledSensors[i]->counter == 0) {
			enabledSensors[i]->counter = enabledSensors[i]->reload;
			enabledSensors[i]->triggered = 1;
		}
	}
}

