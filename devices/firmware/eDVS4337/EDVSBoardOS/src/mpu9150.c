/*
 * mpu9150.c
 *
 *  Created on: Apr 7, 2014
 *      Author: raraujo
 */
#include "chip.h"
#include "config.h"
#include "mpu9105.h"
#include "inv_mpu.h"
#include "inv_mpu_dmp_motion_driver.h"
#include <string.h>
#if USE_IMU_DATA
/* Starting sampling rate. */
#define DEFAULT_MPU_HZ  (40)

// P3.1 VBAT reset signal
#define MPU_INT_GND_PORT_GPIO  		(5)
#define MPU_INT_GND_PIN_GPIO  		(8)
#define MPU_INT_GND_PORT  			(3)
#define MPU_INT_GND_PIN  			(1)

#define SFSI2C0_CONFIGURE_STANDARD_FAST_MODE		(1<<3 | 1<<11)
#define FAST_MODE_BAUD ((uint32_t)400000)

int16_t gyrometer_data[3];
int32_t temperature;
int16_t accelerometer_data[3];
int16_t magnometer_data[3];
int32_t quaternion[4];

/* The sensors can be mounted onto the board in any orientation. The mounting
 * matrix seen below tells the MPL how to rotate the raw data from thei
 * driver(s).
 * TODO: The following matrices refer to the configuration on an internal test
 * board at Invensense. If needed, please modify the matrices to match the
 * chip-to-body matrix for your particular set up.
 */
//static int8_t gyro_orientation[9] = { -1, 0, 0, 0, -1, 0, 0, 0, 1 };
void I2C0_IRQHandler(void) {
	Chip_I2C_MasterStateHandler(I2C0);
}

void updateIMUData() {

	int16_t sensors;
	uint32_t timestamp;
	uint8_t more;
	if (Chip_GPIO_ReadValue(LPC_GPIO_PORT, MPU_INT_GND_PORT_GPIO) & _BIT(MPU_INT_GND_PIN_GPIO)) {
		dmp_read_fifo(gyrometer_data, accelerometer_data, quaternion, &timestamp, &sensors, &more);
		mpu_get_compass_reg(magnometer_data, &timestamp);
		mpu_get_temperature(&temperature, &timestamp);
	}
}

/* These next two functions converts the orientation matrix (see
 * gyro_orientation) to a scalar representation for use by the DMP.
 * NOTE: These functions are borrowed from Invensense's MPL.
 */
static inline unsigned short inv_row_2_scale(const signed char *row) {
	unsigned short b;

	if (row[0] > 0)
		b = 0;
	else if (row[0] < 0)
		b = 4;
	else if (row[1] > 0)
		b = 1;
	else if (row[1] < 0)
		b = 5;
	else if (row[2] > 0)
		b = 2;
	else if (row[2] < 0)
		b = 6;
	else
		b = 7;      // error
	return b;
}

static inline unsigned short inv_orientation_matrix_to_scalar(const signed char *mtx) {
	unsigned short scalar;

	/*
	 XYZ  010_001_000 Identity Matrix
	 XZY  001_010_000
	 YXZ  010_000_001
	 YZX  000_010_001
	 ZXY  001_000_010
	 ZYX  000_001_010
	 */

	scalar = inv_row_2_scale(mtx);
	scalar |= inv_row_2_scale(mtx + 3) << 3;
	scalar |= inv_row_2_scale(mtx + 6) << 6;

	return scalar;
}

void MPU9105Init() {
	Chip_SCU_PinMuxSet(MPU_INT_GND_PORT, MPU_INT_GND_PIN, SCU_MODE_INBUFF_EN | SCU_MODE_FUNC4 | SCU_MODE_PULLUP);
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, MPU_INT_GND_PORT_GPIO, MPU_INT_GND_PIN_GPIO);

	Chip_I2C_Init(I2C0);
	Chip_I2C_SetClockRate(I2C0, FAST_MODE_BAUD);
	Chip_I2C_SetMasterEventHandler(I2C0, Chip_I2C_EventHandler);
	NVIC_EnableIRQ(I2C0_IRQn);
	LPC_SCU->SFSI2C0 = SFSI2C0_CONFIGURE_STANDARD_FAST_MODE;

	/* Set up gyro.
	 * Every function preceded by mpu_ is a driver function and can be found
	 * in inv_mpu.h.
	 */
	if (mpu_init(NULL)) {
		NVIC_DisableIRQ(I2C0_IRQn);
		Chip_I2C_DeInit(I2C0);
		return;
	}

	/* Get/set hardware configuration. Start gyro. */
	/* Wake up all sensors. */
	mpu_set_sensors(INV_XYZ_GYRO | INV_XYZ_ACCEL | INV_XYZ_COMPASS);
	/* Push both gyro and accel data into the FIFO. */
	mpu_configure_fifo(INV_XYZ_GYRO | INV_XYZ_ACCEL | INV_XYZ_COMPASS);
	mpu_set_sample_rate(DEFAULT_MPU_HZ);
	mpu_set_int_level(0);
	mpu_set_int_latched(ENABLE);

	/* To initialize the DMP:
	 * 1. Call dmp_load_motion_driver_firmware(). This pushes the DMP image in
	 *    inv_mpu_dmp_motion_driver.h into the MPU memory.
	 * 2. Push the gyro and accel orientation matrix to the DMP.
	 * 3. Register gesture callbacks. Don't worry, these callbacks won't be
	 *    executed unless the corresponding feature is enabled.
	 * 4. Call dmp_enable_feature(mask) to enable different features.
	 * 5. Call dmp_set_fifo_rate(freq) to select a DMP output rate.
	 * 6. Call any feature-specific control functions.
	 *
	 * To enable the DMP, just call mpu_set_dmp_state(1). This function can
	 * be called repeatedly to enable and disable the DMP at runtime.
	 *
	 * The following is a short summary of the features supported in the DMP
	 * image provided in inv_mpu_dmp_motion_driver.c:
	 * DMP_FEATURE_LP_QUAT: Generate a gyro-only quaternion on the DMP at
	 * 200Hz. Integrating the gyro data at higher rates reduces numerical
	 * errors (compared to integration on the MCU at a lower sampling rate).
	 * DMP_FEATURE_6X_LP_QUAT: Generate a gyro/accel quaternion on the DMP at
	 * 200Hz. Cannot be used in combination with DMP_FEATURE_LP_QUAT.
	 * DMP_FEATURE_TAP: Detect taps along the X, Y, and Z axes.
	 * DMP_FEATURE_ANDROID_ORIENT: Google's screen rotation algorithm. Triggers
	 * an event at the four orientations where the screen should rotate.
	 * DMP_FEATURE_GYRO_CAL: Calibrates the gyro data after eight seconds of
	 * no motion.
	 * DMP_FEATURE_SEND_RAW_ACCEL: Add raw accelerometer data to the FIFO.
	 * DMP_FEATURE_SEND_RAW_GYRO: Add raw gyro data to the FIFO.
	 * DMP_FEATURE_SEND_CAL_GYRO: Add calibrated gyro data to the FIFO. Cannot
	 * be used in combination with DMP_FEATURE_SEND_RAW_GYRO.
	 */
	dmp_load_motion_driver_firmware();
	//dmp_set_orientation(inv_orientation_matrix_to_scalar(gyro_orientation));
	/*
	 * Known Bug -
	 * DMP when enabled will sample sensor data at 200Hz and output to FIFO at the rate
	 * specified in the dmp_set_fifo_rate API. The DMP will then sent an interrupt once
	 * a sample has been put into the FIFO. Therefore if the dmp_set_fifo_rate is at 25Hz
	 * there will be a 25Hz interrupt from the MPU device.
	 *
	 * There is a known issue in which if you do not enable DMP_FEATURE_TAP
	 * then the interrupts will be at 200Hz even if fifo rate
	 * is set at a different rate. To avoid this issue include the DMP_FEATURE_TAP
	 */
	dmp_enable_feature(DMP_FEATURE_6X_LP_QUAT | DMP_FEATURE_TAP | DMP_FEATURE_SEND_RAW_ACCEL | DMP_FEATURE_SEND_RAW_GYRO);
	dmp_set_fifo_rate(DEFAULT_MPU_HZ);
	mpu_set_dmp_state(ENABLE);
}

void disableIMU(void){
	mpu_deinit();
}
int i2c_write(uint8_t slave_addr, uint8_t reg_addr, uint8_t length, uint8_t const *data) {
	uint8_t i2cTxBuffer[20]; //Arbitrary value;
	if (length > sizeof(i2cTxBuffer) - 1) {
		return -1; //This is bad
	}
	i2cTxBuffer[0] = reg_addr;
	memcpy(i2cTxBuffer + 1, data, length);
	if (!Chip_I2C_MasterSend(I2C0, slave_addr, i2cTxBuffer, length + 1)) {
		return -1; //This is bad
	}
	return 0;
}

int i2c_read(uint8_t slave_addr, uint8_t reg_addr, uint8_t length, uint8_t *data) {
	if (!Chip_I2C_MasterCmdRead(I2C0, slave_addr, reg_addr, data, length)) {
		return -1; //This is bad
	}
	return 0;
}

#endif
