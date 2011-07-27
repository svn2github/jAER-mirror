#include "lpc210x_01.h"
#include <stdio.h>
#include <arm_macros.h>

// T0 is running in 1ms time resolution --> 2^32ms = 1193h = 49.7d before wrap over!
// T1 is system time, running 0..(2^32-1) at main clock rate

// ***************************************************************************** CPU clock
//#define PLL_CLOCK	   112
//#define PLL_CLOCK	    96
//#define PLL_CLOCK	    80
#define PLL_CLOCK	    64
//#define PLL_CLOCK	    32

// ***************************************************************************** event time stamp resolution
//#define TIMESTAMP_SHIFTBITS						7	// 64MHz >> 7 = 500KHz --> 2us   resolution
#define TIMESTAMP_SHIFTBITS							6	// 64MHz >> 6 = 1MHz   --> 1us   resolution
//#define TIMESTAMP_SHIFTBITS						5	// 64MHz >> 5 = 2MHz   --> 0.5us resolution

// ***************************************************************************** small stuff
//#define TIME_OPTIMIZED	  						// remove all "stuff" from mainloop
		  											// that might cause slowdown (e.g. blinking LED!)
//#define INCLUDE_MARK_BUFFEROVERFLOW
//#define INCLUDE_PIXEL_CUTOUT_REGION

// ***************************************************************************** hardware settings
//#define INCLUDE_PWM246
//  #define INCLUDE_PWM246_ENABLE_PWM2_OUT			// pin shared with SPI-SSEL, P0.7
//  #define INCLUDE_PWM246_ENABLE_PWM4_OUT			// pin shared with UART1-TXD, P0.8
//  #define INCLUDE_PWM246_ENABLE_PWM6_OUT			// pin shared with UART1-RXD, P0.9
//  #define USE_ALTERNATE_RTS_CTS 					// define this if you use PWM4/6 to relocate RTS/CTS

//#define INCLUDE_EDVS_CHAINING					// not yet implemented


// ***************************************************************************** included algorithms
//#define INCLUDE_TRACK_HF_LED
//  #define INCLUDE_TRACK_HF_LED_SERVO_OUT
//  #define INCLUDE_TRACK_HF_LED_LASERPOINTER

// ***************************************************************************** default baudrate
#define BAUD_RATE_DEFAULT		((unsigned long) (4000000))
//#define BAUD_RATE_DEFAULT		((unsigned long) (2000000))
//#define BAUD_RATE_DEFAULT		((unsigned long) (1843200))
//#define BAUD_RATE_DEFAULT		((unsigned long) (1000000))
//#define BAUD_RATE_DEFAULT		((unsigned long) ( 921600))
//#define BAUD_RATE_DEFAULT		((unsigned long) ( 500000))
//#define BAUD_RATE_DEFAULT		((unsigned long) ( 460800))
//#define BAUD_RATE_DEFAULT		((unsigned long) ( 230400))
//#define BAUD_RATE_DEFAULT		((unsigned long) ( 115200))
//#define BAUD_RATE_DEFAULT		((unsigned long) (  19200))

// ***************************************************************************** data formats
#define EDVS_DATA_FORMAT_DEFAULT			EDVS_DATA_FORMAT_ASCII_TS

#define EDVS_DATA_FORMAT_BIN				 0					//  2 Bytes/event
#define EDVS_DATA_FORMAT_BIN_TS				 1					//  4 Bytes/event

#define EDVS_DATA_FORMAT_6B					10					//  3 Bytes/event
#define EDVS_DATA_FORMAT_6B_TS				11					//  6 Bytes/event
#define EDVS_DATA_FORMAT_6B_RET				12					//  4 Bytes/event
#define EDVS_DATA_FORMAT_6B_TS_RET			13					//  7 Bytes/event

#define EDVS_DATA_FORMAT_HEX				20					//  4 Bytes/event
#define EDVS_DATA_FORMAT_HEX_TS				21					//  8 Bytes/event
#define EDVS_DATA_FORMAT_HEX_RET			22					//  5 Bytes/event
#define EDVS_DATA_FORMAT_HEX_TS_RET			23					//  9 Bytes/event

#define EDVS_DATA_FORMAT_ASCII				30					// 10 Bytes/event
#define EDVS_DATA_FORMAT_ASCII_TS			31					// 16 Bytes/event

// *****************************************************************************
#if ((PLL_CLOCK != 112) && (PLL_CLOCK != 96) && (PLL_CLOCK != 80) && (PLL_CLOCK != 64) && (PLL_CLOCK != 32))
#error specify PLL_CLOCK as 32, 64, 80, 96, or 112 MHz
#endif
// *****************************************************************************


#define BIT(x)				   ((unsigned long) (((unsigned long) 1)<<x))
// *****************************************************************************
// *************************************** global constants
#define SOFTWARE_VERSION				"1.1"

#define DVS_EVENTBUFFER_SIZE_BITS		((unsigned long) 12)
#define DVS_EVENTBUFFER_SIZE		  	(((unsigned long) 1)<<DVS_EVENTBUFFER_SIZE_BITS)
#define DVS_EVENTBUFFER_MASK		  	(DVS_EVENTBUFFER_SIZE - 1)

#define UART_COMMAND_LINE_MAX_LENGTH  96

// *************************************** Pinout definitions
#define PIN_LED						(BIT(13)) 	// P0.13 (same pin as "bias in", used as LED)

#define PIN_ISP						(BIT(14))	// P0.14 (ISP)

#define PIN_UART0_TXD				(BIT(0))	// P0.0 (TxD0)
#define PIN_UART0_RXD				(BIT(1))	// P0.1 (RxD0)
#ifdef INCLUDE_EDVS_CHAINING
  #define PIN_UART1_TXD				(BIT(8))	// P0.8 (TxD1)
  #define PIN_UART1_RXD				(BIT(9))	// P0.9 (RxD1)
  #define PIN_UART0_RTS				(BIT(4))	// P0.04 (SCK),  (LPC-in)  (pin 5 on UART0 connector)    // here eDVS is "slave"
  #define PIN_UART0_CTS				(BIT(5))	// P0.05 (MISO), (LPC-out) (pin 6 on UART0 connector)
  #define PIN_UART1_RTS				(BIT(6))	// P0.06 (MOSI), (LPC-out) (pin 5 on UART1 connector)	 // here eDVS is "master"
  #define PIN_UART1_CTS				(BIT(7))	// P0.07 (SSEL), (LPC-in)  (pin 6 on UART1 connector)
#else
  #ifdef USE_ALTERNATE_RTS_CTS
    #define PIN_UART0_RTS			(BIT(4))	// P0.04 (SCK),  (LPC-in)  (pin 5 on UART0 connector)    // here eDVS is "slave"
    #define PIN_UART0_CTS			(BIT(5))	// P0.05 (MISO), (LPC-out) (pin 6 on UART0 connector)
  #else
    #define PIN_UART0_RTS			(BIT(8))	// P0.08 (LPC-in)  (pin 5 on UART connector)
    #define PIN_UART0_CTS			(BIT(9))	// P0.09 (LPC-out) (pin 6 on UART connector)
  #endif
#endif

#ifdef INCLUDE_TRACK_HF_LED_LASERPOINTER
#define PIN_TRACK_HFL_LASER			(BIT(2) | BIT(3))	// P0.02 signal to control laser diode
#endif

#define PIN_BIAS_CLOCK				(BIT(31))	// P0.31 signal to bias clock
#define PIN_BIAS_DATA				(BIT(13))	// P0.13 signal to bias setup
#define PIN_BIAS_LATCH				(BIT(12))	// P0.12 signal to bias latch

#define PIN_RESET_DVS				(BIT(15))	// P0.15 reset DVS
#define PIN_DVS_REQUEST				(BIT(10))	// P0.10 DVS request (input to LPC) (Pin CAP 1.0)
#define PIN_DVS_ACKN				(BIT(11))	// P0.11 DVS acknowledge (output to DVS)

#define PIN_ALL_ADDR		((unsigned long) 0x7FFF0000)		// all 15 address bits from DVS
#define PIN_ADDR_X			((unsigned long) 0x007F0000)		// address bits X
#define PIN_ADDR_P			((unsigned long) 0x00800000)		// bit specifying polarity of event
#define PIN_ADDR_Y			((unsigned long) 0x7F000000)		// address bits Y
#define OVERFLOW_BIT		((unsigned long) 0x80000000)		// this bit denotes overflow

// *************************************** world stuff
#define FALSE		   		0
#define TRUE				1
#define NOT(x)				(1-(x))

// *************************************** bias definitions
#define BIAS_cas			 0
#define BIAS_injGnd			 1
#define BIAS_reqPd			 2
#define BIAS_puX			 3
#define BIAS_diffOff		 4
#define BIAS_req			 5
#define BIAS_refr			 6
#define BIAS_puY			 7
#define BIAS_diffOn			 8
#define BIAS_diff			 9
#define BIAS_foll			10
#define BIAS_Pr				11

// *************************************** macros
#define LED_ON()			{FGPIO_IOCLR=PIN_LED;}
#define LED_OFF()			{FGPIO_IOSET=PIN_LED;}
#define LED_TOGGLE()		{if ((FGPIO_IOPIN & PIN_LED)) { LED_ON();} else {LED_OFF();}}


// *************************************** Function prototypes
extern void delayUS(unsigned long delayTimeUS);
extern void delayMS(unsigned long delayTimeMS);
extern void resetDevice(void);
extern void enterReprogrammingMode(void);
extern void LEDSetState(long state);
#define LEDSetOn() LEDSetState(1)
#define LEDSetOff() LEDSetState(0)
#define LEDSetBlinking() LEDSetState(((long) -1))
#define LEDSetTime(x) LEDSetState(x)

extern void mainloopInit(void);
extern void mainloop(void);
extern void transmitSpecialData(unsigned long l);

extern int putchar(char charToSend);
extern void UARTInit(void);
extern void parseUARTCommandLine(void);
extern void UARTParseNewChar(unsigned char newChar); 	// in main loop
extern void UARTShowVersion(void);

extern void DVS128ChipInit(void);
extern void DVS128FetchEventsEnable(unsigned char flag);
extern void DVS128SetRequestedEventRate(unsigned long newKEPS);
extern void DVS128BiasSet(unsigned long biasID, unsigned long biasValue);
extern unsigned long DVS128BiasGet(unsigned long biasID);
extern void DVS128BiasLoadDefaultSet(unsigned long biasSetID);
extern void DVS128BiasFlush(void);
extern void DVS128BiasTransmitBiasValue(unsigned long biasID);


#ifdef INCLUDE_PWM246
extern void PWM246SetSignal(unsigned long id, unsigned long newSignal);
extern unsigned long PWM246GetSignal(unsigned long id);
extern void PWM246SetCycle(unsigned long newCycle);
extern unsigned long PWM246GetCycle(void);
extern void PWM246Init(void);
extern void PWM246StopPWM(void);
#endif

#ifdef INCLUDE_TRACK_HF_LED
extern void EP_TrackHFLInit(void);
extern void EP_TrackHFLSetOutputEnabled(unsigned long flag);
extern long EP_TrackHFLGetOutputEnabled(void);
#ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
extern void EP_TrackHFLServoSetEnabled(unsigned long flag);
extern long EP_TrackHFLServoGetEnabled(void);
extern void EP_TrackHFLServoResetPosition(void);
#endif
#endif
