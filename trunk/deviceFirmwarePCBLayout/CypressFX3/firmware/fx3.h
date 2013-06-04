#ifndef _INCLUDED_FX3_H_
#define _INCLUDED_FX3_H_ 1

#include "cyu3types.h"
#include "cyu3system.h"
#include "cyu3os.h"
#include "cyu3error.h"
#include "cyu3usbconst.h"
#include "cyu3usb.h"

// Switch to turn off USB 3.0 enumeration, temporary workaround for hardware bug in Dev-Kit boards, see
// http://www.cypress.com/?app=forum&id=167&rID=70377 for more details.
#define FX3_USB3_ENUMERATION (CyTrue)

// Default log level
#define FX3_LOG_LEVEL (LOG_DEBUG)

// DMA settings
#define FX3_SLFIFO_DMA_BURST_LEN           (4) /* Slave FIFO end-point burst size (USB 3.0 only!) */
#define FX3_SLFIFO_DMA_BUF_COUNT_FIFOTOUSB (4) /* Slave FIFO to USB channel buffer count */
#define FX3_SLFIFO_DMA_BUF_COUNT_USBTOFIFO (4) /* USB to Slave FIFO channel buffer count */

// Thread settings
#define FX3_APPLICATION_THREAD_STACK    (0x0400) /* Main application thread stack size */
#define FX3_APPLICATION_THREAD_PRIORITY (8)      /* Main application thread priority */
#define FX3_HEARTBEAT_THREAD_STACK      (0x0200) /* Heartbeat thread stack size */
#define FX3_HEARTBEAT_THREAD_PRIORITY   (10)     /* Heartbeat thread priority */

// Endpoint maximum transfer sizes
#define FX3_MAX_TRANSFER_SIZE_CONTROL (4 * KILOBYTE) /* 4KB is the default size for control transfers */
#define FX3_MAX_TRANSFER_SIZE_STATUS (64) /* fixed at 64 bytes to be compatible with all USB versions */

// Endpoint addresses
#define FX3_EP_ADDR_STATUS_IN     (0x81) /* EP 1 IN (STATUS) */
#define FX3_EP_ADDR_FIFO_DATA_IN  (0x82) /* EP 2 IN (FIFO_DATA) */
#define FX3_EP_ADDR_FIFO_DATA_OUT (0x02) /* EP 2 OUT (FIFO_DATA) */

// Socket mappings
#define FX3_STATUS_PRODUCER_PPORT_SOCKET (CY_U3P_CPU_SOCKET_PROD)
#define FX3_STATUS_CONSUMER_USB_SOCKET   (CY_U3P_UIB_SOCKET_CONS_1)

#define FX3_FIFO_DATA_PRODUCER_PPORT_SOCKET (CY_U3P_PIB_SOCKET_0)
#define FX3_FIFO_DATA_CONSUMER_USB_SOCKET   (CY_U3P_UIB_SOCKET_CONS_2)

#define FX3_FIFO_DATA_PRODUCER_USB_SOCKET   (CY_U3P_UIB_SOCKET_PROD_2)
#define FX3_FIFO_DATA_CONSUMER_PPORT_SOCKET (CY_U3P_PIB_SOCKET_1)

// Watermark levels for almost full/empty flags
#define FX3_SOCKET_0_WATERMARK (6)
#define FX3_SOCKET_1_WATERMARK (6)

// Request direction
#define FX3_USB_DIRECTION_MASK (0x80)
#define FX3_USB_DIRECTION_IN   (0x00) /* Host-to-Device */
#define FX3_USB_DIRECTION_OUT  (0x80) /* Device-to-Host */

#define FX3_REQ_DIR(request, direction) (((direction) << 8) | (request))

// Debug severity levels
#define LOG_EMERGENCY (0)
#define LOG_ALERT     (1)
#define LOG_CRITICAL  (2)
#define LOG_ERROR     (3)
#define LOG_WARNING   (4)
#define LOG_NOTICE    (5)
#define LOG_INFO      (6)
#define LOG_DEBUG     (7)

// Frequency readability macros
#define KILOHERTZ (1000)
#define MEGAHERTZ (1000 * (KILOHERTZ))

// Memory readability macros
#define KILOBYTE (1024)
#define MEGABYTE (1024 * (KILOBYTE))

// Function declarations
void CyFxErrorHandler(uint8_t log_level, const char *debug_message, CyU3PReturnStatus_t error_code);

// Variable declarations (globally accessible)
extern CyBool_t glAppRunning;
extern uint8_t glLogLevel;
extern uint8_t glLogFailedAmount;
extern uint8_t glEP0Buffer[];

#include "devices/fx3_select.h"

#endif /* _INCLUDED_FX3_H_ */
