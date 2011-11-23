#include "EDVS128_2106.h"

// *****************************************************************************
extern long ledState;	 			// 0:off, -1:on, -2:blinking, >0: timeOn

extern unsigned short eventBufferA[DVS_EVENTBUFFER_SIZE];		  // for event addresses
extern unsigned long  eventBufferT[DVS_EVENTBUFFER_SIZE];		  // for event time stamps
extern unsigned long  eventBufferWritePointer, eventBufferReadPointer;

extern unsigned long enableEventSending;

extern unsigned char commandLine[UART_COMMAND_LINE_MAX_LENGTH];
extern unsigned long commandLinePointer;

unsigned long transmitEventRateEnable;

unsigned char TXBuffer[256];							// events sending
unsigned long TXBufferIndex=0;

unsigned long eventCounterTotal, eventCounterOn, eventCounterOff;
unsigned long currentTimerValue,
		 	  nextTimer1msValue, nextTimer2msValue, nextTimer10msValue, nextTimer100msValue, nextTimer1000msValue;

unsigned char dataForTransmission[16];

unsigned long eDVSDataFormat;
unsigned char hexLookupTable[16];

#ifdef INCLUDE_TRACK_HF_LED
  extern unsigned short tsMemory[128][128];
  extern unsigned long trackingHFLCenterX[4], trackingHFLCenterY[4], trackingHFLCenterC[4];
  extern unsigned long trackingHFLDesiredTimeDiff[4];
  extern unsigned long transmitTrackHFLED;
  #ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT
    extern unsigned long TrackHFL_PWM0, TrackHFL_PWM1;
    extern unsigned long EP_TrackHFP_ServoEnabled;
  #endif
#endif

#ifdef INCLUDE_PIXEL_CUTOUT_REGION
  extern unsigned long pixelCutoutMinX, pixelCutoutMaxX, pixelCutoutMinY, pixelCutoutMaxY;
#endif

// *****************************************************************************
// *****************************************************************************
void mainloopInit(void) {
  unsigned long n;

  eventCounterTotal = 0;
  eventCounterOn = 0;
  eventCounterOff = 0;

  transmitEventRateEnable = 0;			// default: disable automatic EPS control

  eDVSDataFormat = EDVS_DATA_FORMAT_DEFAULT;

  for (n=0; n<10; n++) { hexLookupTable[n]   ='0'+n; }
  for (n=0; n< 6; n++) { hexLookupTable[n+10]='A'+n; }
}

// *****************************************************************************
#pragma ramfunc transmitSpecialData
void transmitSpecialData(unsigned long l) {
  unsigned long n;

  for (n=(TXBufferIndex+l); n>l; n--) {		  // shift data "up"
    TXBuffer[n] = TXBuffer[n-(l+1)];
  }

  for (n=0; n<l; n++) {				  		  // fill data in
    TXBuffer[n] = dataForTransmission[n];
  }
  TXBuffer[l] = 0x80 + (l&0x0F);			  // 0x8y: start of special sequence of length y

  TXBufferIndex += (l+1);
}

// *****************************************************************************
#pragma ramfunc swapByteOrderInMemory
void swapByteOrderInMemory(char *c, unsigned long l) {
  char *cr;
  unsigned char tmp;

  cr=c+l-1;						// point to end of sequence

  while (c<cr) {
    tmp = *c;
	*c = *cr;
	*cr = tmp;
    c++;
	cr--;
  }

}
	  
// *****************************************************************************
// *****************************************************************************
#pragma ramfunc mainloop
void mainloop(void) {
  unsigned long newChar;
  unsigned long newDVSEvent;
  unsigned long lastDVSEventTime, newDVSEventTime;
  unsigned long eventA, eventT;

  nextTimer1msValue = T0_TC + 100; 		 	   // start reporting after 1000 ms
  nextTimer2msValue = nextTimer1msValue; 	   // same time here
  nextTimer10msValue = nextTimer1msValue; 	   // same time here
  nextTimer100msValue = nextTimer1msValue; 	   // same time here
  nextTimer1000msValue = nextTimer1msValue;    // same time here

// *****************************************************************************
//    Main Loop Start
// *****************************************************************************
MLStart:

// *****************************************************************************
//    LEDIterate();
// *****************************************************************************
#ifndef TIME_OPTIMIZED
  if (ledState) {
    if (ledState > 0) {
      ledState--;
	  if (ledState == 1) {
	    ledState = 0;
	    LED_OFF();
	  }
    } else {
      ledState++;
	  if (ledState == 0) {
	    LED_TOGGLE();
  	    ledState = ((long) -50000);
      }
    }
  }
#endif  // #ifndef TIME_OPTIMIZED

// *****************************************************************************
//    UARTIterate();
// *****************************************************************************
  if (UART0_LSR & 0x01) {				   // char arrived?
    newChar = UART0_RBR;
    UARTParseNewChar(newChar);
  }

// *****************************************************************************
//    fetchEventsIterate();
// *****************************************************************************
DVSFetchNewEvents:
  newDVSEventTime = T1_CR0;

  if (lastDVSEventTime != newDVSEventTime) {

    newDVSEvent = (FGPIO_IOPIN & PIN_ALL_ADDR) >> 16;			// fetch event
    lastDVSEventTime = newDVSEventTime;

#ifdef INCLUDE_PIXEL_CUTOUT_REGION
    {
	  unsigned long pX = ((newDVSEvent>>8) & 0x7F);
	  unsigned long pY = ((newDVSEvent)    & 0x7F);

	  if ((pixelCutoutMinX <= pX) && (pixelCutoutMaxX >= pX) &&
	  	  (pixelCutoutMinY <= pY) && (pixelCutoutMaxY >= pY)) {
#endif

														// increase write pointer
    eventBufferWritePointer = ((eventBufferWritePointer+1) & DVS_EVENTBUFFER_MASK);
    eventBufferA[eventBufferWritePointer] = newDVSEvent;   	 	// store event
    eventBufferT[eventBufferWritePointer] = newDVSEventTime;	// store event time

	
    if (eventBufferWritePointer == eventBufferReadPointer) {
      eventBufferReadPointer = ((eventBufferReadPointer+1) & DVS_EVENTBUFFER_MASK);

      LEDSetState(1000);	   							// indicate buffer overflow by LED (will turn out after some 10th of seconds)

#ifdef INCLUDE_MARK_BUFFEROVERFLOW
      eventBufferA[eventBufferWritePointer] |= OVERFLOW_BIT; // high bit set denotes buffer overflow
#endif
    }

#ifdef INCLUDE_TRACK_HF_LED
    {

#ifndef INCLUDE_PIXEL_CUTOUT_REGION
	  unsigned long pX = ((newDVSEvent>>8) & 0x7F);	  		// if not yet computed, do here
	  unsigned long pY = ((newDVSEvent)    & 0x7F);
#endif
	  unsigned long pP = ((newDVSEvent>>7) & 0x01);			// extract polarity
	  unsigned long newDVSEventTimeUS;
	  signed long eventTimeDiff, targetTimeDiff;
	  signed long factorOld, factorNew;
	  signed long dX, dY, dXY;
	  long n;

	  newDVSEventTimeUS = (newDVSEventTime>>TIMESTAMP_SHIFTBITS);	    // keep "requested" part of timestamp
	  newDVSEventTimeUS &= 0xFFFF;

	  if (pP==0) {	  						  					   		// consider only "on"-events
	    eventTimeDiff = newDVSEventTimeUS - tsMemory[pX][pY];			// compute time difference between consecutive on events
		if (eventTimeDiff < 0) eventTimeDiff += BIT(16);				// in case of overrun -> fix
	    tsMemory[pX][pY] = ((unsigned short) newDVSEventTimeUS);		// remember current time

		pX = pX<<8;
		pY = pY<<8;

		for (n=0; n<4; n++) {
		  targetTimeDiff = trackingHFLDesiredTimeDiff[n]-eventTimeDiff; 	// compute time Difference to target Frequency -> [-x ... +x]
		  if (targetTimeDiff<0) targetTimeDiff=-targetTimeDiff;				// change to absolute difference -> [0 ... +x]

		  if (targetTimeDiff<32) {											// too far away? ignore this event!
		    targetTimeDiff = targetTimeDiff*targetTimeDiff;					// square timeDiff to penalize larger distances -> [0 ... 4096]

			dX = ((((signed long) trackingHFLCenterX[n]) - ((signed long) pX))>>8); if (dX<0) dX=-dX;		// compute spatial distance between new and old pixel
			dY = ((((signed long) trackingHFLCenterY[n]) - ((signed long) pY))>>8); if (dY<0) dY=-dY;

			dX = dX*dX*dX;
			dY = dY*dY*dY;
			dXY = dX + dY;

//#define MAX_DIFF (52*64)
#define MAX_DIFF (8*64)
			if (dXY>MAX_DIFF) dXY=MAX_DIFF;
			
			factorNew = (4*64*64) - targetTimeDiff - dXY;	   			  	// contribution of "new" position [0..4096]
			if (factorNew<0) factorNew=0;

		    factorOld =   65536 - factorNew;								// contribution of "old" position

		    trackingHFLCenterX[n] = ((factorOld * trackingHFLCenterX[n]) + (factorNew * pX)) >> 16;		// update estimate of source
		    trackingHFLCenterY[n] = ((factorOld * trackingHFLCenterY[n]) + (factorNew * pY)) >> 16;		// update estimate of source

		    trackingHFLCenterC[n] = (((65536-(64)) * trackingHFLCenterC[n]) + (64* (16*factorNew))) >> 16;	// update certainty [0..65536]
		  }
		}
      }

    }
#endif

    eventCounterTotal++;
    if (newDVSEvent & MEM_ADDR_P) {
      eventCounterOff++;
    } else {
      eventCounterOn++;
    }
#ifdef INCLUDE_PIXEL_CUTOUT_REGION
    }
  }
#endif
  }



// *****************************************************************************
// *****************************************************************************
  currentTimerValue = T0_TC;

// *****************************************************************************
//    stuff to do every 1ms
// *****************************************************************************
  if (currentTimerValue >= nextTimer1msValue) {
    nextTimer1msValue += 1; 				      // start the next 1ms interval

#ifdef INCLUDE_TRACK_HF_LED
	{
	  long n;
      for (n=0; n<4; n++) {
		trackingHFLCenterC[n] = (((65536-(64*64)) * trackingHFLCenterC[n]) + (0)) >> 16;  	  	 	// decay certainty
      }
	}
#endif

#ifdef INCLUDE_TRACK_HF_LED
  #ifdef INCLUDE_TRACK_HF_LED_SERVO_OUT

    if (EP_TrackHFP_ServoEnabled) {

      if ((trackingHFLCenterC[2]) > 512) {
		TrackHFL_PWM0 -= ( (((signed long) (trackingHFLCenterX[2])) - ((signed long) (16384+500)) ) >> 10);
		TrackHFL_PWM1 -= ( (((signed long) (trackingHFLCenterY[2])) - ((signed long) (16384-1000)) ) >> 10);

    #ifdef INCLUDE_TRACK_HF_LED_LASERPOINTER
        FGPIO_IOCLR  = PIN_TRACK_HFL_LASER;		// low -> laser on
    #endif

      } else {

	    signed long error;
		error = (((signed long) 6000)-((signed long) TrackHFL_PWM0));
		if (error > 0) TrackHFL_PWM0++;
		if (error < 0) TrackHFL_PWM0--;

		error = (((signed long) 5200)-((signed long) TrackHFL_PWM1));
		if (error > 0) TrackHFL_PWM1++;
		if (error < 0) TrackHFL_PWM1--;

    #ifdef INCLUDE_TRACK_HF_LED_LASERPOINTER
        FGPIO_IOSET  = PIN_TRACK_HFL_LASER;		// high -> laser off
    #endif
      }

      // limit max and min values
#define SERVO_CENTER 6000
#define SERVO_DELTA  2500

      if (TrackHFL_PWM0 < (SERVO_CENTER-SERVO_DELTA)) TrackHFL_PWM0 = (SERVO_CENTER-SERVO_DELTA);
      if (TrackHFL_PWM1 < (SERVO_CENTER-SERVO_DELTA)) TrackHFL_PWM1 = (SERVO_CENTER-SERVO_DELTA);

      if (TrackHFL_PWM0 > (SERVO_CENTER+SERVO_DELTA)) TrackHFL_PWM0 = (SERVO_CENTER+SERVO_DELTA);
      if (TrackHFL_PWM1 > (SERVO_CENTER+SERVO_DELTA)) TrackHFL_PWM1 = (SERVO_CENTER+SERVO_DELTA);

//      PWM246SetSignal(1, TrackHFL_PWM1);
//      PWM246SetSignal(2, TrackHFL_PWM0);
      PWM_MR4 = TrackHFL_PWM1;		// update PWM4
      PWM_MR6 = TrackHFL_PWM0;		// update PWM6
      PWM_LER = BIT(4) | BIT(6);	// allow changes of MR4 and MR6 on next counter reset
    }
  #endif
#endif

//}  // end of 1ms


// *****************************************************************************
//    stuff to do every 2ms
// *****************************************************************************
  if (currentTimerValue >= nextTimer2msValue) {
    nextTimer2msValue += 2; 				      // start the next 2ms interval
//  }  // end of 2ms


// *****************************************************************************
//    stuff to do every 10ms
// *****************************************************************************
  if (currentTimerValue >= nextTimer10msValue) {
    nextTimer10msValue += 10; 				 	 // start the next 10ms interval

// ** report tracked object position
#ifdef INCLUDE_TRACK_HF_LED
    if (transmitTrackHFLED) {
	  dataForTransmission[ 0] = (trackingHFLCenterX[0]) >> 8;
	  dataForTransmission[ 1] = (trackingHFLCenterY[0]) >> 8;
	  dataForTransmission[ 2] = ((trackingHFLCenterC[0]) >> 8) & 0xFF;		// [0..255]

	  dataForTransmission[ 3] = (trackingHFLCenterX[1]) >> 8;
	  dataForTransmission[ 4] = (trackingHFLCenterY[1]) >> 8;
	  dataForTransmission[ 5] = ((trackingHFLCenterC[1]) >> 8) & 0xFF;		// [0..255]

	  dataForTransmission[ 6] = (trackingHFLCenterX[2]) >> 8;
	  dataForTransmission[ 7] = (trackingHFLCenterY[2]) >> 8;
	  dataForTransmission[ 8] = ((trackingHFLCenterC[2]) >> 8) & 0xFF;		// [0..255]

	  dataForTransmission[ 9] = (trackingHFLCenterX[3]) >> 8;
	  dataForTransmission[10] = (trackingHFLCenterY[3]) >> 8;
	  dataForTransmission[11] = ((trackingHFLCenterC[3]) >> 8) & 0xFF;		// [0..255]

	  transmitSpecialData(12);
    }
#endif

//  }  // end of 10ms


// *****************************************************************************
//    stuff to do every 100ms
// *****************************************************************************
  if (currentTimerValue >= nextTimer100msValue) {
    nextTimer100msValue += 100; 				// start the next 100ms interval

					   	  					   // ** report counted events
    if (transmitEventRateEnable) {
	  dataForTransmission[0] = ((((unsigned long) eventCounterOff  )    ) & 0x3F) + 32;
	  dataForTransmission[1] = ((((unsigned long) eventCounterOff  )>> 6) & 0x3F) + 32;
	  dataForTransmission[2] = ((((unsigned long) eventCounterOff  )>>12) & 0x3F) + 32;
	  dataForTransmission[3] = ((((unsigned long) eventCounterOn   )    ) & 0x3F) + 32;
	  dataForTransmission[4] = ((((unsigned long) eventCounterOn   )>> 6) & 0x3F) + 32;
	  dataForTransmission[5] = ((((unsigned long) eventCounterOn   )>>12) & 0x3F) + 32;
	  dataForTransmission[6] = ((((unsigned long) eventCounterTotal)    ) & 0x3F) + 32;
	  dataForTransmission[7] = ((((unsigned long) eventCounterTotal)>> 6) & 0x3F) + 32;
	  dataForTransmission[8] = ((((unsigned long) eventCounterTotal)>>12) & 0x3F) + 32;
	  transmitSpecialData(9);
    }
    eventCounterTotal = 0;
    eventCounterOn    = 0;
    eventCounterOff   = 0;

//  }  // end of 100ms


// *****************************************************************************
//    stuff to do every 1000ms
// *****************************************************************************
  if (currentTimerValue >= nextTimer1000msValue) {
    nextTimer1000msValue += 1000; 			   // start the next 1000ms interval

  }  // end of 1000ms
  }  // end of  100ms
  }  // end of   10ms
  }  // end of    2ms
  }  // end of    1ms


// *****************************************************************************
//    stuff left to send?
// *****************************************************************************
MainLoopSendEvents:
  if ((FGPIO_IOPIN & PIN_UART0_RTS) !=0 ) {			// no rts stop signal
	goto MLProcessEvents;
  }

  while ((TXBufferIndex) && (UART0_LSR & BIT(5))) {
    TXBufferIndex--;
    UART0_THR = TXBuffer[TXBufferIndex];
  }

// *****************************************************************************
//    processEventsIterate();
// *****************************************************************************
MLProcessEvents:

// *****************************************************************************
//    fetchNewEvent();  (and process event)
// *****************************************************************************
  if (TXBufferIndex) {										// wait for TX to finish sending!
    goto MLStart;
  }
  if (eventBufferWritePointer == eventBufferReadPointer) {	// more events in buffer to process?
    goto MLStart;
  }
   		 		 			  	 						 	// fetch event
  eventBufferReadPointer = ((eventBufferReadPointer+1) & DVS_EVENTBUFFER_MASK);
  eventA = eventBufferA[eventBufferReadPointer];
  eventT = eventBufferT[eventBufferReadPointer];

  if (enableEventSending) {
    switch (eDVSDataFormat) {

	case EDVS_DATA_FORMAT_BIN:
      TXBuffer[1] = ((eventA>>8) & 0xFF);				  // 1st byte to send (Y-address)
      TXBuffer[0] = ((eventA)    & 0xFF);				  // 2nd byte to send (X-address)
      TXBufferIndex = 2; break;

    case EDVS_DATA_FORMAT_BIN_TS2B:
      TXBuffer[3] = ((eventA>>8) & 0xFF);				  // 1st byte to send (Y-address)
      TXBuffer[2] = ((eventA)    & 0xFF);				  // 2nd byte to send (X-address)
      TXBuffer[1] = ((eventT>> (TIMESTAMP_SHIFTBITS+8)) & 0xFF);	// 3rd byte to send (time stamp high byte)
      TXBuffer[0] = ((eventT>> (TIMESTAMP_SHIFTBITS)  ) & 0xFF);	// 4th byte to send (time stamp low byte)
      TXBufferIndex = 4; break;

    case EDVS_DATA_FORMAT_BIN_TS3B:
      TXBuffer[4] = ((eventA>>8) & 0xFF);				  // 1st byte to send (Y-address)
      TXBuffer[3] = ((eventA)    & 0xFF);				  // 2nd byte to send (X-address)
      TXBuffer[2] = ((eventT>> (TIMESTAMP_SHIFTBITS+16)) & 0xFF);	// 3rd byte to send (time stamp high byte)
      TXBuffer[1] = ((eventT>> (TIMESTAMP_SHIFTBITS+ 8)) & 0xFF);	// 4th byte to send (time stamp)
      TXBuffer[0] = ((eventT>> (TIMESTAMP_SHIFTBITS)   ) & 0xFF);	// 5th byte to send (time stamp low byte)
      TXBufferIndex = 5; break;

    case EDVS_DATA_FORMAT_BIN_TS4B:
      TXBuffer[5] = ((eventA>> ( 8)) & 0xFF);			  // 1st byte to send (Y-address)
      TXBuffer[4] = ((eventA)        & 0xFF);			  // 2nd byte to send (X-address)
      TXBuffer[3] = ((eventT>> (24)) & 0xFF);			  // 3rd byte to send (time stamp high byte)
      TXBuffer[2] = ((eventT>> (16)) & 0xFF);			  // 4th byte to send (time stamp)
      TXBuffer[1] = ((eventT>> ( 8)) & 0xFF);			  // 5th byte to send (time stamp)
      TXBuffer[0] = ((eventT       ) & 0xFF);			  // 6th byte to send (time stamp low byte)
      TXBufferIndex = 6; break;

    case EDVS_DATA_FORMAT_HEX:
      TXBuffer[3] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
      TXBuffer[2] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
      TXBuffer[1] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
      TXBuffer[0] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
	  TXBufferIndex = 4; break;

	case EDVS_DATA_FORMAT_HEX_TS:
      TXBuffer[7] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
      TXBuffer[6] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
      TXBuffer[5] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
      TXBuffer[4] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
      TXBuffer[3] = hexLookupTable[((eventT>>12) & 0x0F)]; // 5th byte to send
      TXBuffer[2] = hexLookupTable[((eventT>> 8) & 0x0F)]; // 6th byte to send
      TXBuffer[1] = hexLookupTable[((eventT>> 4) & 0x0F)]; // 7th byte to send
      TXBuffer[0] = hexLookupTable[((eventT)     & 0x0F)]; // 8th byte to send
	  TXBufferIndex = 8; break;

    case EDVS_DATA_FORMAT_HEX_RET:
      TXBuffer[4] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
      TXBuffer[3] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
      TXBuffer[2] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
      TXBuffer[1] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
	  TXBuffer[0] = '\n';		   						  // return
	  TXBufferIndex = 4; break;

    case EDVS_DATA_FORMAT_HEX_TS_RET:
      TXBuffer[8] = hexLookupTable[((eventA>>12) & 0x0F)]; // 1st byte to send
      TXBuffer[7] = hexLookupTable[((eventA>> 8) & 0x0F)]; // 2nd byte to send
      TXBuffer[6] = hexLookupTable[((eventA>> 4) & 0x0F)]; // 3rd byte to send
      TXBuffer[5] = hexLookupTable[((eventA    ) & 0x0F)]; // 4th byte to send
      TXBuffer[4] = hexLookupTable[((eventT>>12) & 0x0F)]; // 5th byte to send
      TXBuffer[3] = hexLookupTable[((eventT>> 8) & 0x0F)]; // 6th byte to send
      TXBuffer[2] = hexLookupTable[((eventT>> 4) & 0x0F)]; // 7th byte to send
      TXBuffer[1] = hexLookupTable[((eventT)     & 0x0F)]; // 8th byte to send
	  TXBuffer[0] = '\n';		   						  // return
	  TXBufferIndex = 9; break;

    case EDVS_DATA_FORMAT_ASCII:
	  sprintf(TXBuffer, "%1d %3d %3d\n", ((eventA>>7) & 0x01), ((eventA>>8) & 0x7F), ((eventA) & 0x7F));
	  swapByteOrderInMemory(TXBuffer, 10);
	  TXBufferIndex = 10; break;

	case EDVS_DATA_FORMAT_ASCII_TS:
	  sprintf(TXBuffer, "%1d %3d %3d %8ld\n", ((eventA>>7) & 0x01), ((eventA>>8) & 0x7F), ((eventA) & 0x7F), ((eventT>>TIMESTAMP_SHIFTBITS)));
	  swapByteOrderInMemory(TXBuffer, 19);
	  TXBufferIndex = 19; break;

	case EDVS_DATA_FORMAT_ASCII_TSHS:
	  sprintf(TXBuffer, "%1d %3d %3d %10lu\n", ((eventA>>7) & 0x01), ((eventA>>8) & 0x7F), ((eventA) & 0x7F), ((eventT)));
	  swapByteOrderInMemory(TXBuffer, 21);
	  TXBufferIndex = 21; break;
    }
  }

// *****************************************************************************
//    End of Main Loop
// *****************************************************************************
goto MLStart;
//  }	// end of while loop

}

