#ifndef _INCLUDED_COMMON_VENDOR_REQUESTS_H_
#define _INCLUDED_COMMON_VENDOR_REQUESTS_H_ 1

// Vendor requests
#define VR_MS_FEATURE_DSCR 0xAF
#define VR_TEST 0xB0
#define VR_LOG_LEVEL 0xB1
#define VR_FX3_RESET 0xB2
#define VR_STATUS 0xB3
#define VR_SUPPORTED 0xB4

// Function declarations
CyBool_t CyFxHandleCustomVR_Common(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength);

#endif /* _INCLUDED_COMMON_VENDOR_REQUESTS_H_ */
