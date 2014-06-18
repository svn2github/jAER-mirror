/*
 * config.h
 *
 *  Created on: Apr 9, 2014
 *      Author: raraujo
 */

#ifndef CONFIG_H_
#define CONFIG_H_
/**
 * Enable/Disable the IMU sensors.
 * The IMU has a 3 axis accelerometer, gyroscope and compass.
 * It also features a temperature sensor and a internal processor
 * which computes a quarternion based on just the  the gyroscope data or
 * on both the gyroscope and accelerometer data.
 */
#define USE_IMU_DATA 					0

/**
 *	Enable/Disable the wheel sensors used in the Minirob.
 *	The motor velocity control is tied to these sensors.
 */
#define USE_MINIROB						1

/**
 * Enable/Disable the SD card support.
 * SD card requires quite a bit of power (~9mA) so it is disable by default
 * TODO: port to the hardware interface.
 */
#define USE_SDCARD						1

/**
 * Enable/Disable low power mode
 * The M4 core will try to sleep if there nothing to stream
 * and the M0 will wake it up when more events can be sent.
 */
#define LOW_POWER_MODE					0

/**
 * Enable/Disable the extended timestamp
 * The default timestamp (4 bytes) will overflow every 70 minutes.
 * With the extended version (6 bytes) it will overflow every ~9 years.
 */
#define EXTENDED_TIMESTAMP				1


/**
 * It defines the default UART port to be used.
 * Valid values are 0 or 1.
 */
#define UART_PORT_DEFAULT 		(0)

/**
 * The default baud rate at power up or after reset.
 * It can be changed afterwards through a UART command.
 */
#define BAUD_RATE_DEFAULT		(4000000)

/**
 * Current Software versions
 */
#define SOFTWARE_VERSION		"0.2"

#endif /* CONFIG_H_ */
