/* Firmware for SlotCarController PCB control using the SiLabs C8051F320 and the SlotCarController board
see http://jaer.wiki.sourceforge.net. 
This is device side of SiLabsC8051F320_USBIO_ServoController host side java class.
author Tobi Delbruck, 2006-2010

Tell 2010: added mode to set PXMDOUT from host, to set port pushpull/opendrain mode
Zurich 2011: Customized just for SlotCarController PCB, with motor braking
			
*/

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
sbit	Led	=	P0^7;	//	LED='1' means ON
sbit	Throttle0 	= 	P1^0;
sbit	Throttle1 	= 	P1^1;
sbit 	Throttle2	=	P1^2;
sbit	Throttle3	=	P1^3;
sbit	Brake0	=	P1^4;
sbit	Brake1	=	P1^5;
sbit	Brake2	=	P1^6;
sbit	Brake3	=	P1^7;

#define zeroThrottleNoBrakes()				P1=0x0F;  // brake bits 0, throttle bits 1

#define LedOn() Led=0;
#define LedOff()  Led=1;
#define LedToggle() Led=!Led; // this may not work because it reads port and then writes opposite

// define command codes
#define CMD_SET_SERVO 7  // clear motor brake, sets throttle PWM
#define CMD_DISABLE_SERVO 8
#define CMD_SET_ALL_SERVOS 9
#define CMD_DISABLE_ALL_SERVOS 10
#define CMD_SET_TIMER0_RELOAD_VALUE 11
#define CMD_SET_PORT2 12  // sets P2 to 8 bit value
#define CMD_SET_PORT_DOUT 14 // sets P2.0 in PWM output mode and programs the duty cycle
#define CMD_SET_PCA0MD_CPS 15 // sets the PCA clock source bits
#define CMD_SET_BRAKE 16 // sets motor brake output, disables throttle

// PWM servo output variables. these are used to hold the new values for the PCA compare registers so that 
// they can be updated on the interrupt generated when the value can be updated safely without introducing glitches.
unsigned char pwmNumber, pwml1, pwmh1, pwml2, pwmh2, pwml3, pwmh3, pwml4, pwmh4;

idata BYTE Out_Packet[64];             // Last packet received from host
idata BYTE In_Packet[64];              // Next packet to sent to host

void	Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void	Timer_Init(void);			// Init timer to use for spike event times

//-----------------------------------------------------------------------------
// Main Routine
//-----------------------------------------------------------------------------
void main(void)  
{
	char cmd;

   PCA0MD &= ~0x40;                    // Disable Watchdog timer

   Sysclk_Init();                      // Initialize oscillator
   Port_Init();                        // Initialize crossbar and GPIO
   P2=0xFF;  // tie high to turn off pulldowns for open drain devices connected
   Usb0_Init();                        // Initialize USB0
   Timer_Init();                       // Initialize timer2
   LedOn(); 

  	//RSTSRC =0x80;	;				   // enable USB and
                                       // missing clock detector reset sources
									   // if we enabled missing clock detector then the device doesn't work, don't know why

    // watchdog
	// load watchdog offset 
	// PCA0CPL4=0xff; // maximum offset so that watchdog takes a good long time to time out
	// enable watchdog 
  PCA0MD |= 0x04;   // WDT disabled, PCA clock source is timer0 overflow
  //PCA0CPH4 = 0x00;  // write value to WDT PCA to start watchdog                   

	// init ports to set throttles to zero and brakes off
	zeroThrottleNoBrakes();
	
/*	Throttle0=0;
	Throttle1=0;
	Throttle2=0;
	Throttle3=0;
*/
   while (1)
   {
    // It is possible that the contents of the following packets can change
    // while being updated.  This doesn't cause a problem in the sample
    // application because the bytes are all independent.  If data is NOT
    // independent, packet update routines should be moved to an interrupt
    // service routine, or interrupts should be disabled during data updates.


	  //PCA0CPH4 = 355;  // write value to WDT PCA to reset watchdog
	  
	             
		
		EA=0; // disable ints
	//	LedToggle();
		cmd=Out_Packet[0];
		switch(cmd){
		case CMD_SET_SERVO:
			Out_Packet[0]=0; // command is processed
			LedToggle();
			pwmNumber=Out_Packet[1];
			switch(pwmNumber)
			{
			// 8 bit value to load into PWM controller
				case 0:
				{ // Throttle0
					Brake0=0;
					PCA0CPM0 = 2; 
					PCA0CPH0=Out_Packet[2]; // store the PCA compare value for later interrupt to load
					
				}
				break;
				case 1:
				{ // Throttle1
					Brake1=0;
					PCA0CPM1 = 2; 
					PCA0CPH1=Out_Packet[2]; // store the PCA compare value for later interrupt to load
				}
				break;
				case 2:
				{ // Throttle2
					Brake2=0;
					PCA0CPM2 = 2; 
					PCA0CPH2=Out_Packet[2]; // store the PCA compare value for later interrupt to load
				}
				break;
				case 3:
				{ // Throttle3
					Brake3=0;
					PCA0CPM3 = 2; 
					PCA0CPH3=Out_Packet[2]; // store the PCA compare value for later interrupt to load
				}
			}			
			EIE1 |= 0x10; // enable PCA interrupt

			break;
			case CMD_DISABLE_SERVO:
	      	//cmd: CMD, SERVO
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				pwmNumber=Out_Packet[1];
				switch(pwmNumber)
				{
				// big endian 16 bit value to load into PWM controller
					case 0:
					{ // Throttle0
						PCA0CPM0 = 0; 
						Throttle0=1;
					}
					break;
					case 1:
					{ // Throttle1
						PCA0CPM1 = 0; 
						Throttle1=1;
					}
					break;
					case 2:
					{ // Throttle2
						PCA0CPM2 = 0; 
						Throttle2=1;
					}
					break;
					case 3:
					{ // Throttle3
						PCA0CPM3 = 0; 
						Throttle3=1;
					}
				}			
			}
			break;
			case CMD_SET_TIMER0_RELOAD_VALUE: 	
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				TH0=255-Out_Packet[1]; // timer0 reload value, 
			}
			break;
			case CMD_SET_PCA0MD_CPS: // bit are ORed with 0x7, left shifted by one, and set to the PCA0MD bits 3:1
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				// must disable watchdog before changing these bits
				//PCA0MD&=~0x40;	

				PCA0MD = (PCA0MD & 0xf1) | (  (0x7&Out_Packet[1])  <<1); // this is the PCA control register, bits 3:1 are the CPS bits that control the PCA clock source
				// CPS = 0 sysclk/12
				// CPS = 1 sysclk/4
				// CPS = 2 timer0 overflow

				//PCA0MD|=0x40; // re-enable watchdog
				//PCA0CPH4 = 0xff;  // write value to WDT PCA to start watchdog                   

			}
			break;
			case CMD_SET_PORT2:
			{
				Out_Packet[0]=0; //ack
				LedToggle();
				P2=Out_Packet[1];
				break;
			}
	
			case CMD_SET_BRAKE:
			{
				Out_Packet[0]=0; //ack
				pwmNumber=Out_Packet[1];
				LedToggle();
				switch(pwmNumber)
				{
					case 0:
					{ // Throttle0
						PCA0CPM0 = 0; 
						Throttle0=1;
						Brake0=1;
					}
					break;
					case 1:
					{ // Throttle1
						PCA0CPM1 = 0; 
						Throttle1=1;
						Brake1=1;
					}
					break;
					case 2:
					{ // Throttle2
						PCA0CPM2 = 0; 
						Throttle2=1;
						Brake2=1;
					}
					break;
					case 3:
					{ // Throttle3
						PCA0CPM3 = 0; 
						Throttle3=1;
						Brake3=1;
					}
				}			
			
				break;
			}
	
			case CMD_SET_PORT_DOUT:
			{
				Out_Packet[0]=0; // cmd has been processed
				LedToggle();
				
				P1MDOUT= (Out_Packet[1]); // setting bit to 1 makes port pin push-pull, 0 makes it open drain
				P2MDOUT= (Out_Packet[2]);
				break;
			}

		} // switch
		EA=1; // enable interrupts
		//LedOn();
	} // while(1)
}


/*
// following ISR was only used for 16 bit PWM output which needed to be synchronized with PCA compare match; not needed for 8 bit 

// pwm interrupt vectored when there is a match interrupt for PCA: only then do we change PCA compare register
// pwm interrupt happens every 1us
void PWM_Update_ISR(void) interrupt 11
{
	EIE1 &= (~0x10); // disable PCA interrupt

	// Switch depending on interrupt source - this can either be from PCA counter overflow OR from
	// PCA comparator match for one of the PCA modules.
	// If the source is PCA counter overflow, the load the PCA counter reload value.
	// If the source is one of the PCA compare modules, then load that modules pwm value.

	switch(pwmNumber)
	{
		case 0:
			PCA0CPL0=pwml1;
			PCA0CPH0=pwmh1;
			PCA0CPM0 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x01); // clear CCF1 interrupt pending flag for PCA1
			break;
		case 1:
			PCA0CPL1=pwml2;
			PCA0CPH1=pwmh2;
			PCA0CPM1 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x02); // clear CCF2 interrupt pending flag for PCA2
			break;
		case 2:
			PCA0CPL2=pwml3;
			PCA0CPH2=pwmh3;
			PCA0CPM2 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x04); // clear CCF2 interrupt pending flag for PCA2
			break;
		case 3:
			PCA0CPL3=pwml4;
			PCA0CPH3=pwmh4;
			PCA0CPM3 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x08); // clear CCF2 interrupt pending flag for PCA2
	}
	EIE1 |= 0x10; // reenable PCA interrupt
}
 */

/* // following was used with wowwee RS control code
unsigned short bdata rsv2_cmd=0;
unsigned short rsv2_cyclesleft = 0;
unsigned char rsv2_cmdidx = 0; // idx+1
bit rsv2_sendcmd=0;
bit rsv2_precmd=0;
bit rsv2_firstbithalf=0;
bit rsv2_sendingone=0;
bit rsv2_startingbit=0;
*/



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
                                       // its maximum frequency (12MHz) and enable
                                       // missing clock detector

   CLKSEL  = SYS_INT_OSC;              // Select System clock
   CLKSEL |= USB_INT_OSC_DIV_2;        // Select USB clock
#else
   OSCICN |= 0x03;                     // Configure internal oscillator for
                                       // its maximum frequency
									   
 
   CLKMUL  = 0x00;                     // Select internal oscillator as
                                       // input to clock multiplier

   CLKMUL |= 0x80;                     // Enable clock multiplier
   Delay();                            // Delay for clock multiplier to begin
   CLKMUL |= 0xC0;                     // Initialize the clock multiplier
   Delay();                            // Delay for clock multiplier to begin

   while(!(CLKMUL & 0x20));            // Wait for multiplier to lock
   CLKSEL  = SYS_INT_OSC;              // Select system clock at osc/1=12MHz
   CLKSEL |= USB_4X_CLOCK;             // Select USB clock (48HHz)
#endif  /* _USB_LOW_SPEED_ */
}

void	Port_Init(void)
{  

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
//	XBR0 = 0x00;	// 0000 0000 Crossbar Register 1. no peripherals are routed to output.
//	XBR1 = 0xc3;	// 1000 0011 Crossbar Register 2. no weak pullups, cex0, cex1, cex2 routed to port pins.1100 0011	0xc3

	XBR0 = 0x00;	// Crossbar Register 1
	XBR1 = 0xC4;	// Crossbar Register 2
// Select Pin I/0

// NOTE: Some peripheral I/O pins can function as either inputs or 
// outputs, depending on the configuration of the peripheral. By default,
// the configuration utility will configure these I/O pins as push-pull 
// outputs.

// Setting microcontroller sbit value low (0) activates pulldown, which turns on optocoupler LED, which causes optocoupler output to pull low. Therefore
// outputs to SlotCarController power MOSFET gates are non-inverting. 
// To brake, set the brake bit to 1 (to turn on the brake N mosfet) and the throttle bit to 1 (to turn off the P throttle mosfet).
// To throttle, set brake bit to 0, which pulls brake N mosfet gate to ground.
 
                      // Port configuration (1 = Push Pull Output, 0=open drain; when value=1, then output does NOT pull down; when value=0 then pulldown is on)
    P0MDOUT = 0x00; // Output configuration for P0 
    P1MDOUT = 0x00; // Output configuration for P1  - all throttle/brake are open drain to optocoupler to pull against 100 ohm VBUS pullups
    P2MDOUT = 0x00; // Output configuration for P2  - all open drain
    P3MDOUT = 0x00; // Output configuration for P3 
     
    P0MDIN = 0xFF;  // Input configuration for P0          
    P1MDIN = 0xFF;  // Input configuration for P1
    P2MDIN = 0xFF;  // Input configuration for P2
    P3MDIN = 0xFF;  // Input configuration for P3

    P0SKIP = 0xFF;  //  Port 0 Crossbar Skip Register
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

/** this is a critical init that defines the timers and their reset values */
void	Timer_Init(void)
{
//----------------------------------------------------------------
// Timers Configuration
//----------------------------------------------------------------

    CKCON = 0x04;   // Clock Control Register: t0 clked by sysclk = 12MHz
    TMOD = 0x12;    // Timer Mode Register: timer0 8 bit with reload, timer1 16 bit
   	TCON = 0x50;    // Timer Control Register: timer0 and 1 running
    TH0 = 0xFF-1; 	// Timer 0 High Byte: reload value. 
				    // This is FF-n so timer0 takes n+1 cycles = to roll over, time is (n+1)*1/12us=1/6us, timer0 rolls over at 6MHz after reset
    TL0 = 0x00;     // Timer 0 Low Byte
 	
	CR=1;			// run PCA counter/timer
	// PCA uses timer 0 overflow which is 1us clock. all pca modules share same timer which runs at 1MHz.

	PCA0MD|=0x84;	// use timer0 overflow to clock PCA counter. leave wdt bit undisturbed. turn off PCA in idle.

	// change PCA0MD to change PCA clock source using bits CPS2:0 which are PCA0MD3:1.

	// pca pwm output frequency depends on pca clock source because pca counter rolls over
	// every 256 cycles. 

	// PCA0-3 are used for throttle MOSFET optocoupler input

	PCA0CPM0=0x00; 
	PCA0CPM1=0x00; 
	PCA0CPM2=0x00; 
	PCA0CPM3=0x00;
	
/*
	TMR3CN=4; // run timer3 for wowwee commands: 16 bit mode, autoreload, sysclk/12 clock
	TMR3RLL=0xff-13; // timer3 runs at sysclk/12 = 1MHz; to get an ISR call every 12.57us (corresponding to 1/(2*38.8kHz)) we need to reload the value 0xffff-12 into the reload registers
	TMR3RLH=0xff;
*/
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