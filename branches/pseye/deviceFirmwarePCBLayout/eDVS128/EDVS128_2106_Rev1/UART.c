#include "EDVS128_2106.h"

// *****************************************************************************
extern unsigned long eventBufferWritePointer, eventBufferReadPointer;
// *****************************************************************************
extern unsigned char TXBuffer[32];	   // this is the small buffer from mainloop
extern unsigned long TXBufferIndex;

extern unsigned long transmitEventRateEnable;
extern unsigned long enableEventSending;

extern unsigned long enableAutomaticEventRateControl;
extern unsigned long requestedEventRate;

extern unsigned long eDVSDataFormat;

#ifdef INCLUDE_TRACK_HF_LED
extern unsigned long transmitTrackHFLED;
#endif
#ifdef INCLUDE_PIXEL_CUTOUT_REGION
extern unsigned long pixelCutoutMinX, pixelCutoutMaxX, pixelCutoutMinY, pixelCutoutMaxY;
#endif

unsigned char commandLine[UART_COMMAND_LINE_MAX_LENGTH];
unsigned long commandLinePointer;

// *****************************************************************************  
#define UARTReturn()	   {putchar('\n');}

// *****************************************************************************
int putchar(char charToSend) {
  while (FGPIO_IOPIN & PIN_UART0_RTS) {  // wait while UART buffer is full
  };
  while ((UART0_LSR & BIT(5))==0) {	  	 // wait until space in UART FIFO
  };
  UART0_THR = charToSend;
  return(0);
}


// *****************************************************************************
void UART0SetBaudRate(unsigned long baudRate) {
  UART0_FDR = 0x10;							// clear fractional baud rate
  UART0_LCR = 0x83;							// Enable the divisor
  UART0_DLM = 0x00;							// Divisor latch MSB (for baud rates < 4800) 

  switch (baudRate) {
#if PLL_CLOCK == 112						   // all baud rates calculated for 112MHz
	case ((unsigned long)  460800): UART0_DLL = (0x0C); UART0_FDR = (((0x0F)<<4) | 0x04); break;
	case ((unsigned long)  500000): UART0_DLL = (0x0E); break;
	case ((unsigned long)  921600): UART0_DLL = (0x06); UART0_FDR = (((0x0F)<<4) | 0x04); break;
	case ((unsigned long)       1):
	case ((unsigned long) 1000000): UART0_DLL = (0x07); break;
	case ((unsigned long)       2):
	case ((unsigned long) 2000000): UART0_DLL = (0x03); UART0_FDR = (((0x06)<<4) | 0x01); break;
#endif

#if PLL_CLOCK == 96						   // all baud rates calculated for 96MHz
	case ((unsigned long)  460800): UART0_DLL = (0x0D); break;
	case ((unsigned long)  500000): UART0_DLL = (0x0C); break;
	case ((unsigned long)  921600): UART0_DLL = (0x06); UART0_FDR = (((0x0C)<<4) | 0x01); break;
	case ((unsigned long)       1):
	case ((unsigned long) 1000000): UART0_DLL = (0x06); break;
	case ((unsigned long)       2):
	case ((unsigned long) 2000000): UART0_DLL = (0x03); break;
	case ((unsigned long)       3):
	case ((unsigned long) 3000000): UART0_DLL = (0x02); break;
#endif

#if PLL_CLOCK == 80						   // all baud rates calculated for 80MHz
	case ((unsigned long)  460800): UART0_DLL = (0x08); UART0_FDR = (((0x0E)<<4) | 0x05); break;
	case ((unsigned long)  500000): UART0_DLL = (0x0A); break;
	case ((unsigned long)  921600): UART0_DLL = (0x04); UART0_FDR = (((0x0E)<<4) | 0x05); break;
	case ((unsigned long)       1):
	case ((unsigned long) 1000000): UART0_DLL = (0x05); break;
#endif

#if PLL_CLOCK == 64			  			   // all baud rates calculated for 64MHz
	case ((unsigned long)   19200): UART0_DLL = (0x7D); UART0_FDR = (((0x03)<<4) | 0x02); break;
    case ((unsigned long)   31250): UART0_DLL = (0x80); break;
	case ((unsigned long)   38400): UART0_DLL = (0x32); UART0_FDR = (((0x0C)<<4) | 0x0D); break;
	case ((unsigned long)   57600): UART0_DLL = (0x36); UART0_FDR = (((0x07)<<4) | 0x02); break;
    case ((unsigned long)   62500): UART0_DLL = (0x40); break;
	case ((unsigned long)  115200): UART0_DLL = (0x1B); UART0_FDR = (((0x07)<<4) | 0x02); break;
	case ((unsigned long)  125000): UART0_DLL = (0x20);	break;
	case ((unsigned long)  230400): UART0_DLL = (0x09); UART0_FDR = (((0x0E)<<4) | 0x0D); break;
    case ((unsigned long)  250000): UART0_DLL = (0x10); break;
	case ((unsigned long)  460800): UART0_DLL = (0x08); UART0_FDR = (((0x0C)<<4) | 0x01); break;
	case ((unsigned long)  500000): UART0_DLL = (0x08); break;
	case ((unsigned long)  921600): UART0_DLL = (0x04); UART0_FDR = (((0x0C)<<4) | 0x01); break;
	case ((unsigned long)       1):
	case ((unsigned long) 1000000): UART0_DLL = (0x04); break;
	case ((unsigned long) 1500000): UART0_DLL = (0x02); UART0_FDR = (((0x03)<<4) | 0x01); break;
	case ((unsigned long) 1843200): UART0_DLL = (0x02); UART0_FDR = (((0x0C)<<4) | 0x01); break; //
	case ((unsigned long)       2):
	case ((unsigned long) 2000000): UART0_DLL = (0x02);	break;
	case ((unsigned long)       4):
	case ((unsigned long) 4000000): UART0_DLL = (0x01);	break;
#endif

#if PLL_CLOCK == 32			  			   // all baud rates calculated for 32MHz
	case ((unsigned long) 1000000): UART0_DLL = (0x02); break;
	case ((unsigned long) 2000000): UART0_DLL = (0x01);	break;
#endif

	default:
  			UART0_LCR = 0x03;				// Close divisor before printing!
			printf("unknown/unsupported baud rate!\n");
			return;
  }

  UART0_LCR = 0x03;							// Close divisor
}

// *****************************************************************************
void UARTInit(void) {

  UART0SetBaudRate(BAUD_RATE_DEFAULT);

  UART0_IER = 0x00;							// disable RS232 interrupts
  UART0_FCR = 0x01;							// enable the fifos
  UART0_FCR = 0x01 | 0x06;					// Reset FIFOs

  UART0_TER = 0x80;							// Enable Transmitter (default)

  PCB_PINSEL0 |= BIT(2) | BIT(0);	  		// enable TxD0, RxD0 output pins

// *****************************************************************************  
  FGPIO_IOCLR  = PIN_UART0_CTS;				// set CTS pin to permanent low
  FGPIO_IODIR |= PIN_UART0_CTS;

  FGPIO_IODIR &= ~(PIN_UART0_RTS);			// set RTS to input

// *****************************************************************************  
  commandLine[0] = 0;
  commandLinePointer = 0;
}


// *****************************************************************************  
void UARTShowVersion(void) {
  UARTReturn();
  printf("EDVS128_LPC2106, V");
  printf(SOFTWARE_VERSION);
  printf(": ");
  printf(__DATE__);
  printf(", ");
  printf(__TIME__);
  UARTReturn();

  printf("System Clock: %2dMHz / %d -> %dns event time resolution",
  				 			   	 	   			  PLL_CLOCK,
												  (1<<TIMESTAMP_SHIFTBITS),
  				 			   	 	   			  1000*(1<<TIMESTAMP_SHIFTBITS) / (PLL_CLOCK));
  UARTReturn();

  printf("Modules: ");

#ifdef TIME_OPTIMIZED
  printf(" TIME_OPTIMIZED");
#endif

#ifdef INCLUDE_TRACK_HF_LED
  printf(" TRACK_HF_LED");
#endif

#ifdef INCLUDE_PIXEL_CUTOUT_REGION
  printf(" PIXEL_CUTOUT_REGION");
#endif

#ifdef INCLUDE_PWM246
  printf(" PWM246-");
  #ifdef INCLUDE_PWM246_ENABLE_PWM2_OUT
    printf("2");
  #endif
  #ifdef INCLUDE_PWM246_ENABLE_PWM4_OUT
    printf("4");
  #endif
  #ifdef INCLUDE_PWM246_ENABLE_PWM6_OUT
    printf("6");
  #endif
#endif

#ifdef USE_ALTERNATE_RTS_CTS
  printf(" ALT-RTS/CTS");
#endif

#ifdef INCLUDE_MARK_BUFFEROVERFLOW
  printf(" MARK_BUFFEROVERFLOW");
#endif

  UARTReturn();
}

// *****************************************************************************  
void UARTShowUsage(void) {
  
  UARTShowVersion();

  UARTReturn();
  printf("Supported Commands:\n");
  UARTReturn();

  printf(" E+/-       - enable/disable event sending\n");
  printf(" !Ex        - specify event data format, ??E to list options\n");
#ifdef INCLUDE_PIXEL_CUTOUT_REGION
  printf(" !Cxl,yl<,xr,yr> - specify a rectangular cutout region\n");
#endif
  UARTReturn();

  printf(" !Bx=y      - set bias register x[0..11] to value y[0..0xFFFFFF]\n");
  printf(" !BF        - send bias settings to DVS\n");
  printf(" !BDx       - select and flush default bias set (default: set 0)\n");
  printf(" ?Bx        - get bias register x current value\n");
  printf(" ?B#x       - get bias register x encoded within event stream\n");
  UARTReturn();

  
  
  printf(" !R+/-      - transmit event rate on/off\n");
#ifdef INCLUDE_TRACK_HF_LED
  printf(" !T+/-      - enable/disable tracking of high-frequency blinkind LEDs\n");
#ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
  printf(" !TS+/-     - enable/disable servo following of tracking target\n");
#endif
  UARTReturn();
#endif
  
  printf(" 0,1,2      - LED off/on/blinking\n");
  printf(" !S=x       - set baudrate to x\n");
#ifdef INCLUDE_PWM246
  printf(" !PWMC=x    - set PWM cycle length to x us\n");
  printf(" !PWMS<x>=y - set PWM signal x [0..2] length to y us\n");
#endif
  UARTReturn();

  printf(" R          - reset board\n");
  printf(" P          - enter reprogramming mode\n");
  UARTReturn();

  printf(" ??         - display help\n");
  UARTReturn();
}

void UARTShowEventDataOptions(void) {
  printf(" !E0   - 2 bytes per event binary 0yyyyyyy.pxxxxxxx (default)\n");
  printf(" !E1   - 4 bytes per event (as above followed by 16bit timestamp)\n");
  UARTReturn();

  printf(" !E10  - 3 bytes per event, 6bit encoded\n");
  printf(" !E11  - 6 bytes per event+timestamp, 6bit encoded \n");
  printf(" !E12  - 4 bytes per event, 6bit encoded; new-line\n");
  printf(" !E13  - 7 bytes per event+timestamp, 6bit encoded; new-line\n");
  UARTReturn();

  printf(" !E20  - 4 bytes per event, hex encoded\n");
  printf(" !E21  - 8 bytes per event+timestamp, hex encoded \n");
  printf(" !E22  - 5 bytes per event, hex encoded; new-line\n");
  printf(" !E23  - 8 bytes per event+timestamp, hex encoded; new-line\n");
  UARTReturn();

  printf(" !E30  - 10 bytes per event, ASCII <1p> <3y> <3x>; new-line\n");
  printf(" !E31  - 10 bytes per event+timestamp, ASCII <1p> <3y> <3x> <5ts>; new-line\n");
}

// *****************************************************************************
unsigned long parseULong(char **c) {
  unsigned long ul=0;
  while (((**c)>='0') && ((**c)<='9')) {
    ul = 10*ul;
	ul += ((**c)-'0');
	(*(c))++;
  }
  return(ul);
}

// *****************************************************************************
// * ** parseGetCommand ** */
// *****************************************************************************
void UARTParseGetCommand(void) {

  switch (commandLine[1]) {

    case 'B':
	case 'b': {	   									 			// request bias value
	            unsigned char *c;
			    long biasID;
			    
				if (commandLine[2] == '#') {	   	// send bias value as encoded event
			      c = commandLine+3;
                  DVS128BiasTransmitBiasValue(parseULong(&c));
			      break;
			    }

			    c = commandLine+2;					// send bias value as deciman value
			    if ((*c == 'A') || (*c == 'a')) {
			      for (biasID=0; biasID<12; biasID++) {
			        printf ("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
			      }
				  break;
			    }
			   
			    biasID = parseULong(&c);
			    printf ("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
		        break;
		      }

#ifdef INCLUDE_PIXEL_CUTOUT_REGION
	case 'C':
	case 'c':
			  printf("-C%d,%d,%d,%d\n", pixelCutoutMinX, pixelCutoutMinY, pixelCutoutMaxX, pixelCutoutMaxY);
			  break;
#endif

	case 'E':
	case 'e':
	          printf("-E%d\n", eDVSDataFormat);
		 	  break;

#ifdef INCLUDE_PWM246
	case 'P':
	case 'p':
		 	  {
			    if ((commandLine[4] == 'C') || (commandLine[4] == 'c')) {
				  printf("-PWMC=%d\n", PWM246GetCycle());
				  break;
			    }
			    if ((commandLine[4] == 'S') || (commandLine[4] == 's')) {
			      printf("-PWMS=%d,%d,%d\n", PWM246GetSignal(0), PWM246GetSignal(1), PWM246GetSignal(2));
				  break;
			    }
			    printf("Get PWM246: parsing error\n");
			    break;
			  }
#endif

	case '?':
	          if (((commandLine[2]) == 'e') || ((commandLine[2]) == 'E')) {
			    UARTShowEventDataOptions();
			    break;
			  }
		 	  UARTShowUsage();
			  break;

	default:
			  printf("Get: parsing error\n");
  }
  return;
}

// *****************************************************************************
// * ** parseSetCommand ** */
// *****************************************************************************
void UARTParseSetCommand(void) {
  switch (commandLine[1]) {

	case 'B':
	case 'b': {
	            unsigned char *c;
			    long biasID, biasValue;

			    if ((commandLine[2] == 'F') || (commandLine[2] == 'f')) {	   	// flush bias values to DVS chip
                  if (enableEventSending==0) {
				    printf("-BF\n");
				  }
				  DVS128BiasFlush();
				  break;
				}

			    if ((commandLine[2] == 'D') || (commandLine[2] == 'd')) {	   	// load and flush default bias set
				  if ((commandLine[3]>'0') && (commandLine[3]<'9')) {
                    if (enableEventSending==0) {
				      printf("-BD%c\n", commandLine[3]);
				    }
					DVS128BiasLoadDefaultSet(commandLine[3]-'0');
					DVS128BiasFlush();
				  } else {
					printf("Select default bias set: parsing error\n");
				  }
				  break;
				}

				c = commandLine+2;
			    biasID = parseULong(&c);
			    c++;
			    biasValue = parseULong(&c);
			    DVS128BiasSet(biasID, biasValue);
			    if (enableEventSending==0) {
			      printf ("-B%d=%d\n", biasID, DVS128BiasGet(biasID));
			    }
			    break;
			  }

#ifdef INCLUDE_PIXEL_CUTOUT_REGION
	case 'C':
	case 'c':
		 	  {
			    long n;
			    n = sscanf(commandLine+2, "%ld,%ld,%ld,%ld", &pixelCutoutMinX, &pixelCutoutMinY, &pixelCutoutMaxX, &pixelCutoutMaxY);
			    if (n==2) { 		  	 	 // only two numbers specified --> assume we only want one pixel
			      pixelCutoutMaxX = pixelCutoutMinX;
			      pixelCutoutMaxY = pixelCutoutMinY;
			      printf("-C%d,%d,%d,%d\n", pixelCutoutMinX, pixelCutoutMinY, pixelCutoutMaxX, pixelCutoutMaxY);
			      break;
			    }
			    if (n==4) { 		  	 	 // correct parsing
			      printf("-C%d,%d,%d,%d\n", pixelCutoutMinX, pixelCutoutMinY, pixelCutoutMaxX, pixelCutoutMaxY);
			      break;
				}
				printf("Set pixel cutout: parsing error\n");
			    break;
			  }
#endif

	case 'E':
	case 'e': {
		 	    unsigned char *c;
			    c = commandLine+2;
			    if ((*c) == '=') c++;   		   		// skip '=' if entered
			    eDVSDataFormat = parseULong(&c);
			    printf("-E%d\n", eDVSDataFormat);
		 	    break;
			  }

#ifdef INCLUDE_PWM246
	case 'P':
	case 'p':
		 	  {
	            unsigned char *c;
				unsigned long id, l;
			    if (((commandLine[4]) == 'C') || ((commandLine[4]) == 'c')) {
			      c = commandLine+6;
			      l = parseULong(&c);
			   	  PWM246SetCycle(l);
			      if (enableEventSending==0) {
			   	    printf("-PWMC=%d\n", PWM246GetCycle());
				  }
				  break;
			    }
			    if (((commandLine[4]) == 'S') || ((commandLine[4]) == 's')) {
				  id = commandLine[5]-'0';
			      c = commandLine+7;
			      l = parseULong(&c);
				  PWM246SetSignal(id, l);
			      if (enableEventSending==0) {
			   	    printf("-PWMS%d=%d\n", id, PWM246GetSignal(id));
				  }
				  break;
				}
				printf("Set PWM246: parsing error\n");
			    break;
			 }
#endif

	case 'R':
	case 'r':
		 	  transmitEventRateEnable = (commandLine[2] == '+') ? 1 : 0;
			  break;

	case 'S':
	case 's': {
	            unsigned char *c;
			    long baudRate;
			    c = commandLine+3;
			    baudRate = parseULong(&c);
			    printf("Switching Baud Rate to %d Baud!\n", baudRate);
                while ((UART0_LSR & BIT(6))==0) {};		   // wait for UART to finish data transfer
			    UART0SetBaudRate(baudRate);
			    break;
			  }

#ifdef INCLUDE_TRACK_HF_LED
    case 'T':
    case 't':
#ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
		 	  if ((commandLine[2]=='s') || (commandLine[2]=='S')){
		 	    if (commandLine[3]=='0') {
			      EP_TrackHFLServoResetPosition();
				  printf ("-TS0\n");
				} else {
				  if (commandLine[3]=='+') {
			        EP_TrackHFLServoSetEnabled(TRUE);
				    printf ("-TS+\n");
			      } else {
			        EP_TrackHFLServoSetEnabled(FALSE);
				    printf ("-TS-\n");
				  }
				}
				break;
			  }
#endif
			  
		 	  if (commandLine[2]=='+') {
			    EP_TrackHFLSetOutputEnabled(TRUE);
				printf ("-T+\n");
			  } else {
			    EP_TrackHFLSetOutputEnabled(FALSE);
				printf ("-T-\n");
			  }
			  break;
#endif

	default:
			  printf("Set: parsing error\n");
  }
  return;
}

// *****************************************************************************
// * ** parseRS232CommandLine ** */
// *****************************************************************************
void parseRS232CommandLine(void) {

  switch (commandLine[0]) {
		case '?': UARTParseGetCommand();	break;
		case '!': UARTParseSetCommand();	break;

	    case 'P':
	    case 'p': enterReprogrammingMode();	break;
	    case 'R':
		case 'r': resetDevice();			break;

		case '0': LEDSetOff();      		break;
		case '1': LEDSetOn();       		break;
		case '2': LEDSetBlinking(); 		break;
		
		case 'E':
		case 'e':
			 	  if (commandLine[1] == '+') {
				    DVS128FetchEventsEnable(TRUE);
				  } else {
				    DVS128FetchEventsEnable(FALSE);
				  }
				  break;

	    default:
				  printf("?\n\r");
  }
  return;
}


// *****************************************************************************
// * ** RS232ParseNewChar ** */
// *****************************************************************************
void UARTParseNewChar(unsigned char newChar) {

  switch(newChar) {
	case 8:			// backspace
	  if (commandLinePointer > 0) {
	    commandLinePointer--;
          if (enableEventSending==0) {
		    printf("%c %c", 8, 8);
		  }
	  }
      break;

	case 10:
	case 13:
      if (enableEventSending==0) {
	    UARTReturn();
      }
      if (commandLinePointer > 0) {
        commandLine[commandLinePointer]=0;
        parseRS232CommandLine();
	    commandLinePointer=0;
      }
	  break;

	default:
      if (commandLinePointer < (UART_COMMAND_LINE_MAX_LENGTH-2)) {
        if (enableEventSending==0) {
          putchar(newChar);	  		   	// echo to indicate char arrived
        }
		commandLine[commandLinePointer] = newChar;
        commandLinePointer++;
      } else {
		long n;
		printf("Reached cmd line length, resetting into bootloader mode!\n");
		for (n=0; n<100; n++) {
		  delayMS(20);
		  if (UART0_LSR & 0x01) {				   // char arrived?
            newChar = UART0_RBR;
		  }
		}
		enterReprogrammingMode();
	  }
  }  // end of switch  
  
}  // end of rs232ParseNewChar


