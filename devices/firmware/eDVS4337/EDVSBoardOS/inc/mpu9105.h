/*
 * mpu9105.h
 *
 *  Created on: Apr 7, 2014
 *      Author: raraujo
 */

#ifndef MPU9105_H_
#define MPU9105_H_
#include <stdint.h>
#define MPU_ERROR		-1
#define SUCCESS			0
#define MPL_ERROR		1

/**
 * It initializes the MPU and the DMP inside of the IMU
 */
extern int32_t MPU9105Init(void);
/**
 * Checks for the interrupt pin of the IMU and if set
 * it update all sensor data
 */
extern void updateIMUData(void);


/**
 * Disable the IMU
 */
extern void disableIMU(void);

//These functions are required for the IMU driver
/**
 *  @brief      Write to a device register.
 *
 *  @param[in]  slave_addr  Slave address of device.
 *  @param[in]  reg_addr	Slave register to be written to.
 *  @param[in]  length      Number of bytes to write.
 *  @param[out] data        Data to be written to register.
 *
 *  @return     0 if successful.
 */
int i2c_write(uint8_t slave_addr, uint8_t reg_addr, uint8_t length, uint8_t const *data);
/**
 *  @brief      Read from a device.
 *
 *  @param[in]  slave_addr  Slave address of device.
 *  @param[in]  reg_addr	Slave register to be read from.
 *  @param[in]  length      Number of bytes to read.
 *  @param[out] data        Data from register.
 *
 *  @return     0 if successful.
 */
int i2c_read(uint8_t slave_addr, uint8_t reg_addr, uint8_t length, uint8_t *data);
#endif /* MPU9105_H_ */
