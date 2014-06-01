#ifndef _INCLUDED_SPI_SUPPORT_H_
#define _INCLUDED_SPI_SUPPORT_H_ 1

// Vendor requests
#define VR_SPI_CONFIG 0xB9
#define VR_SPI_CMD 0xBA
#define VR_SPI_TRANSFER 0xBB
#define VR_SPI_ERASE 0xBC

// SPI maximum data rate (in Hertz)
#define SPI_MAX_CLOCK (33 * MEGAHERTZ)

// Macros to increase readability
#define SPI_READ CyTrue
#define SPI_WRITE CyFalse
#define SPI_ASSERT 0x00
#define SPI_NO_ASSERT 0x01
#define SPI_DEASSERT 0x00
#define SPI_NO_DEASSERT 0x02

// Function declarations
CyU3PReturnStatus_t CyFxSpiConfigParse(uint32_t *gpioSimpleEn0, uint32_t *gpioSimpleEn1);
CyU3PReturnStatus_t CyFxSpiInit(void);
void CyFxSpiSSLineAssert(uint8_t deviceAddress);
void CyFxSpiSSLineDeassert(uint8_t deviceAddress);
CyU3PReturnStatus_t CyFxSpiCommand(uint8_t deviceAddress, const uint8_t *cmd, uint8_t cmdLength, uint8_t *data,
	uint16_t dataLength, CyBool_t isRead, uint8_t controlFlags);
CyU3PReturnStatus_t CyFxSpiTransfer(uint8_t deviceAddress, uint32_t address, uint8_t *data, uint16_t dataLength,
	CyBool_t isRead);
CyU3PReturnStatus_t CyFxSpiEraseBlock(uint8_t deviceAddress, uint32_t address);
CyBool_t CyFxHandleCustomVR_SPI(uint8_t bDirection, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
	uint16_t wLength);

#endif /* _INCLUDED_SPI_SUPPORT_H_ */
