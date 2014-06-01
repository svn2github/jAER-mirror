#ifndef _INCLUDED_GPIO_SUPPORT_H_
#define _INCLUDED_GPIO_SUPPORT_H_ 1

// Vendor requests
#define VR_GPIO_GET 0xB5
#define VR_GPIO_SET 0xB6

// Maximum number of GPIOs that can exist (0-57 on an FX3 => 58)
#define GPIO_MAX_IDENTIFIER (58)

// Function declarations
CyBool_t CyFxGpioVerifyId(const uint8_t gpioId);
CyU3PReturnStatus_t CyFxGpioConfigParse(uint32_t *gpioSimpleEn0, uint32_t *gpioSimpleEn1);
CyU3PReturnStatus_t CyFxGpioInit(void);
void CyFxGpioEventHandlerLoop(void);
void CyFxGpioTurnOff(uint8_t gpioId);
void CyFxGpioTurnOn(uint8_t gpioId);
CyBool_t CyFxGpioGet(uint8_t gpioId);
CyBool_t CyFxHandleCustomVR_GPIO(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength);

#endif /* _INCLUDED_GPIO_SUPPORT_H_ */
