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
// this firmware is for implementing a simple sequencer that gets AE from the computer and sends them out using AER

// Tarek Massoud, Tobi Delbruck  jul 2008

//-----------------------------------------------------------------------------
// Includes
//-----------------------------------------------------------------------------

#include "c8051f320.h"
#include "F32x_USB_Register.h"
#include "F32x_USB_Main.h"
#include "F32x_USB_Descriptor.h"

idata BYTE Out_Packet[64];             // Last packet received from host
idata BYTE In_Packet[64];              // Next packet to sent to host
extern BYTE Ep_Status[];

void	Port_Init(void);			// Initialize Ports Pins and Enable Crossbar
void	Timer_Init(void);			// Init timer to use for spike event times
void	Usb0_Init(void);			//		


sbit	NOTREQ	= P0^1;		// !req line, input
sbit	NOTACK	= P0^0;		// !ack line, output
sbit	LedRed	=	P0^3;	//	LED='1' means ON
sbit	LedGreen	=	P0^4;	//	These blink to indicate data transmission
sbit	LedBlue	= P0^5;

//-----------------------------------------------------------------------------
// Main Routine
//-----------------------------------------------------------------------------
void main(void)
{
 	int i;
	LedRedOn();
   PCA0MD &= ~0x40;                    // Disable Watchdog timer
  Sysclk_Init();                      // Initialize oscillator
	Port_Init();			// Initialize Ports Pins and Enable Crossbar
	Timer_Init();			// Init timer to use for spike event times
	Usb0_Init();
	NOTREQ	=	1; // turn off request
	LedGreenOn();
	LedBlueOn();
	
   while (1)
   {
		if(Ep_Status[2]!=EP_RX){ // if not receiving data
			LedRedToggle();
			LedGreenToggle();
			LedBlueToggle();
		}
	   	for(i=0;i<1400;i++){
			Delay();
		} // about 1 second
   }
}



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
                                       // its maximum frequency and enable
                                       // missing clock detector

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


//-----------------------------------------------------------------------------
// Usb0_Init
//-----------------------------------------------------------------------------
// - Initialize USB0
// - Enable USB0 interrupts
// - Enable USB0 transceiver
// - Enable USB0 with suspend detection
//-----------------------------------------------------------------------------
void Usb0_Init(void)
{
   BYTE Count;
   EA=0; // disable all interrupts
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

    CKCON = 0x04; // t0 clked by sysclk=24MHz 0x00;   // Clock Control Register, timer 0 uses prescaled sysclk/12. sysclk is 24MHz.
    TMOD = 0x11;    // Timer Mode Register, timer0 and, timer1 16 bit 00010001
   	TCON = 0x50;    // Timer Control Register , timer0 and 1 running
    TH0 = 0x00; 	    // Timer 0 High Byte, reload value. this is FE so that timer clocks FE FF 00, 2 cycles, 
    TL0 = 0x00;     // Timer 0 Low Byte
 		
}

void	Port_Init(void)
{  

// P  1	212          O: bit 1 is ACK output, others are inputs (incl REQ on P0.0)
// P2: bit 6,7 are LEDs are outputs
// don't connect any internal functions to ports
// no weak pullups, no internal functions to ports

/*
Step 1.  Select the input mode (analog or digital) for all Port pins, using the Port Input Mode register (PnMDIN).
Step 2.  Select the output mode (open-drain or push-pull) for all Port pins, using the Port Output Mode register (PnMDOUT).
Step 3.  Select any pins to be skipped by the I/O Crossbar using the Port Skip registers (PnSKIP).
Step 4.  Assign Port pins to desired peripherals (XBR0, XBR1).
Step 5.  Enable the Crossbar (XBARE = ‘1’).
*/

// Configure the XBRn Registers

	XBR0 = 0x00;	// 0000 0000 Crossbar Register 1. no peripherals are routed to output.
	XBR1 = 0x00;	// 0000 0001 Crossbar Register 2. weak pullups enabled on open drain outputs and inputs, // NOT ANY MORE FOR SEQUENCER cex0 routed to port pins.

    P0MDIN = 0xFF;  // Input configuration for P0. Not using analog input.
    P1MDIN = 0xFF;  // Input configuration for P1
    P2MDIN = 0xFF;  // Input configuration for P2
    P3MDIN = 0xFF;  // Input configuration for P3

    P0MDOUT = 0x02; // Output configuration for P0, bit 0 is ack input, bit 1 is req output, 0000 0010, 
					// leds are bits 3,4,5 but are open drain, set bit low to pull down and turn on LED
    P1MDOUT = 0xFF; // Output configuration for P1  // P1 is used for AE lsb 8 bits
    P2MDOUT = 0xFF; // Output configuration for P2  // P2 is used for AE msb 8 bits
    P3MDOUT = 0x00; // Output configuration for P3 

    P0SKIP = 0x00;  //  0000 0001 Port 0 Crossbar Skip Register. // NOT ANY MORE, USED FOR MONITOR Skip first pin so that bit 1 (req) P0.1 becomes CEX0 input to PCA capture module

    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register
    P2SKIP = 0x00;  //  Port 2 Crossbar Skip Register


	XBR1|=0x40; 	// 0100 0000 enable xbar

}

void Delay(void)
{
   int x;
   for(x = 0;x < 500;x)
      x++;
}
