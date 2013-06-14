#ifndef _INCLUDED_SRC_SINK_CONFIG_H_
#define _INCLUDED_SRC_SINK_CONFIG_H_ 1

// Feature configuration
#define STRING_PRODUCT 'F', 0x00, 'X', 0x00, '3', 0x00, ' ', 0x00, 'S', 0x00, 'R', 0x00, 'C', 0x00, '_', 0x00, 'S', 0x00, 'I', 0x00, 'N', 0x00, 'K', 0x00
#define STRING_PRODUCT_LEN 24

#define FX3_LOG_LEVEL (LOG_CRITICAL)

#define FX3_FIFO_DATA_PRODUCER_FX3_SOCKET (CY_U3P_CPU_SOCKET_PROD)
#define FX3_FIFO_DATA_DMA_FX3TOUSB_CB_EVENT (CY_U3P_DMA_CB_CONS_EVENT)

#define FX3_FIFO_DATA_CONSUMER_FX3_SOCKET (CY_U3P_CPU_SOCKET_CONS)
#define FX3_FIFO_DATA_DMA_USBTOFX3_CB_EVENT (CY_U3P_DMA_CB_PROD_EVENT)

#define GPIF_32BIT_SUPPORT_ENABLED (0)
#define I2C_SUPPORT_ENABLED (0)
#define SPI_SUPPORT_ENABLED (1)
#define GPIO_SUPPORT_ENABLED (0)

#define DMA_USBTOFX3_CALLBACK (1)
#define DMA_FX3TOUSB_CALLBACK (1)

#endif /* _INCLUDED_SRC_SINK_CONFIG_H_ */
