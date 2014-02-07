#ifndef _INCLUDED_SBRET10FX3_CONFIG_H_
#define _INCLUDED_SBRET10FX3_CONFIG_H_ 1

// Feature configuration
#define PRODUCT_ID 0x1A, 0x84 // Product ID (from Thesycon reserved range)
#define DEVICE_ID  0x00, 0x00

#define STRING_PRODUCT 'D', 0x00, 'A', 0x00, 'V', 0x00, 'i', 0x00, 'S', 0x00, ' ', 0x00, 'F', 0x00, 'X', 0x00, '3', 0x00
#define STRING_PRODUCT_LEN 18

#define FX3_LOG_LEVEL (LOG_DEBUG)

#define MS_FEATURE_DESCRIPTOR_ENABLED (1)

#define GPIF_32BIT_SUPPORT_ENABLED (0)
#define I2C_SUPPORT_ENABLED (1)
#define SPI_SUPPORT_ENABLED (1)
#define GPIO_SUPPORT_ENABLED (1)

#define GPIO_DEBUG_LED_ENABLED (1)
#define GPIO_DEBUG_LED_NUMBER (34)

#define DEVICE_SPECIFIC_INITIALIZATION (1)
#define DEVICE_SPECIFIC_VENDOR_REQUESTS (1)

#define DMA_USBTOFX3_CALLBACK (0)
#define DMA_FX3TOUSB_CALLBACK (0)

#endif /* _INCLUDED_SBRET10FX3_CONFIG_H_ */
