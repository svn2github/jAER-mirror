#ifndef _INCLUDED_I2C_SUPPORT_H_
#define _INCLUDED_I2C_SUPPORT_H_ 1

// Vendor requests
#define VR_I2C_CONFIG 0xB7
#define VR_I2C_TRANSFER 0xB8

// I2C maximum data rate (in Hertz)
#define I2C_MAX_CLOCK (1 * MEGAHERTZ)

// Macros to increase readability
#define I2C_READ CyTrue
#define I2C_WRITE CyFalse

// Function declarations
CyU3PReturnStatus_t CyFxI2cConfigParse(void);
CyU3PReturnStatus_t CyFxI2cInit(void);
CyU3PReturnStatus_t CyFxI2cTransfer(uint8_t deviceAddress, uint32_t address, uint8_t *data, uint16_t dataLength,
	CyBool_t isRead);
CyBool_t CyFxHandleCustomVR_I2C(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength);

#endif /* _INCLUDED_I2C_SUPPORT_H_ */
