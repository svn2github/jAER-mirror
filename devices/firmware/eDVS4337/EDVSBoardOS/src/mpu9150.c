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
#include "invensense.h"
#include "invensense_adv.h"
#include "eMPL_outputs.h"
#include "xprintf.h"
#include "sensors.h"
#include "fixedptc.h"
#include "utils.h"
#include "extra_pins.h"
#include <string.h>
#include <stdbool.h>
#if USE_IMU_DATA
/* Starting sampling rate. */
#define DEFAULT_MPU_HZ  (40)

// P3.1 VBAT reset signal
#define MPU_INT_GND_PORT_GPIO  		(5)
#define MPU_INT_GND_PIN_GPIO  		(8)
#define MPU_INT_GND_PORT  			(3)
#define MPU_INT_GND_PIN  			(1)

#define SFSI2C0_CONFIGURE_STANDARD_FAST_MODE_PLUS		(1<<3 | 3<<10)
#define FAST_MODE_BAUD ((uint32_t)400000)
#define FAST_MODE_PLUS_BAUD ((uint32_t)1000000)

static long temperature;/* Temperature sensor output */
static short gyrometer_data[3];/* 3 axis gyrometer data from the IMU*/
static short accelerometer_data[3];/* 3 axis accelerometer data from the IMU*/
static short magnometer_data[3];/* 3 axis compass data from the IMU*/
static long quaternion[4];/* 4d quaternion data from the IMU DMP*/
static unsigned long sensor_timestamp;
static bool mpuEnabled = false;

/* Platform-specific information. Kinda like a boardfile. */
struct platform_data_s {
	signed char orientation[9];
};

unsigned char *mpl_key = (unsigned char*) "eMPL 5.1";

/* The sensors can be mounted onto the board in any orientation. The mounting
 * matrix seen below tells the MPL how to rotate the raw data from the
 * driver(s).
 */
static struct platform_data_s gyro_pdata = { .orientation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 } };

static struct platform_data_s compass_pdata = { .orientation = { 0, 1, 0, 1, 0, 0, 0, 0, -1 } };

#define MAX_NUMBER_STRING_SIZE 32

static void printLongHexData(long *data, int length) {
	for (int i = 0; i < length; ++i) {
		xprintf(" %X", data[i]);
	}
}

static void printShortData(short *data, int length) {
	for (int i = 0; i < length; ++i) {
		xprintf(" %d", data[i]);
	}
}

union ufloat {
	float f;
	long u;
};

/* ---------------------------------------------------------------------------*/
/* Get data from MPL.
 */
static void readFromMpl(uint8_t sensorId) {
	long data[9];
	int8_t accuracy;
	inv_time_t timestamp;

	xprintf("-S%d", sensorId);
	switch (sensorId) {
	case RAW_GYRO: {
		printShortData(gyrometer_data, 3);
		xputc('\n');
		break;
	}
	case RAW_ACCEL: {
		printShortData(accelerometer_data, 3);
		xputc('\n');
		break;
	}
	case RAW_COMPASS: {
		printShortData(magnometer_data, 3);
		xputc('\n');
		break;
	}
	case CAL_GYRO: {
		inv_get_sensor_type_gyro(data, &accuracy, &timestamp);
		printLongHexData(data, 3);
		xprintf(" %d\n", timestamp);
		break;
	}
	case CAL_ACCEL: {
		inv_get_sensor_type_accel(data, &accuracy, &timestamp);
		printLongHexData(data, 3);
		xputc('\n');
		break;
	}
	case CAL_COMPASS: {
		inv_get_sensor_type_compass(data, &accuracy, &timestamp);
		printLongHexData(data, 3);
		xputc('\n');
		break;
	}
	case QUARTERNION: {
		inv_get_sensor_type_quat(data, &accuracy, &timestamp);
		printLongHexData(data, 4);
		xputc('\n');
		break;
	}
	case EULER_ANGLES: {
		inv_get_sensor_type_euler(data, &accuracy, &timestamp);
		printLongHexData(data, 4);
		xputc('\n');
		break;
	}
	case ROTATION_MATRIX: {
		inv_get_sensor_type_rot_mat(data, &accuracy, &timestamp);
		printLongHexData(data, 9);
		xputc('\n');
		break;
	}
	case HEADING: {
		inv_get_sensor_type_heading(data, &accuracy, &timestamp);
		xprintf(" %X\n", data[0]);
		break;
	}
	case LINEAR_ACCEL: {
		float float_data[3] = { 0 };
		inv_get_sensor_type_linear_acceleration(float_data, &accuracy, &timestamp);
		union ufloat converter;
		for (int i = 0; i < 3; ++i) {
			converter.f = float_data[i];
			xprintf(" %X", converter.u);
		}
		xputc('\n');
		break;
	}
	case STATUS: {
		xprintf(" %s %d\n", fixedpt_cstr(temperature, 3, false), sensor_timestamp);
		break;
	}
	}
}

void RawGyroReport() {
	readFromMpl(RAW_GYRO);
}
void RawAccelerometerReport() {
	readFromMpl(RAW_ACCEL);

}
void RawCompassReport() {
	readFromMpl(RAW_COMPASS);
}

void CalGyroReport() {
	readFromMpl(CAL_GYRO);
}

void CalAccelerometerReport() {
	readFromMpl(CAL_ACCEL);
}

void CalCompassReport() {
	readFromMpl(CAL_COMPASS);
}
void IMUStatusReport() {
	readFromMpl(STATUS);
}

void QuaternionReport() {
	readFromMpl(QUARTERNION);
}

void EulerAnglesReport() {
	readFromMpl(EULER_ANGLES);
}

void RotationMatrixReport() {
	readFromMpl(ROTATION_MATRIX);
}

void HeadingReport() {
	readFromMpl(HEADING);
}

void LinearAccelReport() {
	readFromMpl(LINEAR_ACCEL);
}

void updateIMUData() {

	short sensors;
	unsigned char more;
	if (mpuEnabled && Chip_GPIO_ReadPortBit(LPC_GPIO_PORT, MPU_INT_GND_PORT_GPIO, MPU_INT_GND_PIN_GPIO)) {
		if (dmp_read_fifo(gyrometer_data, accelerometer_data, quaternion, &sensor_timestamp, &sensors, &more)) {
			return;
		}
		/* Push the new data to the MPL. */
		inv_build_gyro(gyrometer_data, sensor_timestamp);
		mpu_get_temperature(&temperature, &sensor_timestamp);
		inv_build_temp(temperature, sensor_timestamp);
		long converter[3];
		for (int i = 0; i < 3; i++) {
			converter[i] = accelerometer_data[i];
		}
		inv_build_accel(converter, 0, sensor_timestamp);
		inv_build_quat(quaternion, 0, sensor_timestamp);
		for (int i = 0; i < 3; i++) {
			converter[i] = magnometer_data[i];
		}
		mpu_get_compass_reg(magnometer_data, &sensor_timestamp);
		inv_build_compass((long*) magnometer_data, 0, sensor_timestamp);
		inv_execute_on_data();
	}
}

int32_t MPU9105Init() {
	Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, MPU_INT_GND_PORT_GPIO, MPU_INT_GND_PIN_GPIO);
	Chip_SCU_PinMuxSet(MPU_INT_GND_PORT, MPU_INT_GND_PIN,
	SCU_MODE_INBUFF_EN | SCU_MODE_FUNC4 | SCU_MODE_PULLDOWN);
	mpuEnabled = false;
	Chip_I2C_Init(I2C0);
	Chip_I2C_SetClockRate(I2C0, FAST_MODE_BAUD);
	Chip_I2C_SetMasterEventHandler(I2C0, Chip_I2C_EventHandlerPolling);
	LPC_SCU->SFSI2C0 = SFSI2C0_CONFIGURE_STANDARD_FAST_MODE_PLUS;

	/* Set up gyro.
	 * Every function preceded by mpu_ is a driver function and can be found
	 * in inv_mpu.h.
	 */
	if (mpu_init(NULL)) {
		Chip_I2C_DeInit(I2C0);
		return MPU_ERROR;
	}
	bool mplInitialized = false;
	if (inv_init_mpl() == INV_SUCCESS) {
		mplInitialized = true;

		/* Compute 6-axis and 9-axis quaternions. */
		inv_enable_quaternion();
		inv_enable_9x_sensor_fusion();
		inv_9x_fusion_use_timestamps(1);

		/* Update gyro biases when not in motion.
		 */
		inv_enable_fast_nomot();

		/* Update gyro biases when temperature changes. */
		inv_enable_gyro_tc();

		/* This algorithm updates the accel biases when in motion. A more accurate
		 * bias measurement can be made when running the self-test but this algorithm
		 * can be enabled if the self-test can't be executed in your application.
		 */
		inv_enable_in_use_auto_calibration();
		/* Compass calibration algorithms. */
		inv_enable_vector_compass_cal();
		inv_enable_magnetic_disturbance();

		/* If you need to estimate your heading before the compass is calibrated,
		 * enable this algorithm. It becomes useless after a good figure-eight is
		 * detected, so we'll just leave it out to save memory.
		 *
		 */
		inv_enable_heading_from_gyro();

		/* Allows use of the MPL APIs in read_from_mpl. */
		inv_enable_eMPL_outputs();

		inv_start_mpl();
	}

	/* Get/set hardware configuration. Start gyro. */
	/* Wake up all sensors. */
	mpu_set_sensors(INV_XYZ_GYRO | INV_XYZ_ACCEL | INV_XYZ_COMPASS);
	/* Push both gyro and accel data into the FIFO. */
	mpu_configure_fifo(INV_XYZ_GYRO | INV_XYZ_ACCEL);

	mpu_set_sample_rate(DEFAULT_MPU_HZ);

	/* The compass sampling rate can be less than the gyro/accel sampling rate.
	 * Use this function for proper power management.
	 */
	mpu_set_compass_sample_rate(DEFAULT_MPU_HZ);
	unsigned char accel_fsr = 0;
	unsigned short gyro_rate = 0, gyro_fsr = 0, compass_fsr = 0;
	/* Read back configuration in case it was set improperly. */
	mpu_get_sample_rate(&gyro_rate);
	mpu_get_gyro_fsr(&gyro_fsr);
	mpu_get_accel_fsr(&accel_fsr);
	mpu_get_compass_fsr(&compass_fsr);
	if (mplInitialized) {
		/* Sync driver configuration with MPL. */
		/* Sample rate expected in microseconds. */
		inv_set_gyro_sample_rate(1000000L / gyro_rate);
		inv_set_accel_sample_rate(1000000L / gyro_rate);

		/* The compass rate is independent of the gyro and accel rates. As long as
		 * inv_set_compass_sample_rate is called with the correct value, the 9-axis
		 * fusion algorithm's compass correction gain will work properly.
		 */
		inv_set_compass_sample_rate(1000000L / gyro_rate);

		/* Set chip-to-body orientation matrix.
		 * Set hardware units to dps/g's/degrees scaling factor.
		 */
		inv_set_gyro_orientation_and_scale(inv_orientation_matrix_to_scalar(gyro_pdata.orientation),
				(long) gyro_fsr << 15);
		inv_set_accel_orientation_and_scale(inv_orientation_matrix_to_scalar(gyro_pdata.orientation),
				(long) accel_fsr << 15);
		inv_set_compass_orientation_and_scale(inv_orientation_matrix_to_scalar(compass_pdata.orientation),
				(long) compass_fsr << 15);
	}
	mpu_set_int_level(0);
	mpu_set_int_latched(ENABLE);

	dmp_load_motion_driver_firmware();
	dmp_set_orientation(inv_orientation_matrix_to_scalar(gyro_pdata.orientation));
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
	 *
	 *  DMP sensor fusion works only with gyro at +-2000dps and accel +-2G
	 */
	dmp_enable_feature(DMP_FEATURE_6X_LP_QUAT | DMP_FEATURE_TAP |
	DMP_FEATURE_ANDROID_ORIENT | DMP_FEATURE_SEND_RAW_ACCEL | DMP_FEATURE_SEND_CAL_GYRO |
	DMP_FEATURE_GYRO_CAL);
	dmp_set_fifo_rate(DEFAULT_MPU_HZ);
	mpu_set_dmp_state(ENABLE);
	Chip_I2C_SetClockRate(I2C0, FAST_MODE_PLUS_BAUD);
	mpuEnabled = true;

	//Register the sensors
	sensorsTimers[STATUS].refresh = IMUStatusReport;
	sensorsTimers[RAW_ACCEL].refresh = RawAccelerometerReport;
	sensorsTimers[RAW_GYRO].refresh = RawGyroReport;
	sensorsTimers[RAW_COMPASS].refresh = RawCompassReport;
	if (!mplInitialized) {
		return MPL_ERROR;
	}
	//Otherwise register the calculated sensors
	sensorsTimers[CAL_ACCEL].refresh = CalAccelerometerReport;
	sensorsTimers[CAL_GYRO].refresh = CalGyroReport;
	sensorsTimers[CAL_COMPASS].refresh = CalCompassReport;
	sensorsTimers[QUARTERNION].refresh = QuaternionReport;
	sensorsTimers[EULER_ANGLES].refresh = EulerAnglesReport;
	sensorsTimers[ROTATION_MATRIX].refresh = RotationMatrixReport;
	sensorsTimers[HEADING].refresh = HeadingReport;
	sensorsTimers[LINEAR_ACCEL].refresh = LinearAccelReport;
	return SUCCESS;
}

void disableIMU(void) {

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

/**
 * Stubs for the MPL library
 */

int _MLPrintLog(int priority, const char *tag, const char *fmt, ...) {
	return 0;
}
int _MLPrintVaLog(int priority, const char *tag, const char *fmt, va_list args) {
	return 0;
}
/* Final implementation of actual writing to a character device */
int _MLWriteLog(const char *buf, int buflen) {
	return 0;
}

#endif
