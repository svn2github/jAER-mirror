#ifndef _INCLUDED_SBRET10FX3_CONFIG_H_
#define _INCLUDED_SBRET10FX3_CONFIG_H_ 1

// Feature configuration
#define PRODUCT_ID 0x1A, 0x84 // Product ID (from Thesycon reserved range)
#define DEVICE_ID  0x00, 0x00

#define STRING_PRODUCT 'S', 0x00, 'B', 0x00, 'R', 0x00, 'E', 0x00, 'T', 0x00, '1', 0x00, '0', 0x00, 'F', 0x00, 'X', 0x00, '3', 0x00
#define STRING_PRODUCT_LEN 20

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
