#ifndef __UART_H 
#define __UART_H

#include "config.h"

#if UART_PORT_DEFAULT == 0
#define LPC_UART LPC_USART0
#elif UART_PORT_DEFAULT == 1
#define LPC_UART ((LPC_USART_T*)LPC_UART1)
#else
#error "undefined value of UART"
#endif

#define RTS0_PORT                		(1)
#define RTS0_PIN                		(3)
#define RTS0_GPIO_PORT                	(0)
#define RTS0_GPIO_PIN               	(10)

#define CTS0_PORT						(1)
#define CTS0_PIN						(5)
#define CTS0_GPIO_PORT					(1)
#define CTS0_GPIO_PIN					(8)

#define TX_BUFFER_SIZE_BITS		(12)
#define TX_BUFFER_SIZE			(1<<TX_BUFFER_SIZE_BITS)
#define TX_BUFFER_MASK			(TX_BUFFER_SIZE-1)

#define RX_BUFFER_SIZE_BITS		(12)
#define RX_BUFFER_SIZE			(1<<RX_BUFFER_SIZE_BITS)
#define RX_BUFFER_MASK			(RX_BUFFER_SIZE-1)
#define RX_WARNING				(128)

struct uart_hal {
#if LOW_POWER_MODE
	uint32_t txSleepingFlag;
#endif
	uint32_t txBufferWritePointer;
	uint32_t txBufferReadPointer;
	uint32_t rxBufferWritePointer;
	uint32_t rxBufferReadPointer;
	uint8_t txBuffer[TX_BUFFER_SIZE];
	uint8_t rxBuffer[RX_BUFFER_SIZE];
};
//Transmit buffer that will be used on the rest of the system
extern volatile struct uart_hal uart;

STATIC INLINE void pushByteToTransmission(volatile struct uart_hal * uart, uint8_t byte) {
	uart->txBuffer[uart->txBufferWritePointer] = byte;
	uart->txBufferWritePointer = (uart->txBufferWritePointer + 1) & TX_BUFFER_MASK;
}

STATIC INLINE void pushByteToReception(volatile struct uart_hal * uart, uint8_t byte) {
	uart->rxBuffer[uart->rxBufferWritePointer] = byte;
	uart->rxBufferWritePointer = (uart->rxBufferWritePointer + 1) & RX_BUFFER_MASK;
}

STATIC INLINE void popByteFromTransmissionBuffer(volatile struct uart_hal * uart) {
	LPC_UART->THR = uart->txBuffer[uart->txBufferReadPointer];
	uart->txBufferReadPointer = (uart->txBufferReadPointer + 1) & TX_BUFFER_MASK;
}

#if LOW_POWER_MODE
STATIC INLINE uint32_t M4Sleeping(volatile struct uart_hal * uart) {
	return uart->txSleepingFlag;
}
#endif

STATIC INLINE uint8_t bytesToSend(volatile struct uart_hal * uart) {
	return uart->txBufferReadPointer != uart->txBufferWritePointer;
}

STATIC INLINE uint8_t bytesReceived(volatile struct uart_hal * uart) {
	return uart->rxBufferReadPointer != uart->rxBufferWritePointer;
}
STATIC INLINE volatile uint8_t popByteFromReceptionBuffer(volatile struct uart_hal * uart) {
	volatile uint8_t ret = uart->rxBuffer[uart->rxBufferReadPointer];
	uart->rxBufferReadPointer = (uart->rxBufferReadPointer + 1) & RX_BUFFER_MASK;
	return ret;
}

STATIC INLINE uint32_t freeSpaceForReception(volatile struct uart_hal * uart) {
	if (uart->rxBufferReadPointer == uart->rxBufferWritePointer)
		return RX_BUFFER_SIZE;
	else if (uart->rxBufferReadPointer > uart->rxBufferWritePointer) {
		return uart->rxBufferReadPointer - uart->rxBufferWritePointer;
	} else {
		return RX_BUFFER_SIZE - uart->rxBufferWritePointer + uart->rxBufferReadPointer;
	}
}
STATIC INLINE uint32_t freeSpaceForTranmission(volatile struct uart_hal * uart) {
	if (uart->txBufferReadPointer == uart->txBufferWritePointer)
		return TX_BUFFER_SIZE;
	else if (uart->txBufferReadPointer > uart->txBufferWritePointer) {
		return uart->txBufferReadPointer - uart->txBufferWritePointer;
	} else {
		return TX_BUFFER_SIZE - uart->txBufferWritePointer + uart->txBufferReadPointer;
	}
}

/**
 * It initializes the selected UART peripheral.
 * @param UARTx Pointer to the UART peripheral
 * @param Baudrate Baud rate to be used
 */
extern void UARTInit(LPC_USART_T* UARTx, uint32_t Baudrate);

/**
 * Prints through the UART the version string of the firmware.
 */
extern void UARTShowVersion(void);

/**
 * Parses the character received
 * @param newChar new character received
 */
extern void UART0ParseNewChar(unsigned char newChar);

#endif /* end __UART_H */
/*****************************************************************************
 **                            End Of File
 ******************************************************************************/
