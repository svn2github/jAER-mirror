#include "EDVS128_2106.h"

#define DEFAULT_BIAS_SET		0			// "BIAS_BRAGFOST"
//#define DEFAULT_BIAS_SET		1			// "BIAS_DEFAULT"
//#define DEFAULT_BIAS_SET		2			// "BIAS_FAST"
//#define DEFAULT_BIAS_SET		3			// "BIAS_STEREO_PAIR"
//#define DEFAULT_BIAS_SET		4			// "BIAS_MINI_DVS"

// *****************************************************************************
extern unsigned char dataForTransmission[16];

// *****************************************************************************
unsigned long biasMatrix[12];

// *****************************************************************************
unsigned long enableEventSending;
unsigned long newEvent;
unsigned long x, y, p;

unsigned long eventBufferWritePointer;
unsigned long eventBufferReadPointer;
unsigned long eventBuffer[DVS_EVENTBUFFER_SIZE];

#ifdef INCLUDE_PIXEL_CUTOUT_REGION
unsigned long pixelCutoutMinX, pixelCutoutMaxX, pixelCutoutMinY, pixelCutoutMaxY;
#endif

// *****************************************************************************
void DVS128ChipInit(void) {
  FGPIO_IOSET  = PIN_RESET_DVS;				// DVS array reset to high
  FGPIO_IODIR |= PIN_RESET_DVS;				// DVS array reset pin to output

//  FGPIO_IOSET  = PIN_DVS_ACKN;				// ackn to high	   	  // let DVS handshake itself, only grab addresses from bus
//  FGPIO_IODIR |= PIN_DVS_ACKN;				// ackn to output port

  FGPIO_IOSET  = (PIN_BIAS_LATCH);			// set pins to bias setup as outputs
  FGPIO_IOCLR  = (PIN_BIAS_CLOCK | PIN_BIAS_DATA);
  FGPIO_IODIR |= (PIN_BIAS_LATCH | PIN_BIAS_DATA | PIN_BIAS_CLOCK);

  FGPIO_IOCLR  = PIN_RESET_DVS;				// DVS array reset to low
  delayMS(10); 	 							// 10ms delay
  FGPIO_IOSET  = PIN_RESET_DVS;				// DVS array reset to high
  delayMS(1); 	 							// 1ms delay

  DVS128BiasLoadDefaultSet(4);					// load default bias settings
  DVS128BiasFlush();								// transfer bias settings to chip

  // *****************************************************************************
  eventBufferWritePointer=0;				// initialize eventBuffer
  eventBufferReadPointer=0;

  // *****************************************************************************
  enableEventSending=0;
  DVS128FetchEventsEnable(FALSE);

#ifdef INCLUDE_PIXEL_CUTOUT_REGION
  pixelCutoutMinX = 0;
  pixelCutoutMaxX = 127;
  pixelCutoutMinY = 0;
  pixelCutoutMaxY = 127;
#endif


  // *****************************************************************************
  // ** initialize timer 0 (1us clock)
  // *****************************************************************************
  T0_PR = (1000*PLL_CLOCK)-1;	// prescaler: run at 1ms clock rate
  T0_CTCR = 0x00;				// increase time on every T-CLK

  T0_MCR  = 0x00;				// match register, no special action, simply count until 2^32-1 and restart
  T0_TC	  = 0;					// reset counter to zero
  T0_TCR  = 0x01;				// enable Timer/Counter 0


  // *****************************************************************************
  // ** initialize timer 1 (system main clock)
  // *****************************************************************************
  T1_PR = 0;					// prescaler: run at main clock speed!
  T1_CTCR = 0x00;				// increase time on every T-CLK

//  T1_MR0 = BIT(16);			// match register: count only up to 2^16 = 0..65535
//  T1_MR0 = 50000;				// match register: count only up 2us * 50.000 = 100.000us = 100ms
//  T1_MCR  = 0x02;				// match register, reset counter on match with T1_MR0

  T1_MCR  = 0x00;				// match register, no special action, simply count until 2^32-1 and restart
  T1_CCR  = BIT(1);				// capture TC in CR0 on falling edge of CAP0.1 (PIN_DVS_REQUEST)
  PCB_PINSEL0 |= BIT(21);		// set P0.10 to capture register CAP0.1

  T1_TC	  = 0;					// reset counter to zero
  T1_TCR  = 0x01;				// enable Timer/Counter 1
}

// *****************************************************************************
void DVS128FetchEventsEnable(unsigned char flag) {
  if (flag) {
    LEDSetOff();
    enableEventSending = 1;
  } else {
    LEDSetBlinking();
    enableEventSending = 0;
  }
}

// *****************************************************************************
void DVS128BiasSet(unsigned long biasID, unsigned long biasValue) {
  if (biasID < 12) {
    biasMatrix[biasID] = biasValue;
  }
}
// *****************************************************************************
unsigned long DVS128BiasGet(unsigned long biasID) {
  if (biasID < 12) {
    return(biasMatrix[biasID]);
  }
  return(0);
}

// *****************************************************************************
void DVS128BiasLoadDefaultSet(unsigned long biasSetID) {

  switch (biasSetID) {

  case 0:  // 12 bias values of 24 bits each 								BIAS_BRAGFOST
    biasMatrix[ 0]=        1067;	  		// Tmpdiff128.IPot.cas
    biasMatrix[ 1]=       12316;			// Tmpdiff128.IPot.injGnd
    biasMatrix[ 2]=    16777215;			// Tmpdiff128.IPot.reqPd
    biasMatrix[ 3]=     5579731;			// Tmpdiff128.IPot.puX
    biasMatrix[ 4]=          60;			// Tmpdiff128.IPot.diffOff
    biasMatrix[ 5]=      427594;			// Tmpdiff128.IPot.req
    biasMatrix[ 6]=           0;			// Tmpdiff128.IPot.refr
    biasMatrix[ 7]=    16777215;			// Tmpdiff128.IPot.puY
    biasMatrix[ 8]=      567391;			// Tmpdiff128.IPot.diffOn
    biasMatrix[ 9]=        6831;			// Tmpdiff128.IPot.diff
    biasMatrix[10]=          39;			// Tmpdiff128.IPot.foll
    biasMatrix[11]=           4;			// Tmpdiff128.IPot.Pr
    break;

  case 1:  // 12 bias values of 24 bits each 								BIAS_DEFAULT
    biasMatrix[ 0]=	    1067; // 0x00042B,	  		// Tmpdiff128.IPot.cas
    biasMatrix[ 1]=	   12316; // 0x00301C,			// Tmpdiff128.IPot.injGnd
    biasMatrix[ 2]=	16777215; // 0xFFFFFF,			// Tmpdiff128.IPot.reqPd
    biasMatrix[ 3]=	 5579732; // 0x5523D4,			// Tmpdiff128.IPot.puX
    biasMatrix[ 4]=	     151; // 0x000097,			// Tmpdiff128.IPot.diffOff
    biasMatrix[ 5]=	  427594; // 0x06864A,			// Tmpdiff128.IPot.req
    biasMatrix[ 6]=	       0; // 0x000000,			// Tmpdiff128.IPot.refr
    biasMatrix[ 7]=	16777215; // 0xFFFFFF,			// Tmpdiff128.IPot.puY
    biasMatrix[ 8]=	  296253; // 0x04853D,			// Tmpdiff128.IPot.diffOn
    biasMatrix[ 9]=	    3624; // 0x000E28,			// Tmpdiff128.IPot.diff
    biasMatrix[10]=	      39; // 0x000027,			// Tmpdiff128.IPot.foll
    biasMatrix[11]=        4; // 0x000004			// Tmpdiff128.IPot.Pr
    break;

  case 2:  // 12 bias values of 24 bits each 								BIAS_FAST
    biasMatrix[ 0]=        1966;	  		// Tmpdiff128.IPot.cas
    biasMatrix[ 1]=     1137667;			// Tmpdiff128.IPot.injGnd
    biasMatrix[ 2]=    16777215;			// Tmpdiff128.IPot.reqPd
    biasMatrix[ 3]=     8053457;			// Tmpdiff128.IPot.puX
    biasMatrix[ 4]=         133;			// Tmpdiff128.IPot.diffOff
    biasMatrix[ 5]=      160712;			// Tmpdiff128.IPot.req
    biasMatrix[ 6]=         944;			// Tmpdiff128.IPot.refr
    biasMatrix[ 7]=    16777215;			// Tmpdiff128.IPot.puY
    biasMatrix[ 8]=      205255;			// Tmpdiff128.IPot.diffOn
    biasMatrix[ 9]=        3207;			// Tmpdiff128.IPot.diff
    biasMatrix[10]=         278;			// Tmpdiff128.IPot.foll
    biasMatrix[11]=         217;			// Tmpdiff128.IPot.Pr
    break;

  case 3:  // 12 bias values of 24 bits each 								BIAS_STEREO_PAIR
    biasMatrix[ 0]=        1966;
    biasMatrix[ 1]=     1135792;
    biasMatrix[ 2]=    16769632;
    biasMatrix[ 3]=     8061894;
    biasMatrix[ 4]=         133;
    biasMatrix[ 5]=      160703;
    biasMatrix[ 6]=         935;
    biasMatrix[ 7]=    16769632;
    biasMatrix[ 8]=      205244;
    biasMatrix[ 9]=        3207;
    biasMatrix[10]=         267;
    biasMatrix[11]=         217;
    break;

  case 4:  // 12 bias values of 24 bits each 								BIAS_MINI_DVS
    biasMatrix[ 0]=        1966;
    biasMatrix[ 1]=     1137667;
    biasMatrix[ 2]=    16777215;
    biasMatrix[ 3]=     8053458;
    biasMatrix[ 4]=          62;
    biasMatrix[ 5]=      160712;
    biasMatrix[ 6]=         944;
    biasMatrix[ 7]=    16777215;
    biasMatrix[ 8]=      480988;
    biasMatrix[ 9]=        3207;
    biasMatrix[10]=         278;
    biasMatrix[11]=         217;
    break;

  }
}

// *****************************************************************************
#pragma ramfunc biasFlush
void DVS128BiasFlush(void) {
  unsigned long biasIndex, bitIndex, currentBias;
  
  for (biasIndex=0; biasIndex<12; biasIndex++) {
    currentBias = biasMatrix[biasIndex];

	bitIndex = BIT(23);
	do {
	  if (currentBias & bitIndex) {
	    FGPIO_IOSET = PIN_BIAS_DATA;
	  } else {
	    FGPIO_IOCLR = PIN_BIAS_DATA;
	  }
	  FGPIO_IOSET = PIN_BIAS_CLOCK;

	  FGPIO_IOCLR = PIN_BIAS_CLOCK;

	  bitIndex >>= 1;
	} while (bitIndex);

  }  // end of biasIndexclocking

  FGPIO_IOCLR = PIN_BIAS_DATA;	   // set data pin to low just to have the same output all the time

  // trigger latch to push bias data to bias generators
  FGPIO_IOCLR = PIN_BIAS_LATCH;
  FGPIO_IOSET = PIN_BIAS_LATCH;
}


// *****************************************************************************
#pragma ramfunc biasTransmitBiasValue
void DVS128BiasTransmitBiasValue(unsigned long biasID) {
  unsigned long biasValue;
  biasValue = biasMatrix[biasID];

  dataForTransmission[0] = (((biasValue)    ) & 0x3F) + 32;
  dataForTransmission[1] = (((biasValue)>> 6) & 0x3F) + 32;
  dataForTransmission[2] = (((biasValue)>>12) & 0x3F) + 32;
  dataForTransmission[3] = (((biasValue)>>18) & 0x3F) + 32;
  dataForTransmission[4] = biasID + 32;

  transmitSpecialData(5);
}
