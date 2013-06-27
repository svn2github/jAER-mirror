/* This file contains the USB enumeration descriptors.
 * The descriptor arrays must be 32 byte aligned and multiple of 32 bytes if the D-cache is
 * turned on. If the linker used is not capable of supporting the aligned feature for this,
 * either the descriptors must be placed in a different section and the section should be
 * 32 byte aligned and 32 byte multiple; or dynamically allocated buffer allocated using
 * CyU3PDmaBufferAlloc must be used, and the descriptor must be loaded into it. The example
 * assumes that the aligned attribute for 32 bytes is supported by the linker. Do not add
 * any other variables to this file other than USB descriptors. This is not the only
 * pre-requisite to enabling the D-cache. Refer to the documentation for
 * CyU3PDeviceCacheControl for more information.
 */

#ifndef _INCLUDED_FX3_USBDESCR_H_
#define _INCLUDED_FX3_USBDESCR_H_ 1

/* Standard device descriptor for USB 3.0 */
const uint8_t CyFxUSB30DeviceDscr[] __attribute__ ((aligned (32))) = { 0x12, /* Descriptor size */
CY_U3P_USB_DEVICE_DESCR, /* Device descriptor type */
0x00, 0x03, /* USB 3.0 */
0x00, /* Device class */
0x00, /* Device sub-class */
0x00, /* Device protocol */
0x09, /* Maxpacket size for EP0 : 2^9 (512 bytes) */
VENDOR_ID, /* Vendor ID */
PRODUCT_ID, /* Product ID */
DEVICE_ID, /* Device release number */
0x01, /* Manufacture string index */
0x02, /* Product string index */
0x03, /* Serial number string index */
0x01 /* Number of configurations */
};

/* Standard device descriptor for USB 2.0 */
const uint8_t CyFxUSB20DeviceDscr[] __attribute__ ((aligned (32))) = { 0x12, /* Descriptor size */
CY_U3P_USB_DEVICE_DESCR, /* Device descriptor type */
0x10, 0x02, /* USB 2.10 */
0x00, /* Device class */
0x00, /* Device sub-class */
0x00, /* Device protocol */
0x40, /* Maxpacket size for EP0 : 64 bytes */
VENDOR_ID, /* Vendor ID */
PRODUCT_ID, /* Product ID */
DEVICE_ID, /* Device release number */
0x01, /* Manufacture string index */
0x02, /* Product string index */
0x03, /* Serial number string index */
0x01 /* Number of configurations */
};

/* Binary device object store descriptor */
const uint8_t CyFxUSBBOSDscr[] __attribute__ ((aligned (32))) = { 0x05, /* Descriptor size */
CY_U3P_BOS_DESCR, /* Device descriptor type */
0x16, 0x00, /* Length of this descriptor and all sub descriptors */
0x02, /* Number of device capability descriptors */

/* USB 2.0 extension */
0x07, /* Descriptor size */
CY_U3P_DEVICE_CAPB_DESCR, /* Device capability type descriptor */
CY_U3P_USB2_EXTN_CAPB_TYPE, /* USB 2.0 extension capability type */
0x02, 0x00, 0x00, 0x00, /* Supported device level features: LPM support  */

/* SuperSpeed device capability */
0x0A, /* Descriptor size */
CY_U3P_DEVICE_CAPB_DESCR, /* Device capability type descriptor */
CY_U3P_SS_USB_CAPB_TYPE, /* SuperSpeed device capability type */
0x00, /* Supported device level features  */
0x0E, 0x00, /* Speeds supported by the device : SS, HS and FS */
0x03, /* Functionality support */
0x00, /* U1 Device Exit latency */
0x00, 0x00 /* U2 Device Exit latency */
};

/* Standard device qualifier descriptor */
const uint8_t CyFxUSBDeviceQualDscr[] __attribute__ ((aligned (32))) = { 0x0A, /* Descriptor size */
CY_U3P_USB_DEVQUAL_DESCR, /* Device qualifier descriptor type */
0x00, 0x02, /* USB 2.0 */
0x00, /* Device class */
0x00, /* Device sub-class */
0x00, /* Device protocol */
0x40, /* Maxpacket size for EP0 : 64 bytes */
0x01, /* Number of configurations */
0x00 /* Reserved */
};

/* Standard super speed configuration descriptor */
const uint8_t CyFxUSBSSConfigDscr[] __attribute__ ((aligned (32))) = {
/* Configuration descriptor */
0x09, /* Descriptor size */
CY_U3P_USB_CONFIG_DESCR, /* Configuration descriptor type */
0x39, 0x00, /* Length of this descriptor and all sub descriptors */
0x01, /* Number of interfaces */
0x01, /* Configuration number */
0x00, /* Configuration string index */
0x80, /* Config characteristics - Bus powered */
0x32, /* Max power consumption of device (in 8mA unit) : 400mA */

/* Interface descriptor */
0x09, /* Descriptor size */
CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
0x00, /* Interface number */
0x00, /* Alternate setting number */
0x03, /* Number of end points */
0xFF, /* Interface class */
0x00, /* Interface sub class */
0x00, /* Interface protocol code */
0x00, /* Interface descriptor string index */

/* Endpoint descriptor for consumer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_STATUS_EP_ADDR_OUT, /* Endpoint address and description */
CY_U3P_USB_EP_INTR, /* Interrupt endpoint type */
0x40, 0x00, /* Max packet size = 64 bytes */
0x04, /* Servicing interval for data transfers : 0.5ms (125us frames) */

/* Super speed endpoint companion descriptor for consumer EP */
0x06, /* Descriptor size */
CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
0x00, /* Max no. of packets in a burst : 0: burst 1 packet at a time */
0x00, /* Max streams for bulk EP = 0 (No streams) */
0x40, 0x00, /* Bytes per interval: 64 bytes */

/* Endpoint descriptor for producer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_FIFO_DATA_EP_ADDR_IN, /* Endpoint address and description */
CY_U3P_USB_EP_BULK, /* Bulk endpoint type */
0x00, 0x04, /* Max packet size = 1024 bytes */
0x00, /* Servicing interval for data transfers : 0 for bulk */

/* Super speed endpoint companion descriptor for producer EP */
0x06, /* Descriptor size */
CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
FX3_FIFO_DATA_DMA_USBTOFX3_BURST_LEN - 1, /* Max no. of packets in a burst : 0: burst 1 packet at a time */
0x00, /* Max streams for bulk EP = 0 (No streams) */
0x00, 0x00, /* Service interval for the EP : 0 for bulk */

/* Endpoint descriptor for consumer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_FIFO_DATA_EP_ADDR_OUT, /* Endpoint address and description */
CY_U3P_USB_EP_BULK, /* Bulk endpoint type */
0x00, 0x04, /* Max packet size = 1024 bytes */
0x00, /* Servicing interval for data transfers : 0 for Bulk */

/* Super speed endpoint companion descriptor for consumer EP */
0x06, /* Descriptor size */
CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
FX3_FIFO_DATA_DMA_FX3TOUSB_BURST_LEN - 1, /* Max no. of packets in a burst : 0: burst 1 packet at a time */
0x00, /* Max streams for bulk EP = 0 (No streams) */
0x00, 0x00 /* Service interval for the EP : 0 for bulk */
};

/* Standard high speed configuration descriptor */
const uint8_t CyFxUSBHSConfigDscr[] __attribute__ ((aligned (32))) = {
/* Configuration descriptor */
0x09, /* Descriptor size */
CY_U3P_USB_CONFIG_DESCR, /* Configuration descriptor type */
0x27, 0x00, /* Length of this descriptor and all sub descriptors */
0x01, /* Number of interfaces */
0x01, /* Configuration number */
0x00, /* Configuration string index */
0x80, /* Config characteristics - bus powered */
0x32, /* Max power consumption of device (in 2mA unit) : 100mA */

/* Interface descriptor */
0x09, /* Descriptor size */
CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
0x00, /* Interface number */
0x00, /* Alternate setting number */
0x03, /* Number of endpoints */
0xFF, /* Interface class */
0x00, /* Interface sub class */
0x00, /* Interface protocol code */
0x00, /* Interface descriptor string index */

/* Endpoint descriptor for consumer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_STATUS_EP_ADDR_OUT, /* Endpoint address and description */
CY_U3P_USB_EP_INTR, /* Interrupt endpoint type */
0x40, 0x00, /* Max packet size = 64 bytes */
0x04, /* Servicing interval for data transfers : 0.5ms (125us frames) */

/* Endpoint descriptor for producer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_FIFO_DATA_EP_ADDR_IN, /* Endpoint address and description */
CY_U3P_USB_EP_BULK, /* Bulk endpoint type */
0x00, 0x02, /* Max packet size = 512 bytes */
0x00, /* Servicing interval for data transfers : 0 for bulk */

/* Endpoint descriptor for consumer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_FIFO_DATA_EP_ADDR_OUT, /* Endpoint address and description */
CY_U3P_USB_EP_BULK, /* Bulk endpoint type */
0x00, 0x02, /* Max packet size = 512 bytes */
0x00 /* Servicing interval for data transfers : 0 for bulk */
};

/* Standard full speed configuration descriptor */
const uint8_t CyFxUSBFSConfigDscr[] __attribute__ ((aligned (32))) = {
/* Configuration descriptor */
0x09, /* Descriptor size */
CY_U3P_USB_CONFIG_DESCR, /* Configuration descriptor type */
0x27, 0x00, /* Length of this descriptor and all sub descriptors */
0x01, /* Number of interfaces */
0x01, /* Configuration number */
0x00, /* Configuration string index */
0x80, /* Config characteristics - bus powered */
0x32, /* Max power consumption of device (in 2mA unit) : 100mA */

/* Interface descriptor */
0x09, /* Descriptor size */
CY_U3P_USB_INTRFC_DESCR, /* Interface descriptor type */
0x00, /* Interface number */
0x00, /* Alternate setting number */
0x03, /* Number of endpoints */
0xFF, /* Interface class */
0x00, /* Interface sub class */
0x00, /* Interface protocol code */
0x00, /* Interface descriptor string index */

/* Endpoint descriptor for consumer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_STATUS_EP_ADDR_OUT, /* Endpoint address and description */
CY_U3P_USB_EP_INTR, /* Interrupt endpoint type */
0x40, 0x00, /* Max packet size = 64 bytes */
0x01, /* Servicing interval for data transfers : 1ms (1ms frames) */

/* Endpoint descriptor for producer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_FIFO_DATA_EP_ADDR_IN, /* Endpoint address and description */
CY_U3P_USB_EP_BULK, /* Bulk endpoint type */
0x40, 0x00, /* Max packet size = 64 bytes */
0x00, /* Servicing interval for data transfers : 0 for bulk */

/* Endpoint descriptor for consumer EP */
0x07, /* Descriptor size */
CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
FX3_FIFO_DATA_EP_ADDR_OUT, /* Endpoint address and description */
CY_U3P_USB_EP_BULK, /* Bulk endpoint type */
0x40, 0x00, /* Max packet size = 64 bytes */
0x00 /* Servicing interval for data transfers : 0 for bulk */
};

/* Standard language ID string descriptor */
const uint8_t CyFxUSBStringLangIDDscr[] __attribute__ ((aligned (32))) = { 0x04, /* Descriptor size */
CY_U3P_USB_STRING_DESCR, /* Device descriptor type */
0x09, 0x04 /* Language ID supported */};

/* Standard manufacturer string descriptor */
const uint8_t CyFxUSBManufacturerDscr[] __attribute__ ((aligned (32))) = { STRING_MANUFACTURER_LEN + 2, /* Descriptor size */
CY_U3P_USB_STRING_DESCR, /* Device descriptor type */
STRING_MANUFACTURER };

/* Standard product string descriptor */
const uint8_t CyFxUSBProductDscr[] __attribute__ ((aligned (32))) = { STRING_PRODUCT_LEN + 2, /* Descriptor size */
CY_U3P_USB_STRING_DESCR, /* Device descriptor type */
STRING_PRODUCT };

/* Standard serial number string descriptor */
uint8_t CyFxUSBSerialNumberDscr[] __attribute__ ((aligned (32))) = { STRING_SERIALNUMBER_LEN + 2, /* Descriptor size */
CY_U3P_USB_STRING_DESCR, /* Device descriptor type */
STRING_SERIALNUMBER };

#if MS_FEATURE_DESCRIPTOR_ENABLED == 1
/* Microsoft OS string descriptor */
const uint8_t CyFxUSBMicrosoftOSDscr[] __attribute__ ((aligned (32))) = { 0x12, /* Descriptor size */
CY_U3P_USB_STRING_DESCR, /* Device descriptor type */
0x4D, 0x00, 0x53, 0x00, 0x46, 0x00, 0x54, 0x00, 0x31, 0x00, 0x30, 0x00, 0x30, 0x00, /* "MSFT100" signature */
0xAF, 0x00 /* Vendor Request code */ };
#endif

/* Place this buffer as the last buffer so that no other variable / code shares
 * the same cache line. Do not add any other variables / arrays in this file.
 * This will lead to variables sharing the same cache line. */
const uint8_t CyFxUSBDscrAlignBuffer[32] __attribute__ ((aligned (32)));

#endif /* _INCLUDED_FX3_USBDESCR_H_ */