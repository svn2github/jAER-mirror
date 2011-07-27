#include "EDVS128_2106.h"

long ledState;	 			// 0:off, -1:on, -2:blinking, >0: timeOn

// *****************************************************************************
#pragma interrupt_handler defInterruptServiceRoutine
void defInterruptServiceRoutine(void) {
/* */
}

// *****************************************************************************
void initProcessor(void) {

  __DISABLE_INTERRUPT();

// ************************************************************* PLL
  //PLL				   		  	// set frequency

#if PLL_CLOCK == 112
  SCB_PLLCFG = 0x26;			// multiplier 7(6+1), divider 2 --> Frequency 16.0 MHz * 7 ~ 112 MHz
#endif
#if PLL_CLOCK == 96
  SCB_PLLCFG = 0x25;			// multiplier 6(5+1), divider 2 --> Frequency 16.0 MHz * 6 ~  96 MHz
#endif
#if PLL_CLOCK == 80
  SCB_PLLCFG = 0x24;			// multiplier 5(4+1), divider 2 --> Frequency 16.0 MHz * 5 ~  80 MHz
#endif
#if PLL_CLOCK == 64
  SCB_PLLCFG = 0x23;			// multiplier 4(3+1), divider 2 --> Frequency 16.0 MHz * 4 ~  64 MHz
#endif
#if PLL_CLOCK == 32
  SCB_PLLCFG = 0x21;			// multiplier 2(1+1), divider 2 --> Frequency 16.0 MHz * 2 ~  64 MHz
#endif

  SCB_PLLCON = 0x01;			// set PLL enable

  SCB_PLLFEED = 0xAA;	 		// activate frequency
  SCB_PLLFEED = 0x55;
  while ((SCB_PLLSTAT & 0x0400) == 0) {  			// wait till PLL locked
  };
  SCB_PLLCON = 0x03;			// set PLL connect & enable

  SCB_PLLFEED = 0xAA;	 		// activate frequency
  SCB_PLLFEED = 0x55;
  
  // ****************************************** MAM (memory Acceleration Module)
  MAM_CR = 0;
  MAM_TIM = 0x00000003;
  MAM_CR = 0x00000002;

// *************************************************** No wakeup from powerdown
  SCB_EXTWAKE=0x00000000;

// ************************************************************* Bus clock
//  SCB_VPBDIV = 0x00000000; //peripheral clock divider, 1/4 of main clock
//  SCB_VAPBDIV = 0x00000002; //peripheral clock divider, 1/2 of main clock
  SCB_VPBDIV = 0x00000001; //peripheral clock divider, identical to main clock

  // ********************************************************* interrupt vector
  VICIntSelect=0x00000000;
  VICSoftInt = 0x00000000;
  VICSoftIntClear = 0xFFFFFFFF;
  VICIntEnable=0x00000000;

  VICDefVectAddr=(unsigned)defInterruptServiceRoutine;
  __ENABLE_INTERRUPT();
  
  
  // ************************************************************* IO ports
  // port setings
  SCB_SCS = 0x00000001;								// enable fast IO ports
  FGPIO_IOMASK = 0x00000000;						// unmask ports

  FGPIO_IODIR  = 0x00000000;		 		  		// initially all pins input
  FGPIO_IOCLR  = 0xFFFFFFFF;	  			   		// clear these pins

  PCB_PINSEL0 = 0x00000000;							// all pins to GPIO
  PCB_PINSEL1 = 0x00000000;
	// individual functions will be added during their respective Init calls
  
  // ********************************************************* IO pins
  FGPIO_IOSET  = PIN_ISP;				// ISP (P0.14) pin to high
  FGPIO_IODIR |= PIN_ISP;				// ISP (P0.14) pin to output
}

// *****************************************************************************
void delayUS(unsigned long delayTimeUS) {
  unsigned long m,n;
#if PLL_CLOCK == 112
#define DELAY_1US	  ((unsigned short) 0x000A)			// at 7x16 = 112 MHz (should be 10.5)
#endif
#if PLL_CLOCK == 96
#define DELAY_1US	  ((unsigned short) 0x0009)			// at 6x16 = 96 MHz
#endif
#if PLL_CLOCK == 80
#define DELAY_1US	  ((unsigned short) 0x0007)			// at 5x16 = 80 MHz (should be 7.5)
#endif
#if PLL_CLOCK == 64
#define DELAY_1US	  ((unsigned short) 0x0006)			// at 4x16 = 64 MHz
#endif
#if PLL_CLOCK == 32
#define DELAY_1US	  ((unsigned short) 0x0003)			// at 2x16 = 32 MHz
#endif
  for (n=0; n<delayTimeUS; n++) {
    for (m=DELAY_1US; m; m--) {
	}
  }
}
void delayMS(unsigned long delayTimeMS) {
  unsigned long m,n;
#define DELAY_1MS	  ((unsigned short) ((0x5A)*PLL_CLOCK))
  for (n=0; n<delayTimeMS; n++) {
    for (m=DELAY_1MS; m; m--) {
	}
  }
}

// *****************************************************************************
void LEDSetState(long state) {
  ledState = state;
  if (state!=0) {
    LED_ON();
  } else {
    LED_OFF();
  }
}
void LEDInit(void) {
  FGPIO_IODIR |= PIN_LED;			   	// set LEDs as output
  LEDSetBlinking();
//  LEDSetOn();
}

// *****************************************************************************
void resetDevice(void) {
#ifdef INCLUDE_PWM246
  PWM246StopPWM();
#endif

  // convince WDT to trigger :)

  WD_WDTC  = 0xFF;	  	 	     // minimal time allowed
  WD_WDMOD = 0x03;				 // enable WDT and reset on underflow
  		  					 		   // PCLCK at 60MHz -> Reset after 1000*(1/60MHz)
  WD_WDFEED = 0xAA;  	 		 // enable watch dog
  WD_WDFEED = 0x55;

  while (1) {	  						   // infinite loop, rest will trigger
  };
}

// *****************************************************************************
void enterReprogrammingMode(void) {
  void (*bootloader_entry)(void) = (void*)0;
  volatile char newChar;

#ifdef INCLUDE_PWM246
  PWM246StopPWM();
#endif

  __DISABLE_INTERRUPT();
  VICIntEnClr = 0xFFFFFFFF;            	// Clear all interrupts

  /* reset PINSEL (set all pins to GPIO) */
  SCB_SCS = 0x0000;					// disable fast IO ports
  PCB_PINSEL0 = 0x00000000;			// all pins to IO
  PCB_PINSEL1 = 0x00000000;

  /* reset GPIO, but drive P0.14 low (output) */
  GPIO_IODIR  = PIN_ISP;	   	   // only ISP (->P0.14) pin to output
  GPIO_IOCLR  = PIN_ISP;           // ISP (->P0.14) pin to low
  delayMS(20);

  /* power up all peripherals */
  SCB_PCONP = 0x000003be;     /* for LPC2104/5/6

  /* disconnect PLL */
  SCB_PLLCON = 0x00;
  SCB_PLLFEED = 0xAA;
  SCB_PLLFEED = 0x55;

  /* set peripheral bus to 1/4th of the system clock */
  SCB_VPBDIV = 0x00;

  /* map bootloader vectors */
  SCB_MEMMAP = 0;

  /* clear WDT */
  WD_WDMOD = 0; 			  // disable WDT; ensure overflow-flag is false,
  			  				  // otherwise BL is ignored

  /* clear fractional baud rate generator of serial port */
  UART0_FDR = 0x10;							// clear fractional baud rate
  UART0_FCR = 0x00;							// disable the fifos
  while (UART0_LSR & 0x01) {				// new char here?
    newChar = UART0_RBR;
  }

  /* reset T1 to default value */
  T1_CTCR = 0x00;				// increase time on PCLK
  T1_PR	  = 0;					// prescale register, increment timer every 64000th PCLK == 1ms
  T1_MCR  = 0x00;				// match register, no action on any matches (later: reset on 0xFFFF) !!!
  T1_CCR  = 0x00;				// react on external falling edge, generate interrupt
  T1_TC	  = 0;					// reset counter to zero
  T1_TCR  = 0x0;				// enable Timer/Counter 0

  // clear ISP pin, such that after ISP system returns to running mode
  GPIO_IODIR  = 0;	   	      // all pins back to input

  /* jump to the bootloader address */
  bootloader_entry();
}


// *****************************************************************************
// ************************************************************* Main
// *****************************************************************************
void main(void) {
  (void) initProcessor();

  (void) DVS128ChipInit();

  (void) LEDInit();

  (void) UARTInit();

#ifdef INCLUDE_PWM246
  (void) PWM246Init();
#endif

#ifdef INCLUDE_TRACK_HF_LED
  (void) EP_TrackHFLInit();
#endif

  (void) mainloopInit();

  (void) UARTShowVersion();

  (void) mainloop();
}