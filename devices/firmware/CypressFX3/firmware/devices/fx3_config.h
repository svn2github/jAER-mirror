#ifndef _INCLUDED_FX3_CONFIG_H_
#define _INCLUDED_FX3_CONFIG_H_ 1

// Feature configuration
#define VENDOR_ID  0x2A, 0x15 // Thesycon Vendor ID
#define PRODUCT_ID 0x1A, 0x84 // Product ID (from Thesycon reserved range)
#define DEVICE_ID  0x00, 0x00

#define STRING_MANUFACTURER 'I', 0x00, 'N', 0x00, 'I', 0x00
#define STRING_MANUFACTURER_LEN 6
#define STRING_PRODUCT 'F', 0x00, 'X', 0x00, '3', 0x00, ' ', 0x00, 'S', 0x00, 'E', 0x00, 'N', 0x00, 'S', 0x00, 'O', 0x00, 'R', 0x00, 'S', 0x00
#define STRING_PRODUCT_LEN 22
#define STRING_SERIALNUMBER '0', 0x00, '0', 0x00, '0', 0x00, '0', 0x00, '0', 0x00, '0', 0x00, '0', 0x00, '0', 0x00
#define STRING_SERIALNUMBER_LEN 16

#define MS_FEATURE_DESCRIPTOR_ENABLED (0)

#define GPIF_32BIT_SUPPORT_ENABLED (0)

/*
 * ********************************************************************************************************************
 */

#define I2C_SUPPORT_ENABLED (0)

typedef struct {
	const uint8_t deviceAddress; // Address in I2C format, meaning the 7 lower bits are the address, the MSB is always 0.
	uint8_t addressLength;
	uint16_t pageSize;
	const uint32_t deviceSize;
	const uint32_t maxFrequency;
} i2cConfig_DeviceSpecific_Type;

extern i2cConfig_DeviceSpecific_Type i2cConfig_DeviceSpecific[];
extern const uint8_t i2cConfig_DeviceSpecific_Length;

/*
 * ********************************************************************************************************************
 */

#define SPI_SUPPORT_ENABLED (0)

typedef struct {
	const uint8_t deviceAddress; // Either 0 meaning default SS line or the actual GPIO Id to be used.
	uint8_t addressLength;
	uint16_t pageSize;
	const uint32_t deviceSize;
	const uint32_t maxFrequency;
	const CyBool_t SSPolarity; // TRUE is active-high, FALSE is active-low.
} spiConfig_DeviceSpecific_Type;

extern spiConfig_DeviceSpecific_Type spiConfig_DeviceSpecific[];
extern const uint8_t spiConfig_DeviceSpecific_Length;

/*
 * ********************************************************************************************************************
 */

#define GPIO_SUPPORT_ENABLED (0)

// Define GPIO configurations here, see documentation and examples in example/.
typedef struct {
	const uint8_t gpioId;
	const uint8_t gpioType;
} gpioConfig_DeviceSpecific_Type;

extern gpioConfig_DeviceSpecific_Type gpioConfig_DeviceSpecific[];
extern const uint8_t gpioConfig_DeviceSpecific_Length;

void CyFxHandleCustomGPIO_DeviceSpecific(uint8_t gpioId);

#define GPIO_DEBUG_LED_ENABLED (0)
#define GPIO_DEBUG_LED_NUMBER (0xFF)

/*
 * ********************************************************************************************************************
 */

#define DEVICE_SPECIFIC_INITIALIZATION (0)

CyU3PReturnStatus_t CyFxHandleCustomINIT_DeviceSpecific(void);

/*
 * ********************************************************************************************************************
 */

// There are no device specific Vendor Requests for the default configuration.
#define DEVICE_SPECIFIC_VENDOR_REQUESTS (0)

CyBool_t CyFxHandleCustomVR_DeviceSpecific(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength);

/*
 * ********************************************************************************************************************
 */

// Select DMA channels. Default is both directions available, input or output only can be selected.
#define DMA_USBTOFX3_ONLY (0)
#define DMA_FX3TOUSB_ONLY (0)

// Use multichannel DMA to configure both available sockets for data transfer in one direction.
#define DMA_USE_MULTICHANNEL (0)

// You can process packets as they pass through the FX3, in either direction. Only enable this if really needed,
// and remember that you then will have to explicitly commit each and every buffer! Be wary of performance!
#define DMA_USBTOFX3_CALLBACK (0)

void CyFxDmaUSBtoFX3Callback(CyU3PDmaChannel *chHandle, CyU3PDmaCbType_t type, CyU3PDmaCBInput_t *input);

// Additional helper functions for USBtoFX3 DMA channel management.
void CyFxDmaUSBtoFX3CallbackInit(CyU3PDmaChannel *chHandle);
void CyFxDmaUSBtoFX3CallbackDestroy(CyU3PDmaChannel *chHandle);

#define DMA_FX3TOUSB_CALLBACK (0)

void CyFxDmaFX3toUSBCallback(CyU3PDmaChannel *chHandle, CyU3PDmaCbType_t type, CyU3PDmaCBInput_t *input);

// Additional helper functions for FX3toUSB DMA channel management.
void CyFxDmaFX3toUSBCallbackInit(CyU3PDmaChannel *chHandle);
void CyFxDmaFX3toUSBCallbackDestroy(CyU3PDmaChannel *chHandle);

#endif /* _INCLUDED_FX3_CONFIG_H_ */
