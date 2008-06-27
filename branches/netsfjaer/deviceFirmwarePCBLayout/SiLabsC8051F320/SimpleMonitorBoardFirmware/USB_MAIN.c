/* 	Tobi Delbruck 28.1.05 

monitors address-events (AEs) captured using C8051F320 directly on Anton Civit's group's small USB board.

 on USB open from host, events are transmitted to host continuously, 
 are buffered in the host USBXPress USB driver (up to 64k=16kEvents) and are acquired into matlab with
 the usbaemon.dll matlab mex file.

 addresses are 16 bits
 timestamps are 16 bit and tick is 2us
 
 Because C51 Keil compiler is big-endian (MSB at lower mem 
 addresses) these are transmitted as 
 addr0highbyte,  addr0lowbyte, 
 ts0highbyte,  ts0lowbyte, 
 addr1highbyte, 
 etc....

 the AE buffer here is in XRAM and its size is defined in events
 
 address ports are defined below. presently they are P1 (AE0-7) and P2 (AE8-15)
 handshake pins are also defined below. presently they are 
	sbit	NOTREQ	= P0^0;		// !req line, input
	sbit	NOTACK	= P0^1;		// !ack line, output


	This example illustrates usage of the USB_API.lib
	DO NOT locate code segments at 0x1400 to 0x4000
	These are used for non-voltile storage for transmitted data.

additional notes from silabs developers re USBXPress:

The USB_SUSPEND function takes care of the USB peripheral and halts the system clock until USB activity resumes. 
You should power down any other peripherals you are using before making this call.

3. Block_Write should be called from an ISR because it 
cannot be interrupted by the library ISR. It uses bank 0 
(the default), but this limitation is due to indexed access 
method for the USB peripheral. It was not designed to be 
called from the main. It could be modified for this but it 
would take more code, and we have tried to make the library 
as small as possible.

4. The document is correct. The library is compiled with the 
small memory model, but every function has the large keyword 
to override this setting. This allows users to use the small 
memory model for their projects without any warnings, while 
making the library use as few resources as possible.

6. Calling Block_Write for a 64-byte write will return 
quickly if the fifo is empty. It will wait to write the data 
if you make the call before the transmit complete interrupt 
occurs. If you call Block_Write with a large amount of data, 
it will return when it has sent all data across the bus.


Note that here we call Block_Write from main after globally 
disabling interrupts. This may cause problems, but is the 
only sensible thing because we are AE-driven. When we have a 
buffer of events, we send them. If a storm of events comes, 
Block_Write will block until these have been loaded on the 
USB fifos. otherwise we collect events as rapidly as 
possible into our own buffer.


From the Keil compiler manual:

The 8051 is an 8-bit machine and has no instructions for 
directly manipulating data objects that are larger than 8 
bits.  Multi-byte data are stored according to the following 
rules.  

All other 16-bit and 32-bit values are stored, contrary to other Intel 
processors, in big endian format, with the high-order byte 
stored first.  For example, the LJMP and LCALL instructions 
expect 16-bit addresses that are in big endian format. 

If your 8051 embedded application 
performs data communications with other microprocessors, it 
may be necessary to know the byte ordering method used by 
the other CPU.  This is certainly true when transmitting raw 
binary data. 
*/


#pragma small code		// use small model, show assembly in .lst file

//	Include files
#include <c8051f320.h>		//	Header file for SiLabs c8051f320  
#include <stddef.h>			//	Used for NULL pointer definition
#include "USB_API.h"		//	Header file for USB_API.lib

// USB string identifier constants
// first element (num chars)*2+2
// 2nd element 3
//Univ Sevilla & ETH (18)
unsigned char code ManufacturerStr[]={38,0x03,'U',0,'n',0,'i',0,'v',0,' ',0,'S',0,'e',0,'v',0,'i',0,'l',0,'l',0,'a',0,' ',0,'&',0,' ',0,'E',0,'T',0,'H',0};
//USBAER (this shows up in Windows Device Manager under Other Devices if no driver is installed)
// this string is not returned when USBXPress device driver is loaded. Then product string is "USBXpress Device"
unsigned char code ProductStr[]={14,0x03,'U',0,'S',0,'B',0,'A',0,'E',0,'R',0};
// 10000
unsigned char code SerialNumberStr[]={12,0x03,'1',0,'0',0,'0',0,'0',0,'0',0};

//	Bit Definitions
// Note LEDs on small Sevilla board are on MSBs of port 2
// this is OK for retina because highest two bits driven from retina are 0 anyhow; only lowest 6 y bits are significant
sbit	LedRed	=	P2^6;	//	LED='1' means ON
sbit	LedYellow	=	P2^7;	//	These blink to indicate data transmission

sbit	NOTREQ	= P0^0;		// !req line, input
sbit	NOTACK	= P0^1;		// !ack line, output

//	Constants Definitions
#define MAX_BLOCK_SIZE_READ	64	//	Use the maximum read block size of 64 bytes
#define MAX_BLOCK_SIZE_WRITE 4096	//	Use the maximum write block size of 4096 bytes

//	Machine States
#define	ST_WAITING	0x01	//	Wait for application to open a device instance
#define	ST_ACTIVE	0x02	//	Connected, send events
#define AE_BUFFER_SIZE	225	// this is size of event buffer in events
							// each event takes 4 bytes consisting of 2 byte addr and 2 byte timestamp,
							// this is sized to almost fill xram of 1024 bytes. usbxpress uses some xram too.	
unsigned char xdata	AEBuffer[4*AE_BUFFER_SIZE];	//	Temporary storage of events, this is in XRAM
unsigned char xdata * data AEPtr;		// pointer to next write location. ptr in data, ptr to xdata
unsigned short	data AECounter;	// counter of bytes collected
unsigned char data lastXmitTime;	// to hold last timestamp, to send buffer even before it is full. this is char for just high byte of timer0

unsigned char	data	state;		//	Current Machine State

void	Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void	Timer_Init(void);			// Init timer to use for spike event times
//void	Suspend_Device(void);		//  Place the device in suspend mode

void sendEvents(void);


void initVariables(void){
	AEPtr=AEBuffer;		// reset AE buffer pointer and AE counter
	AECounter=0;
	NOTACK	=	1;		// start by not acknowledging, so that !req can come in
	lastXmitTime=TH0;	
	LedRed=0;			// we're not connected now
}


//-----------------------------------------------------------------------------
// Main Routine
// after initialization, the program simply polls the !req input and when 
// !req goes low, !ack on P0.1 is lowered to acknowledge, 
// the address is captured in P1 (AE0-7) and P2 (AE8-15) and is copied to XRAM.
// Then !ack is raised, we wait for !req to go high and start over.
// When we get an interrupt from USB, we transmit the existing buffer of data.
//-----------------------------------------------------------------------------
void main(void) 
{
	PCA0MD &= ~0x40;					//	Disable Watchdog timer
	//void USB_Init (int VendorID, int ProductID, uchar *ManufacturerStr,uchar *ProductStr, uchar *SerialNumberStr, byte MaxPower, byte PwAttributes, uint bcdDevice)
	// note that ProductID is important that windows hardware installation wizard can find the USBXPress driver
	// this driver must be preinstalled before plugging in device
	// see the Preinstaller but note that path in .ini file may need to be changed for preinstaller to locate driver files 
	// so that they can be copied to standard windows driver search folder for drivers.
	// this initVariables is for 60mA device, bus powered, serial number 1.00
	USB_Init (0, 0xEA61, ManufacturerStr, ProductStr, SerialNumberStr,30,0x80,0x0100);
	CLKSEL |= 0x02;		// system clock 24MHz (48MHz USB/2)
	RSTSRC	|=	0x02;	// power on reset
	IP=0x01; // ext int 0 high priority

	Port_Init();			//	Initialize crossbar and GPIO
	Timer_Init();			// Init Timer and Capture for event timing
	initVariables();
	state=ST_WAITING;
	USB_Int_Enable();					//	Enable USB_API Interrupts
	while (1){
		if(state==ST_ACTIVE){
		// measured acquisition time is about 14us per event between req low and ack high
			if( TH1==0xFF) {	// while polling req, check if we have wrapped timer1 since last transfer
				if(AECounter>0) 
					sendEvents(); 	// if so just send available events
			}
		}else if(state==ST_WAITING){
			// plain handshake cycle is about 1+/-0.2us
			LedYellow=0;	// waiting for !req
			while(NOTREQ==1); // wait for !req low
		
			LedYellow=1; 	// !req received
			NOTACK=0;	// lower acknowledge
			while(NOTREQ==0); // wait for req to go high 
			NOTACK=1;	// raise acknowledge, completing handshake
			LedYellow=0; 	// event finished
		}
	}
}

void sendEvents(){
//	EA=0; //USB_Int_Disable();	// disable USB interrupt while writing buffer to FIFO
	LedRed = 0;	// toggle LED on each packet
	EIE1 &= ~0x02; // disable usb int
	Block_Write((BYTE*)AEBuffer, AECounter*4);
	EIE1 |= 0x02;	// enable usb int
	AECounter=0;	// reset counter and pointer for event buffering
	AEPtr=AEBuffer;
	LedRed=1;
//	EA=1; //USB_Int_Enable();
}

void Timer_ISR(void) interrupt 1
{
	TH1=0;
	if(AECounter>0)
		sendEvents();
}

void Event_ISR(void) interrupt 0
{
	EX0=0; // disable external int0
	EIE1 &= ~0x02; // disable usb int
	// handshake and capture event into xram unless full
	LedYellow=1;	// got req

	NOTACK=0;	// lower acknowledge

	//note according to C51 compiler specs, shorts are stored big-endian, MSB comes first
	*AEPtr++=P2;	// AE8-15
	*AEPtr++=P1;	// AE07

	*AEPtr++=PCA0CPH0;	// captured PCA counter/timer MSB. This was captured by req low.
	*AEPtr++=PCA0CPL0;	// timer LSB.
					
	AECounter++;	// increment counter for events
	EA=1;			// reenable interrupts
	// USB_Int_Enable(); // using these functions increases cycle time to >8us


	while(NOTREQ==0); // wait for req to go high 
	NOTACK=1;	// raise acknowledge, completing handshake
	LedYellow=0; 	// event finished 
	if(AECounter==AE_BUFFER_SIZE){
		// when we have collected buffer, initiate transfer
		// during this 860us no handshaking is occurring
		sendEvents();
	}

	EIE1 |= 0x02; // enable usb int
	EX0=1; // enable external int0
}

//	ISR for USB_API, run when API interrupts are enabled, and an interrupt is received
//  no data transmission is initiated here except for reception. only state is set or counters are reset
void 	My_USB_ISR(void)	interrupt	16
{
//	BYTE msg;
	BYTE	INTVAL	=	Get_Interrupt_Source();	//	Determine type of API interrupts
	BYTE	receivedMsg[3];	// rcvd msg buffer, for later use in host commands

	if (INTVAL	&	RX_COMPLETE)				//	RX Complete, assume we should send data
	{
		Block_Read(&receivedMsg,3);	// on rcv, read all the data
										// we don't do anything with it now
		state	=	ST_ACTIVE;
		return;
	}
	if	(INTVAL	&	TX_COMPLETE)	// same for TX_COMPLETE, assume we are connected and should send events
	{
		TH1=0; 	// reset last transmission done time
		sendEvents(); // send all events gathered up to now
		state	=	ST_ACTIVE;	//	Go to active collection of events when done
		return;
	}
	// exceptional conditions
	if	(INTVAL	&	USB_RESET)					//	Bus Reset Event, go to Wait State
	{
		initVariables();
	}
	if	(INTVAL	&	DEVICE_OPEN)				//	Device opened on host, go to active state to send events
	{
		AEPtr=AEBuffer;			// reset data pointers
		AECounter=0;
		NOTACK	=	1;			// start by not acknowledging, so that !req can come in
		LedRed=1;				// we're active now
		EX0=1;					// enable event interupt
		state	=	ST_ACTIVE;
	}
	if	(INTVAL	&	DEVICE_CLOSE)				//	Device closed, wait for re-open. only handshake in this state
	{
		LedRed=0;				// we're not connected
		state	=	ST_WAITING;
	}
	if	(INTVAL	&	FIFO_PURGE)	//	Fifo purged on host side. This happens when user code calls
								// SI_FlushBuffers. Don't do anything here because most likely
								// there was a driver buffer overrun and user code is just resetting
								// the overrun flag after reading available event. 
								// Just go to active state no matter what
	{
		state	=	ST_ACTIVE;
	}
	if	(INTVAL	&	DEV_SUSPEND)					//	USB suspended, shut down
	{
		USB_Suspend();	// turn off internal oscillator until usb event comes again (p.118)
		AECounter=0;	// reset counter and pointer for event buffering
		AEPtr=AEBuffer;
	}

}


/*
AER tick is 1us. Achieved by using PCA to capture timestamp on req edge low.
PCA is clocked from timer0 overflow to give a 1us PCA counter clock tick. 
timer0 is programmed as 8 bit timer with automatic reload
of 8 bit value. timer0 is clocked from sysclk. sysclk is 24Mhz, so timer0 runs at 24MHz. therefore reload
value is 0xFF-23 so timer0 overflows and clocks PCA counter every 1us.
This timing has been verified with a function generator generating events down to 6us period.

In addition timer1 is used to ensure transfers happen every 32ms (30Hz) regardless of how many events have 
been captured. Otherwise host could wait a long time for a slow sender.
16 bit timer1 is set for sysclk/12=.5us*65k=32ms wrap. 
We check in event loop for timer1 high bit less than last value
captured at end of last USB transfer. This signals wrap of timer1 and time to send all available events.
*/

void	Timer_Init(void)
{
//----------------------------------------------------------------
// Timers Configuration
//----------------------------------------------------------------

    CKCON = 0x04; // t0 clked by sysclk=24MHz 0x00;   // Clock Control Register, timer 0 uses prescaled sysclk/12. sysclk is 24MHz.
    TMOD = 0x12;    // Timer Mode Register, timer0 8 bit with reload, timer1 16 bit
   	TCON = 0x50;    // Timer Control Register , timer0 and 1 running
    TH0 = 0xFF-23; 	    // Timer 0 High Byte, reload value. this is FE so that timer clocks FE FF 00, 2 cycles, 
    TL0 = 0x00;     // Timer 0 Low Byte
 	
	CR=1;			// run PCA counter/timer
	PCA0MD|=0x84;	// use timer0 overflow to clock PCA counter. leave wdt bit undisturbed. turn off PCA in idle.
	PCA0CPM0=0x10;	// negative edge on CEX0 captures PCA, which is req from sender
	
}

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

// Configure the XBRn Registers

	XBR0 = 0x00;	// Crossbar Register 1. no peripherals are routed to output.
	XBR1 = 0xC1;	// Crossbar Register 2. no weak pullups, xbar enabled, cex0 routed to port pins.
					// CEX0 should go to P0.0 because that is first pin on first port, which is also req from sender
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

    P0MDOUT = 0x02; // Output configuration for P0, bit 0 is req input, bit 1 is ack output.
    P1MDOUT = 0x00; // Output configuration for P2  // P1 is used for AE lsb 8 bits
    P2MDOUT = 0xC0; // Output configuration for P2  // bits 6 and 7 are LEDs but P2 is also used for AE. OK because retina only has 6 bits for Y
    P3MDOUT = 0x00; // Output configuration for P3 

    P0SKIP = 0x00;  //  Port 0 Crossbar Skip Register
    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register
    P2SKIP = 0x00;  //  Port 2 Crossbar Skip Register

// View port pinout

	// The current Crossbar configuration results in the 
	// following port pinout assignment:
	// Port 0
	// P0.0 = unassigned      (Open-Drain Output/Input)(Digital)
	// P0.1 = unassigned      (Push-Pull Output)(Digital)
	// P0.2 = unassigned      (Open-Drain Output/Input)(Digital)
	// P0.3 = unassigned      (Open-Drain Output/Input)(Digital)
	// P0.4 = unassigned      (Open-Drain Output/Input)(Digital)
	// P0.5 = unassigned      (Open-Drain Output/Input)(Digital)
	// P0.6 = unassigned      (Open-Drain Output/Input)(Digital)
	// P0.7 = unassigned      (Open-Drain Output/Input)(Digital)

    // Port 1
	// P1.0 = unassigned      (Open-Drain Output/Input)(Digital)
	// P1.1 = unassigned      (Open-Drain Output/Input)(Digital)
	// P1.2 = unassigned      (Open-Drain Output/Input)(Digital)
	// P1.3 = unassigned      (Open-Drain Output/Input)(Digital)
	// P1.4 = unassigned      (Open-Drain Output/Input)(Digital)
	// P1.5 = unassigned      (Open-Drain Output/Input)(Digital)
	// P1.6 = unassigned      (Open-Drain Output/Input)(Digital)
	// P1.7 = unassigned      (Open-Drain Output/Input)(Digital)

    // Port 2
	// P2.0 = unassigned      (Open-Drain Output/Input)(Digital)
	// P2.1 = unassigned      (Open-Drain Output/Input)(Digital)
	// P2.2 = unassigned      (Open-Drain Output/Input)(Digital)
	// P2.3 = unassigned      (Open-Drain Output/Input)(Digital)
	// P2.4 = unassigned      (Open-Drain Output/Input)(Digital)
	// P2.5 = unassigned      (Open-Drain Output/Input)(Digital)
	// P2.6 = unassigned      (Push-Pull Output)(Digital)
	// P2.7 = unassigned      (Push-Pull Output)(Digital)

    // Port 3
	// P3.0 = unassigned      (Open-Drain Output/Input)(Digital)

}
