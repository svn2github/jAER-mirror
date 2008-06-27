/*
hex cheat sheet
0000	0x00
0001	0x01
0010	0x02

0111	0x07
1000	0x08
1001	0x09
1010	0x0a
1011	0x0b
1100	0x0c
1101	0x0d
1110	0x0e
1111	0x0f

*/
//-----------------------------------------------------------------------------
// F32x_USB_Main.c
//-----------------------------------------------------------------------------
// Copyright 2005 Silicon Laboratories, Inc.
// http://www.silabs.com
//
// Program Description:
//
// This application note covers the implementation of a simple USB application 
// using the interrupt transfer type. This includes support for device
// enumeration, control and interrupt transactions, and definitions of 
// descriptor data. The purpose of this software is to give a simple working 
// example of an interrupt transfer application; it does not include
// support for multiple configurations or other transfer types.
//
// How To Test:    See Readme.txt
//
//
// FID:            32X000024
// Target:         C8051F32x
// Tool chain:     Keil C51 7.50 / Keil EVAL C51
//                 Silicon Laboratories IDE version 2.6
// Command Line:   See Readme.txt
// Project Name:   F32x_USB_Interrupt
//
//
// Release 1.3
//    -All changes by GP
//    -22 NOV 2005
//    -Changed revision number to match project revision
//     No content changes to this file
//    -Modified file to fit new formatting guidelines
//    -Changed file name from USB_MAIN.c

// Release 1.1
//    -All changes by DM
//    -22 NOV 2002
//    -Added support for switches and sample USB interrupt application.
//
// Release 1.0
//    -Initial Revision (JS)
//    -22 FEB 2002
//

//-----------------------------------------------------------------------------
// Includes
//-----------------------------------------------------------------------------

#include <c8051f320.h>
#include "F32x_USB_Register.h"
#include "F32x_USB_Main.h"
#include "F32x_USB_Descriptor.h"

//-----------------------------------------------------------------------------
// Globals
//-----------------------------------------------------------------------------
sbit	LedRed	=	P0^3;	//	LED='1' means ON
sbit	LedGreen	=	P0^4;	//	These blink to indicate data transmission
sbit	LedBlue	= 	P0^5;
sbit	Servo0 	= 	P0^2;
sbit	Servo1 	= 	P0^7;

#define LedRedOn() LedRed=0;
#define LedRedOff()  LedRed=1;
#define LedRedToggle() LedRed=!LedRed; // this probably doesn't work because it reads port and then writes opposite, but since all ports are tied together somewhat it may not work
#define LedGreenOn() LedGreen=0;
#define LedGreenOff() LedGreen=1;
#define LedGreenToggle() LedGreen=!LedGreen;
#define LedBlueOn() LedBlue=0;
#define LedBlueOff() LedBlue=1;
#define LedBlueToggle() LedBlue=!LedBlue;

// define command codes
#define CMD_SET_SERVO 7 
#define CMD_DISABLE_SERVO 8
#define CMD_SET_ALL_SERVOS 9
#define CMD_DISABLE_ALL_SERVOS 10


// PWM servo output variables. these are used to hold the new values for the PCA compare registers so that 
// they can be updated on the interrupt generated when the value can be updated safely without introducing glitches.
unsigned char pwmNumber, pwml1, pwmh1, pwml2, pwmh2;

sbit Led1 = P0^3;                      // LED='1' means ON
sbit Led2 = P0^4;

idata BYTE Out_Packet[64];             // Last packet received from host
idata BYTE In_Packet[64];              // Next packet to sent to host

void	Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void	Timer_Init(void);			// Init timer to use for spike event times


//-----------------------------------------------------------------------------
// Main Routine
//-----------------------------------------------------------------------------
void main(void)
{
   PCA0MD &= ~0x40;                    // Disable Watchdog timer

   Sysclk_Init();                      // Initialize oscillator
   Port_Init();                        // Initialize crossbar and GPIO
   Usb0_Init();                        // Initialize USB0
   Timer_Init();                       // Initialize timer2

   while (1)
   {
    // It is possible that the contents of the following packets can change
    // while being updated.  This doesn't cause a problem in the sample
    // application because the bytes are all independent.  If data is NOT
    // independent, packet update routines should be moved to an interrupt
    // service routine, or interrupts should be disabled during data updates.

		EA=0; // disable ints
      	if(Out_Packet[0]==CMD_SET_SERVO) // cmd: CMD, SERVO, PWMValue (2 bytes bigendian)
		{
			Out_Packet[0]=0; // command is processed
			LedRedOn();
			pwmNumber=Out_Packet[1];
			switch(pwmNumber)
			{
			// big endian 16 bit value to load into PWM controller
				case 0:
				{ // servo0
					pwmh1=Out_Packet[2]; // store the PCA compare value for later interrupt to load
					pwml1=Out_Packet[3];
					PCA0CPM1 |= 0x49; // enable compare function and match and interrupt for match for pca
					
				}
				break;
				case 1:
				{ // servo1
					pwmh2=Out_Packet[2];
					pwml2=Out_Packet[3];
					PCA0CPM2 |= 0x49; // enable compare function and enable match and interrupt for match for pca
				}
			}			
			EIE1 |= 0x10; // enable PCA interrupt
		}
      	else if(Out_Packet[0]==CMD_DISABLE_SERVO) // cmd: CMD, SERVO
		{
			Out_Packet[0]=0; // command is processed
			LedRedOn();
			pwmNumber=Out_Packet[1];
			switch(pwmNumber)
			{
			// big endian 16 bit value to load into PWM controller
				case 0:
				{ // servo0
					PCA0CPM1 &= ~0x40; // disable compare function
					
				}
				break;
				case 1:
				{ // servo1
					PCA0CPM2 &= ~0x40; // disable compare function
				}
			}			
		}
      	else if(Out_Packet[0]==CMD_SET_ALL_SERVOS) // cmd: CMD, PWMValue0 (2 bytes bigendian), PWMValue1 (2 bytes bigendian)
		{
			Out_Packet[0]=0; // command is processed
			LedRedOn();
			pwmh1=Out_Packet[1]; // store the PCA compare value for later interrupt to load
			pwml1=Out_Packet[2];
			PCA0CPM1 |= 0x49; // enable compare function and match and interrupt for match for pca
			pwmh2=Out_Packet[3];
			pwml2=Out_Packet[4];
			PCA0CPM2 |= 0x49; // enable compare function and enable match and interrupt for match for pca
		}		
     	else if(Out_Packet[0]==CMD_DISABLE_ALL_SERVOS) // cmd: CMD
		{
			Out_Packet[0]=0; // command is processed
			LedRedOn();
			PCA0CPM1 &= ~0x40; // disable compare function
			PCA0CPM2 &= ~0x40; // disable compare function
		}
		EA=1; // enable interrupts
		LedRedOff();
	}

}


// pwm interrupt vectored when there is a match interrupt for PCA: only then do we change PCA compare register
void PWM_Update_ISR(void) interrupt 11
{
	EIE1 &= (~0x10); // disable PCA interrupt
	switch(pwmNumber)
	{
		case 0:
			PCA0CPL1=pwml1;
			PCA0CPH1=pwmh1;
			PCA0CPM1 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x02); // clear CCF1 interrupt pending flag for PCA1
			break;
		case 1:
			PCA0CPL2=pwml2;
			PCA0CPH2=pwmh2;
			PCA0CPM2 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x04); // clear CCF2 interrupt pending flag for PCA2
	}
	EIE1 |= 0x10; // reenable PCA interrupt
}




//-----------------------------------------------------------------------------
// Initialization Subroutines
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Sysclk_Init
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : None
//
// Initialize the system clock and USB clock
//
//-----------------------------------------------------------------------------
void Sysclk_Init(void)
{
#ifdef _USB_LOW_SPEED_

   OSCICN |= 0x03;                     // Configure internal oscillator for
                                       // its maximum frequency and enable
                                       // missing clock detector

   CLKSEL  = SYS_INT_OSC;              // Select System clock
   CLKSEL |= USB_INT_OSC_DIV_2;        // Select USB clock
#else
   OSCICN |= 0x03;                     // Configure internal oscillator for
                                       // its maximum frequency and enable
                                       // missing clock detector

   CLKMUL  = 0x00;                     // Select internal oscillator as
                                       // input to clock multiplier

   CLKMUL |= 0x80;                     // Enable clock multiplier
   Delay();                            // Delay for clock multiplier to begin
   CLKMUL |= 0xC0;                     // Initialize the clock multiplier
   Delay();                            // Delay for clock multiplier to begin

   while(!(CLKMUL & 0x20));            // Wait for multiplier to lock
   CLKSEL  = SYS_INT_OSC;              // Select system clock
   CLKSEL |= USB_4X_CLOCK;             // Select USB clock
#endif  /* _USB_LOW_SPEED_ */
}

//-----------------------------------------------------------------------------
// PORT_Init
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : None
//
// This function configures the crossbar and GPIO ports.
//
// P1.7   analog                  Potentiometer
// P2.2   digital   push-pull     LED
// P2.3   digital   push-pull     LED
//-----------------------------------------------------------------------------
void	Port_Init(void)
{  

// P  1	212          O: bit 1 is ACK output, others are inputs (incl REQ on P0.0)
// P2: bit 6,7 are LEDs are outputs
// don't connect any internal functions to ports
// no weak pullups, no internal functions to ports

// following from silabs config wizard 2.05 bundled as utility with IDE
// Config template saved as ConfigWizardTemplate.dat
//----------------------------------------------------------------
// CROSSBAR REGISTER CONFIGURATION
//
// NOTE: The crossbar register should be configured before any  
// of the digital peripherals are enabled. The pinout of the 
// device is dependent on the crossbar configuration so caution 
// must be exercised when modifying the contents of the XBR0, 
// XBR1 registers. For detailed information on 
// Crossbar Decoder Configuration, refer to Application Note 
// AN001, "Configuring the Port I/O Crossbar Decoder". 
//----------------------------------------------------------------

/*
Step 1.  Select the input mode (analog or digital) for all Port pins, using the Port Input Mode register (PnMDIN).
Step 2.  Select the output mode (open-drain or push-pull) for all Port pins, using the Port Output Mode register (PnMDOUT).
Step 3.  Select any pins to be skipped by the I/O Crossbar using the Port Skip registers (PnSKIP).
Step 4.  Assign Port pins to desired peripherals (XBR0, XBR1).
Step 5.  Enable the Crossbar (XBARE = ‘1’).
*/

// Configure the XBRn Registers
	XBR0 = 0x00;	// 0000 0000 Crossbar Register 1. no peripherals are routed to output.
	XBR1 = 0xc3;	// 1000 0011 Crossbar Register 2. no weak pullups, cex0, cex1, cex2 routed to port pins.1100 0011	0xc3

// Select Pin I/0

// NOTE: Some peripheral I/O pins can function as either inputs or 
// outputs, depending on the configuration of the peripheral. By default,
// the configuration utility will configure these I/O pins as push-pull 
// outputs.
	// Port configuration (1 = Push Pull Output)
    P0MDIN = 0xFF;  // Input configuration for P0. Not using analog input.
    P1MDIN = 0xFF;  // Input configuration for P1
    P2MDIN = 0xFF;  // Input configuration for P2
    P3MDIN = 0xFF;  // Input configuration for P3

// leds are p0 3,4,5 
// servos are p2, p7
    P0MDOUT = 0xbd; // Output configuration for P0, 1011 1101 bit 0 is ack output, bit 1 is req input, bit 2 is Servo0 output, bit 7 is Servo1 output, bits 3,4,5 are LED outputs
//    P0MDOUT = 0x01; // Output configuration for P0, bit 0 is ack output, bit 1 is req input, 0000 0001, 
					// leds are bits 3,4,5 but are open drain, set bit low to pull down and turn on LED
    P1MDOUT = 0x00; // Output configuration for P1  // P1 is used for AE lsb 8 bits
    P2MDOUT = 0x00; // Output configuration for P2  // P2 is used for AE msb 8 bits

    P3MDOUT = 0x00; // Output configuration for P3 



    P0SKIP = 0x79;  //  0111 1001 Port 0 Crossbar Skip Register. Skip first pin so that 
	                // bit 1 (req) P0.1 becomes CEX0 input to PCA0 capture module
					// then p0.2 becomes cex1 and p0.7 becomes cex2
				
    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register
    P2SKIP = 0x00;  //  Port 2 Crossbar Skip Register


	XBR1|=0x40; 	// 0100 0000 enable xbar, setting XBARE


}

//-----------------------------------------------------------------------------
// Usb0_Init
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : None
// 
// - Initialize USB0
// - Enable USB0 interrupts
// - Enable USB0 transceiver
// - Enable USB0 with suspend detection
//-----------------------------------------------------------------------------
void Usb0_Init(void)
{
   BYTE Count;

   // Set initial values of In_Packet and Out_Packet to zero
   // Initialized here so that WDT doesn't kick in first
   for (Count = 0; Count < 64; Count++)
   {
      Out_Packet[Count] = 0;
      In_Packet[Count] = 0;
   }


   POLL_WRITE_BYTE(POWER,  0x08);      // Force Asynchronous USB Reset
   POLL_WRITE_BYTE(IN1IE,  0x07);      // Enable Endpoint 0-2 in interrupts
   POLL_WRITE_BYTE(OUT1IE, 0x07);      // Enable Endpoint 0-2 out interrupts
   POLL_WRITE_BYTE(CMIE,   0x07);      // Enable Reset,Resume,Suspend interrupts
#ifdef _USB_LOW_SPEED_
   USB0XCN = 0xC0;                     // Enable transceiver; select low speed
   POLL_WRITE_BYTE(CLKREC, 0xA0);      // Enable clock recovery; single-step mode
                                       // disabled; low speed mode enabled
#else
   USB0XCN = 0xE0;                     // Enable transceiver; select full speed
   POLL_WRITE_BYTE(CLKREC, 0x80);      // Enable clock recovery, single-step mode
                                       // disabled
#endif // _USB_LOW_SPEED_

   EIE1 |= 0x02;                       // Enable USB0 Interrupts
   EA = 1;                             // Global Interrupt enable
                                       // Enable USB0 by clearing the USB 
                                       // Inhibit bit
   POLL_WRITE_BYTE(POWER,  0x01);      // and enable suspend detection
}

void	Timer_Init(void)
{
//----------------------------------------------------------------
// Timers Configuration
//----------------------------------------------------------------

    CKCON = 0x04; // t0 clked by sysclk=24MHz 0x04;   // Clock Control Register, timer 0 uses prescaled sysclk/12. sysclk is 24MHz.
   TMOD = 0x12;    // Timer Mode Register, timer0 8 bit with reload, timer1 16 bit
   	TCON = 0x50;    // Timer Control Register , timer0 and 1 running
    TH0 = 0xFF-1; 	    // Timer 0 High Byte, reload value. 
						//This is FF-n so timer0 takes n+1 cycles = to roll over, time is (n+1)/12MHz (12MHz = Sysclk)  
    TL0 = 0x00;     // Timer 0 Low Byte
 	
	CR=1;			// run PCA counter/timer
	// PCA uses timer 0 overflow which is 1us clock. all pca modules share same timer which runs at 1MHz.
	

	PCA0MD|=0x84;	// use timer0 overflow to clock PCA counter. leave wdt bit undisturbed. turn off PCA in idle.
//	PCA0MD |= 0x80;	// PCA runs on sysclk/12 (24/12=2 MHz), doesn't run when in idle.
//	PCA0MD =0x88; // PCA uses sysclk = 12  MHz
//	PCA0MD=0x82; // PCA uses sysclk/4=3MHz

	// pca pwm output frequency depends on pca clock source because pca counter rolls over
	// every 64k cycles. we want pwm update frequency to be about 100 Hz which means rollower
	// should happen about every 10ms, therefore (1/f)*64k=10ms means f=6.5MHz
	// but we use sysclk/4=3MHz


	// PCA0CPM0=0x10; 

	// PCA1 and PCA2 are used for servo motor output

	// using new PCA clocking above, each count takes 1/6 us, giving about 91Hz servo update rate

	// pca is 16 bit = 65k counts = =64k*0.5us=32kus=32ms. 16 bit count varies pulse width. 
	// PCA value defines low time, therefore pulse width
	// is 65k-PCA value, if PCA0CP1 value=63k, for example, pulse width will be (64-63)=1k us=1ms.

	// servo motors respond to high pulse widths from 0.9 ms to 2.1 ms. CPL values encode time that PCA PWM output is low.
	// therefore we need to load a value that is 64k-counthigh. This computation is done on the host so that the interrupt service routine
	// just loads the low and high byte values into the capture compare registers.	

	PCA0CPM1=0xC2; // PWM16+ECOM+PWM: 16 bit mode, PCA compare enabled, PWM output to CEX1 
	PCA0CPM2=0xC2; // PWM16+ECOM+PWM: 16 bit mode, PCA compare enabled, PWM output to CEX2 

//	PCA0CPM1 &= ~0x40; // disable servo
//	PCA0CPM2 &= ~0x40; // disable servo
	
}

//-----------------------------------------------------------------------------
// Delay
//-----------------------------------------------------------------------------
//
// Used for a small pause, approximately 80 us in Full Speed,
// and 1 ms when clock is configured for Low Speed
//
//-----------------------------------------------------------------------------

void Delay(void)
{
   int x;
   for(x = 0;x < 500;x)
      x++;
}

//-----------------------------------------------------------------------------
// End Of File
//-----------------------------------------------------------------------------