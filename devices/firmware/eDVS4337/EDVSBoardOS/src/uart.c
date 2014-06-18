#include <string.h>
#include <cr_section_macros.h>
#include "chip.h"

#include "config.h"
#include "extra_pins.h"
#include "uart.h"
#include "sensors.h"
#include "motors.h"
#include "sleep.h"
#include "utils.h"
#include "pwm.h"
#include "EDVS128_LPC43xx.h"
#include "sdcard.h"
#include "xprintf.h"

#define MHZ								(1000000)

__NOINIT(RAM5) volatile struct uart_hal uart;

//length of "2012-03-02 12:00:00"
#define TIME_DATE_COM_SIZE (20)

#define UART_COMMAND_LINE_MAX_LENGTH  	128

// *****************************************************************************

unsigned char commandLine[UART_COMMAND_LINE_MAX_LENGTH];
uint32_t commandLinePointer;
uint32_t enableUARTecho;	 // 0-no cmd echo, 1-only cmd reply, 2-all visible

// *****************************************************************************
#define UARTReturn()	   xputc('\n')

/* The rate at which data is sent to the queue, specified in milliseconds. */

/*****************************************************************************
 ** Function name:		UARTSend
 **
 ** Descriptions:		Send a block of data to the UART 0 port based
 **						on the data length
 **
 ** parameters:			portNum, buffer pointer, and data length
 ** Returned value:		None
 **
 *****************************************************************************/

void UARTWriteChar(char pcBuffer) {
	while (freeSpaceForTranmission(&uart) == 0) {
		; //Wait for the M0 core to move some char out
	}
	pushByteToTransmission(&uart, pcBuffer);
}

/*****************************************************************************
 ** Function name:		UARTInit
 **
 ** Descriptions:		Initialize UART port, setup pin select,
 **						clock, parity, stop bits, FIFO, etc.
 **
 ** parameters:			portNum(0 or 1) and UART baudrate
 ** Returned value:		true or false, return false only if the
 **						interrupt handler can't be installed to the
 **						VIC table
 **
 *****************************************************************************/
void UARTInit(LPC_USART_T* UARTx, uint32_t baudrate) {
	memset(commandLine, 0, UART_COMMAND_LINE_MAX_LENGTH);
	commandLinePointer = 0;
	enableUARTecho = 2;
	memset((void*) &uart, 0, sizeof(struct uart_hal));
	xdev_out(UARTWriteChar);
	if (UARTx == LPC_USART0) {
		NVIC_DisableIRQ(USART0_IRQn);
		/* RxD0 is P2.1 and TxD0 is P2.0 */
		Chip_SCU_PinMuxSet(2, 0, MD_PLN_FAST | FUNC1);
		Chip_SCU_PinMuxSet(2, 1, MD_PLN_FAST | MD_EZI | FUNC1);
		Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, RTS0_GPIO_PORT, RTS0_GPIO_PIN); //Signal ready to the DTE
		Chip_GPIO_SetPinDIROutput(LPC_GPIO_PORT, RTS0_GPIO_PORT, RTS0_GPIO_PIN);
		Chip_SCU_PinMuxSet(RTS0_PORT, RTS0_PIN, MD_PLN_FAST | FUNC0);
		Chip_GPIO_SetPinDIRInput(LPC_GPIO_PORT, CTS0_GPIO_PORT, CTS0_GPIO_PIN);
		Chip_SCU_PinMuxSet( CTS0_PORT, CTS0_PIN, MD_BUK | MD_EZI | FUNC0);
	} else if (UARTx == LPC_UART1) {
		NVIC_DisableIRQ(UART1_IRQn);
		/* Enable RTS1  P5.2, CTS1 P5.4, RxD1 P1.14, TxD1 P3.4*/
		Chip_SCU_PinMuxSet(3, 4, MD_PLN_FAST | FUNC4);
		Chip_SCU_PinMuxSet(1, 14, MD_BUK | MD_EZI | FUNC1);
		Chip_SCU_PinMuxSet(5, 2, MD_PLN_FAST | FUNC4);
		Chip_SCU_PinMuxSet(5, 4, MD_BUK | MD_EZI | FUNC4);
		Chip_UART_SetModemControl(LPC_UART1,
		UART_MCR_AUTO_RTS_EN | UART_MCR_AUTO_CTS_EN);
	}
	Chip_UART_Init(UARTx);
	Chip_UART_SetBaudFDR(UARTx, baudrate);
	Chip_UART_TXEnable(UARTx);
}

// *****************************************************************************

// *****************************************************************************
void UARTShowVersion(void) {
	xputs("\nEDVS-4337, V" SOFTWARE_VERSION);
#if USE_IMU_DATA
	xputs(" IMU");
#endif
#if USE_MINIROB
	xputs(" MROB");
#endif
#if USE_SDCARD
	xputs(" SD");
#endif
#if LOW_POWER_MODE
	xputs(" LP");
#endif
#if EXTENDED_TIMESTAMP
	xputs(" ET");
#endif
	xputs(" " __DATE__ ", " __TIME__ "\n");

	xprintf("System Clock: %3dMHz; 1us event time resolution\n", SystemCoreClock / MHZ);
}

// *****************************************************************************
static void UARTShowUsage(void) {

	UARTShowVersion();

	UARTReturn();
	xputs("Supported Commands:\n");
	UARTReturn();

	xputs(" E+/-                  - enable/disable event sending\n");
#if USE_SDCARD
	xputs(" !ER+/-                - enable/disable event recording (SD card)\n");
#endif
	xputs(" !Ex                   - specify event data format, ??E to show options\n");
	xputs(" !ETx                  - set current timestamp to x (default: 0)\n");
	xputs(" !ETM+                 - synch timestamp, master mode, output active\n");
	xputs(" !ETM0                 - synch timestamp, master mode, output stopped\n");
	xputs(" !ETS                  - synch timestamp, slave mode\n");
	xputs(" !ETI                  - single retina, no external synch mode\n");
	UARTReturn();

	xputs(" !B[0-11]=x            - set bias register to value\n"); // please check, I have removed leading "0x" --- can we change this to decimal reception?
	xputs(" !BF                   - send bias settings to DVS (flush)\n");
	xputs(" !BDx                  - select and flush predefined bias set x\n");
	xputs(" ?Bx                   - get bias register x current value\n");
	UARTReturn();

//     xputs(" ?Ax                   - get analog input");   // TODO
//     xputs(" !D=x                  - set digital output");  // TODO
//     xputs(" ?Dx                   - get digital input");// TODO
//     UARTReturn();

	xputs(" !L[0,1,2]             - LED off/on/blinking\n");
	xputs(" !U=x                  - set baud rate to x\n");
	xputs(" !U[0,1,2]             - UART echo mode (none, cmd-reply, all)\n");
	UARTReturn();

	xputs(" !S[+/-],b,p           - enable/disable sensors streaming, ??S to show options\n");
	xputs(" ?Sb                   - get sensor readouts according to bitmap b\n");
	xputs(" ??S                   - bitmap b options\n");
	UARTReturn();

//     xputs(" !A=[0-1023]           - set (internal) analog output");  // TODO (only useful with sleep mode) --- in fact not useful, please remove
//     xputs(" S[=x]                 - enter sleep mode (with wake-up threshold specified by x [0-1023]\n");    // TODO
	xputs(" R                     - reset board\n");
	xputs(" P                     - enter reprogramming mode\n");
	UARTReturn();

	xputs(" !M+/-                 - enable/disable motor driver\n");
	xputs(" !MP[0,1]=x            - set motor PWM period in microseconds\n");
	xputs(" !M[0,1]=[%]x          - set motor duty width in microseconds [% 0..100]\n");
#if USE_MINIROB
	xputs(" !MV[0,1]=[0-100]      - set motor velocity (internal P-controller for PushBot)\n");
#endif
	xputs(" !MD[0,1]=[%]          - set motor duty width, slow decay [% 0..100]\n");
#if USE_MINIROB
	xputs(" !MVD[0,1]=x           - set motor duty velocity, slow decay\n");
#endif
	UARTReturn();

	xputs(" !P[A,B,C]=x           - set timer base period in microseconds\n");
	xputs(" !P[A,B,C][0,1]=[%]x   - set timer channel width in microseconds [% 0..100]\n");
	UARTReturn();

	xputs(" !T+/-                 - enable/disable Real Time Clock (RTC)\n");
	xputs(" !Tyyyy-mm-dd hh:mm:ss - set RTC time\n");
	xputs(" ?T                    - get RTC time\n");
	UARTReturn();

	xputs(" ??                    - display (this) help\n");
	UARTReturn();
}

static inline void UARTShowEventDataOptions(void) {
	xputs("List of available event data formats:\n");
	xputs(" !E0   - 2 bytes per event, binary: 1yyyyyyy.pxxxxxxx (default)\n");
	xputs(" !E1   - 3..5 bytes per event, 1..3 bytes delta-timestamp (7bits each)\n");
	xputs(" !E2   - 4 bytes per event (as !E0 followed by 16bit timestamp)\n");
	xputs(" !E3   - 5 bytes per event (as !E0 followed by 24bit timestamp)\n");
	xputs(" !E4   - 6 bytes per event (as !E0 followed by 32bit timestamp)\n");
	UARTReturn();
	xputs(" Every timestamp has 1us resolution\n");
	UARTReturn();
}

static inline void UARTShowSensorOptions(void) {
	xputs("Bitlist for available sensors:\n");
	xputs(" Bit Name     # Values  Description\n");
	xputs(" 0   BATTERY         1  raw battery voltage level\n");
	xputs(" 1   ADC_CHANNEL0    1  raw ADC reading from pin 2\n");
	xputs(" 2   ADC_CHANNEL1    1  raw ADC reading from pin 3\n");
	xputs(" 3   ADC_CHANNEL2    1  raw ADC reading from pin 4\n");
	xputs(" 4   ADC_CHANNEL3    1  raw ADC reading from pin 5\n");
	xputs(" 5   ADC_CHANNEL4    1  raw ADC reading from pin 6\n");
	xputs(" 6   ADC_CHANNEL5    1  raw ADC reading from pin 7\n");
#if USE_IMU_DATA
	xputs(" 7   GYROMETER       3  raw gyroscope data for 3 axis\n");
	xputs(" 8   ACCELEROMETER   3  raw accelerometer data for 3 axis\n");
	xputs(" 9   COMPASS         3  raw magnetic values for 3 axis\n");
	xputs(" 10  TEMPERATURE     1  computed values from the temperature sensor\n");
	xputs(" 11  QUARTERNION     4  raw values from the IMU DMP\n");
#endif
	xputs(" 12  PWM_SIG         2  currently set PWM duty cycle for all 2 motors\n");
	xputs(" 13  MOTOR_CURRENTS  2  motor currents from the motor driver\n");
	xputs(" 14  EVENTS_RATE     1  Event rate per second\n");
#if USE_SDCARD
	xputs(" 15  SDCARD_RATE     1  Bytes written per second\n");
#endif
#if USE_MINIROB
	xputs(" 24  MOTOR_SENSORS   2  wheel tick counter\n");
#endif
	UARTReturn();
}
// *****************************************************************************
static uint32_t parseUInt32(unsigned char **c) {
	uint32_t ul = 0;
	while (((**c) >= '0') && ((**c) <= '9')) {
		ul = 10 * ul;
		ul += ((**c) - '0');
		(*(c))++;
	}
	return (ul);
}

static int32_t parseInt32(unsigned char **c) {
	if ((**c) == '-') {
		(*(c))++;
		return (-1 * ((int32_t) parseUInt32(c)));
	}
	if ((**c) == '+') {
		(*(c))++;
	}
	return ((int32_t) parseUInt32(c));
}

// *****************************************************************************
// * ** parseGetCommand ** */
// *****************************************************************************
static void UARTParseGetCommand(void) {

	switch (commandLine[1]) {

	case 'B':
	case 'b': {	   									// request bias value
		unsigned char *c;
		int32_t biasID;

		c = commandLine + 2;				// send bias value as decimal value
		if ((*c == 'A') || (*c == 'a')) {
			for (biasID = 0; biasID < 12; biasID++) {
				xprintf("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
			}
			break;
		}

		biasID = parseUInt32(&c);
		xprintf("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
		break;
	}

	case 'E':
	case 'e':
		xprintf("-E%d\n", eDVSDataFormat);
		break;
	case 'S':
	case 's': {
		unsigned char *c = commandLine + 2;
		getSensorsOutput(parseUInt32(&c));
		break;
	}
	case 'T':
	case 't':
		xprintf("-T%04d-%02d-%02d %02d:%02d:%02d\n", Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_YEAR),
				Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_MONTH), Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_DAYOFMONTH),
				Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_HOUR), Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_MINUTE),
				Chip_RTC_GetTime(LPC_RTC, RTC_TIMETYPE_SECOND));
		break;
	case '?':
		if (((commandLine[2]) == 'e') || ((commandLine[2]) == 'E')) {
			UARTShowEventDataOptions();
			break;
		}
		if (((commandLine[2]) == 's') || ((commandLine[2]) == 'S')) {
			UARTShowSensorOptions();
			break;
		}
		UARTShowUsage();
		break;

	default:
		xputs("Get: parsing error\n");
	}
	return;
}

// *****************************************************************************
// * ** parseSetCommand ** */
// *****************************************************************************
static void UARTParseSetCommand(void) {
	switch (commandLine[1]) {
	case 'A':
	case 'a': {
		unsigned char *c = commandLine + 2;
		if (*c == '=') {
			c++;
		}
		uint32_t newDacValue = parseUInt32(&c);
		if (newDacValue > 0x3FF) {
			xputs("Analog output should be between [0-1023]\n");
			break;
		}
		Chip_DAC_UpdateValue(LPC_DAC, newDacValue);
		break;
	}

	case 'B':
	case 'b': {
		unsigned char *c;
		long biasID, biasValue;

		if ((commandLine[2] == 'F') || (commandLine[2] == 'f')) {				// flush bias values to DVS chip
			if ((enableEventSending == 0) && (enableUARTecho > 1)) {
				xputs("-BF\n");
			}
			DVS128BiasFlush(1);
			break;
		}

		if ((commandLine[2] == 'D') || (commandLine[2] == 'd')) {				// load and flush default bias set
			if ((commandLine[3] >= '0') && (commandLine[3] <= '5')) {
				if ((enableEventSending == 0) && (enableUARTecho > 1)) {
					xprintf("-BD%c\n", commandLine[3]);
				}
				DVS128BiasLoadDefaultSet(commandLine[3] - '0');
				DVS128BiasFlush(1);
			} else {
				xputs("Select default bias set: parsing error\n");
			}
			break;
		}

		c = commandLine + 2;
		biasID = parseUInt32(&c);
		c++;
		biasValue = parseUInt32(&c);
		DVS128BiasSet(biasID, biasValue);
		if ((enableEventSending == 0) && (enableUARTecho > 1)) {
			xprintf("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
		}
		break;
	}

	case 'E':
	case 'e': {
		unsigned char *c = commandLine + 2;
		if ((*c == 't') || (*c == 'T')) { // set new event time
			c++;
			if ((*c == 's') || (*c == 'S')) { // set to clk-slave (use external pin CAP1 instead of internal clock)
				eDVSMode = EDVS_MODE_SLAVE;
				Chip_TIMER_Disable(LPC_TIMER1); //   disable Timer/Counter 1
				timerDelayUs(10); //Wait for any events that are being placed in the buffer
				events.eventBufferReadPointer = events.eventBufferWritePointer; //clearing the buffer
				Chip_TIMER_PrescaleSet(LPC_TIMER1, 0);	// prescaler: run at 192Mhz to check for input
				Chip_SCU_PinMuxSet(SYNCHRONIZATION_PORT, SYNCHRONIZATION_PIN, SCU_PINIO_FAST | FUNC3);
				//Select the capture input pin in the Global Input Multiplexer Array
				LPC_GIMA->CAP0_IN[1][0] = (uint32_t) (0x0 << 4);

				Chip_TIMER_CaptureRisingEdgeEnable(LPC_TIMER1, SYNCHRONIZATION_CHANNEL);
				Chip_TIMER_CaptureFallingEdgeEnable(LPC_TIMER1, SYNCHRONIZATION_CHANNEL);
				Chip_TIMER_CaptureDisableInt(LPC_TIMER1, SYNCHRONIZATION_CHANNEL);
				Chip_TIMER_TIMER_SetCountClockSrc(LPC_TIMER1, TIMER_CAPSRC_BOTH_CAPN, SYNCHRONIZATION_CHANNEL);
				Chip_TIMER_Reset(LPC_TIMER1);
				Chip_TIMER_Enable(LPC_TIMER1);
				xputs("-ETS\n");
				break;
			} else if ((*c == 'm') || (*c == 'M')) { // enable PWM2 (P0.7) to serve as clock for others
				c++;
				if (*c == '0') {
					eDVSMode = EDVS_MODE_MASTER_ARMED;
					Chip_TIMER_Init(LPC_TIMER3);
					Chip_TIMER_PrescaleSet(LPC_TIMER3, 95); //192/(95+1)=2 Mhz
					Chip_TIMER_ResetOnMatchEnable(LPC_TIMER3, 1);
					Chip_TIMER_StopOnMatchDisable(LPC_TIMER3, 1);
					Chip_TIMER_MatchDisableInt(LPC_TIMER3, 1);
					Chip_TIMER_SetMatch(LPC_TIMER3, 1, 1); // enable this output channel
					Chip_TIMER_ExtMatchControlSet(LPC_TIMER3, 0, TIMER_EXTMATCH_CLEAR, 1);
					Chip_SCU_PinMuxSet(SYNCHRONIZATION_PORT, SYNCHRONIZATION_PIN, SCU_PINIO_FAST | FUNC6);
					Chip_TIMER_Enable(LPC_TIMER3);
					Chip_TIMER_Enable(LPC_TIMER1); // Restart capturing
					xputs("-ETM0\n");
				} else {
					eDVSMode = EDVS_MODE_MASTER_RUNNING;
					Chip_TIMER_Disable(LPC_TIMER3);
					Chip_TIMER_ExtMatchControlSet(LPC_TIMER3, 0, TIMER_EXTMATCH_TOGGLE, 1);
					Chip_SCU_PinMuxSet(SYNCHRONIZATION_PORT, SYNCHRONIZATION_PIN, SCU_PINIO_FAST | FUNC6);
					Chip_TIMER_Disable(LPC_TIMER1); //   disable Timer/Counter 1
					timerDelayUs(10); //Wait for any events that are being placed in the buffer
					events.eventBufferReadPointer = events.eventBufferWritePointer;
					Chip_TIMER_Reset(LPC_TIMER1);
					Chip_TIMER_Enable(LPC_TIMER3); //Starts the clock out
					Chip_TIMER_Enable(LPC_TIMER1); // Restart capturing
					xputs("-ETM+\n");
				}
				break;
			} else if ((*c == 'i') || (*c == 'I')) {
				//Returning to retina mode.
				switch (eDVSMode) {
				case EDVS_MODE_SLAVE:
					Chip_RGU_TriggerReset(RGU_TIMER1_RST); // reset timer 1
					Chip_TIMER_DeInit(LPC_TIMER1);
					DVS128InitTimer();
					/* Fall-through*/
				case EDVS_MODE_MASTER_ARMED:
				case EDVS_MODE_MASTER_RUNNING:
					eDVSMode = EDVS_MODE_INTERNAL;
					PWMSetPeriod(0, 0); //calling this function will reset Timer3 normal operation
					break;
				case EDVS_MODE_INTERNAL: //do nothing
				default:
					break;
				}
				xputs("-ETI\n");
				break;
			} else {
				c++;
				LPC_TIMER1->TC = parseUInt32(&c);
				break;
			}
		}
#if USE_SDCARD
		if ((*c == 'R') || (*c == 'r')) {
			c++;
			if (*c == '-') {
				setSDCardRecord(DISABLE);
				break;
			} else if (*c == '+') {
				setSDCardRecord(ENABLE);
				break;
			}
		}
#endif
		if ((*c >= '0') && (*c <= '4')) {
			eDVSDataFormat = ((*c) - '0');
			if ((enableEventSending == 0) && (enableUARTecho > 1)) {
				xprintf("-E%d\n", eDVSDataFormat);
			}
			break;
		}

		xputs("Set: parsing error\n");
		break;
	}

	case 'L':
	case 'l': {
		unsigned char *c = commandLine + 2;
		if (*c == '0') {
			LED0SetBlinking(DISABLE);
			LED0SetOff();
			break;
		} else if (*c == '1') {
			LED0SetBlinking(DISABLE);
			LED0SetOn();
			break;
		} else if (*c == '2') {
			LED0SetBlinking(ENABLE);
			break;
		}
		xputs("Set: parsing error\n");
		break;
	}

	case 'M':
	case 'm': {
		unsigned char *c = commandLine + 2;
		uint32_t motorId = 0;
		if (*c == '+') {
			enableMotorDriver(TRUE);
			break;
		} else if (*c == '-') {
			enableMotorDriver(FALSE);
			break;
		}
		if ((*c == 'D') || (*c == 'd')) {
			c++;
			motorId = parseUInt32(&c);
			c++;
			if (*c == '%') {
				c++;
				if (updateMotorDutyCycleDecay(motorId, parseInt32(&c))) {
					xputs("Error setting motor speed\n");
					break;
				}
			} else {
				if (updateMotorWidthDecay(motorId, parseInt32(&c))) {
					xputs("Error setting motor speed\n");
					break;
				}

			}
			break;
		}
#if USE_MINIROB
		if ((*c == 'V') || (*c == 'v')) {
			c++;
			if ((*c == 'D') || (*c == 'd')) {
				c++;
				motorId = parseUInt32(&c);
				c++;
				if (updateMotorVelocityDecay(motorId, parseInt32(&c))) {
					xputs("Error setting motor speed\n");
					break;
				}
			}
			motorId = parseUInt32(&c);
			c++;
			if (updateMotorVelocity(motorId, parseInt32(&c))) {
				xputs("Error setting motor speed\n");
			}
			break;
		}
#endif
		if ((*c == 'P') || (*c == 'p')) {
			c++;
			motorId = parseUInt32(&c);
			c++;
			if (updateMotorPWMPeriod(motorId, parseUInt32(&c))) {
				xputs("Error setting motor PWM\n");
			}
			break;
		}
		motorId = parseUInt32(&c);
		c++;
		if (updateMotorMode(motorId, DIRECT_MODE)) {
			xputs("Error setting motor mode\n");
			break;
		}
		if (*c == '%') {
			c++;
			if (updateMotorDutyCycle(motorId, parseInt32(&c))) {
				xputs("Error setting motor speed\n");
				break;
			}
		} else {
			if (updateMotorWidth(motorId, parseInt32(&c))) {
				xputs("Error setting motor width\n");
			}
		}

		break;
	}

	case 'P':
	case 'p': {
		unsigned char *c = commandLine + 2;
		if (((*c >= 'A') && (*c <= 'C')) || ((*c >= 'a') && (*c <= 'c'))) {
			uint8_t channel = *c - (*c >= 'a' ? 'a' : 'A');
			c++;
			if ((*c == '0') || (*c == '1')) {
				uint8_t output = *c - '0';
				c += 2;
				if (*c == '%') {
					c++;
					if (PWMSetDutyCycle(channel, output, parseUInt32(&c))) {
						xputs("Error setting PWM dutycycle\n");
					}
				} else if (PWMSetWidth(channel, output, parseUInt32(&c))) {
					xputs("Error setting PWM width\n");
				}
			} else {
				c++;
				if (PWMSetPeriod(channel, parseUInt32(&c))) {
					xputs("Error setting PWM frequency\n");
				}
			}
			break;
		} else {
			xputs("Channel not recognized\n");
		}
		break;
	}

	case 'S':
	case 's': {
		unsigned char *c = commandLine + 2;
		uint8_t flag = *c == '+' ? ENABLE : DISABLE;
		c += 2;
		uint32_t mask = parseUInt32(&c), period = 0;
		if (mask == 0 && !flag && (commandLinePointer == 3)) {
			mask = 0xFFFFFFFF;
		}
		c++;
		if (flag) {
			period = parseUInt32(&c);
		}
		enableSensors(mask, flag, period);
		break;
	}
	case 'T':
	case 't': {

		unsigned char *c = commandLine + 2;
		if (*c == '+') {
			Chip_RTC_Init(LPC_RTC);
			Chip_RTC_Enable(LPC_RTC, ENABLE);
			Chip_RTC_SetFullTime(LPC_RTC, &buildTime);
			xputs("-T+\n");
			break;
		} else if (*c == '-') {
			Chip_RTC_Enable(LPC_RTC, DISABLE);
			Chip_RTC_DeInit(LPC_RTC);
			xputs("-T-\n");
			break;
		}
		if (commandLinePointer < TIME_DATE_COM_SIZE + 2) {
			xputs("Wrong format\n");
			break;
		}
		if (!Chip_RTC_Clock_Running()) {
			xputs("RTC not enabled\n");
			break;
		}
		RTC_TIME_T time;
		time.time[RTC_TIMETYPE_DAYOFWEEK] = 0;
		time.time[RTC_TIMETYPE_DAYOFYEAR] = 1;
		time.time[RTC_TIMETYPE_YEAR] = parseUInt32(&c);
		c++;
		time.time[RTC_TIMETYPE_MONTH] = parseUInt32(&c);
		c++;
		time.time[RTC_TIMETYPE_DAYOFMONTH] = parseUInt32(&c);
		c++;
		time.time[RTC_TIMETYPE_HOUR] = parseUInt32(&c);
		c++;
		time.time[RTC_TIMETYPE_MINUTE] = parseUInt32(&c);
		c++;
		time.time[RTC_TIMETYPE_SECOND] = parseUInt32(&c);
		Chip_RTC_SetFullTime(LPC_RTC, &time);
		break;
	}

	case 'U':
	case 'u': {
		unsigned char *c;
		long baudRate;
		c = commandLine + 2;
		if (((*c) >= '0') && ((*c) <= '2')) {
			enableUARTecho = ((*c) - '0');
			break;
		}
		c++;
		baudRate = parseUInt32(&c);
		while ((LPC_UART->LSR & UART_LSR_TEMT) == 0) {
		};		   // wait for UART to finish data transfer
		if ((enableEventSending == 0) && (enableUARTecho > 1)) {
			xprintf("Switching Baud Rate to %d Baud!\n", baudRate);
		}
		if (Chip_UART_SetBaudFDR(LPC_UART, baudRate) == 0) {
			if ((enableEventSending == 0) && (enableUARTecho > 1)) {
				xprintf("Failed to switch Baud Rate to %d Baud!\n", baudRate);
			}
		}
		break;
	}

	default:
		xputs("Set: parsing error\n");
	}
	return;
}

// *****************************************************************************
// * ** parseRS232CommandLine ** */
// *****************************************************************************
static void parseRS232CommandLine(void) {

	switch (commandLine[0]) {
	case '?':
		UARTParseGetCommand();
		break;
	case '!':
		UARTParseSetCommand();
		break;

	case 'P':
	case 'p':
		UARTInit(LPC_USART0, 9600);
		enterReprogrammingMode();
		break;
	case 'R':
	case 'r':
		resetDevice();
		break;
	case 'E':
	case 'e':
		if (commandLine[1] == '+') {
			DVS128FetchEventsEnable(TRUE);
		} else {
			DVS128FetchEventsEnable(FALSE);
		}
		break;

	case 'S':
	case 's': {
		//
		break;
	}

	default:
		xputs("?\n");
	}
	return;
}

// *****************************************************************************
// * ** RS232ParseNewChar ** */
// *****************************************************************************
void UART0ParseNewChar(unsigned char newChar) {

	if (freeSpaceForReception(&uart) < 16) {
		Chip_GPIO_SetPinOutHigh(LPC_GPIO_PORT, RTS0_GPIO_PORT,
		RTS0_GPIO_PIN); //Signal busy to the DTE
	} else {
		Chip_GPIO_SetPinOutLow(LPC_GPIO_PORT, RTS0_GPIO_PORT,
		RTS0_GPIO_PIN); //Signal ready to the DTE
	}

	switch (newChar) {
	case 8:			// backspace
		if (commandLinePointer > 0) {
			commandLinePointer--;
			if ((enableEventSending == 0) && (enableUARTecho)) {
				xprintf("%c %c", 8, 8);
			}
		}
		break;

	case 10:
	case 13:
		if ((enableEventSending == 0) && (enableUARTecho)) {
			UARTReturn();
		}
		if (commandLinePointer > 0) {
			commandLine[commandLinePointer] = 0;
			parseRS232CommandLine();
			commandLinePointer = 0;
		}
		break;

	default:
		if (newChar & 0x80) {
			return; //only accept ASCII
		}
		if (commandLinePointer < UART_COMMAND_LINE_MAX_LENGTH - 1) {
			if ((enableEventSending == 0) && (enableUARTecho)) {
				xputc(newChar);	  		   	// echo to indicate char arrived
			}
			commandLine[commandLinePointer++] = newChar;
		} else {
			commandLinePointer = 0;
			commandLine[commandLinePointer++] = newChar;
		}
	}  // end of switch

}  // end of rs232ParseNewChar

