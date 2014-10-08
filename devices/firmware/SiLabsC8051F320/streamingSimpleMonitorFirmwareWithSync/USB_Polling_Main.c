/* 	Tobi Delbruck 28.1.05 

monitors address-events (AEs) captured using C8051F320 directly on Anton Civit's group's small USB board.

This version includes a sync bit functionality for
generating a synthetic address on e.g., function generator input: for experiments using
externally generated LED inputs.  

The sync is (for historical reasons) on AE15 and only address bits 14:0 are sent; bits
15 is masked out of the AE address. The sync sends address 0xFFFE.

To handle slow event rates from the device, we also send special timestamp wrap events
with address 0xFFFF when the timestamp counter wraps. This allows unambigous unwrapping on the host
since we are guarenteed to know about the wrap, instead of relying on nonmonotonic 16 bit timestamps.
This option is enabled on the host by an option to the SiLabs java device class 

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




/* 

The code was modified in the Telluride 2007 workshop to get rid of the 900us pauses resulting from moving the

data from the Xram to the EPs

The code now directly writes to EP2 with double budffering enabled and avoids the Xram completely.

*/



#pragma small code		// use small model, show assembly in .lst file

//	Include files
#include <c8051f320.h>		//	Header file for SiLabs c8051f320  
#include <stddef.h>			//	Used for NULL pointer definition
#include "USB_API.h"		//	Header file for USB_API.lib
#include "Register.h"		//	Header file for the Register definitions
// USB string identifier constants
// first element (num chars)*2+2
// 2nd element 3
//Univ Sevilla & ETH (18)
unsigned char code ManufacturerStr[]={38,0x03,'U',0,'n',0,'i',0,'v',0,' ',0,'S',0,'e',0,'v',0,'i',0,'l',0,'l',0,'a',0,' ',0,'&',0,' ',0,'E',0,'T',0,'H',0};
//USBAER (this shows up in Windows Device Manager under Other Devices if no driver is installed)
// this string is not returned when USBXPress device driver is loaded. Then product string is "USBXpress Device"
unsigned char code ProductStr[]={14,0x03,'U',0,'S',0,'B',0,'A',0,'E',0,'R',0};
// 10000
unsigned char code SerialNumberStr[]={12,0x03,'1',0,'0',0,'0',0,'0',0,'2',0};

//	Bit Definitions

#define INI_BOARD
//#define SEVILLA_BOARD

#ifndef INI_BOARD
#ifndef SEVILLA_BOARD
	#error You need to define a board type
#endif
#endif

#ifdef INI_BOARD
	sbit	NOTREQ	= P0^1;		// !req line, input
	sbit	NOTACK	= P0^0;		// !ack line, output
	sbit	LedRed	=	P0^3;	//	LED='1' means ON
	sbit	LedGreen	=	P0^4;	//	These blink to indicate data transmission
	sbit	LedBlue	= P0^5;
	#define LedRedOn() LedRed=0;
	#define LedRedOff()  LedRed=1;
	#define LedRedToggle() LedRed=!LedRed; // this probably doesn't work because it reads port and then writes opposite, but since all ports are tied together somewhat it may not work
	#define LedGreenOn() LedGreen=0;
	#define LedGreenOff() LedGreen=1;
	#define LedGreenToggle() LedGreen=!LedGreen;
	#define LedBlueOn() LedBlue=0;
	#define LedBlueOff() LedBlue=1;
	#define LedBlueToggle() LedBlue=!LedBlue;
	sbit	SYNCBIT=P2^7; 	// special sync input bit - on this TestchipARCs pixel array test chip, we use a high order AE bit (Y6, AE14) as the external sync input

#else // sevilla board
	// Note LEDs on prototype small Sevilla board are on MSBs of port 2
	// this is OK for retina because highest two bits driven from retina are 0 anyhow; only lowest 6 y bits are significant
	sbit	NOTREQ	= P0^7;		// !req line, input
	sbit	NOTACK	= P0^6;		// !ack line, output
	sbit	LedRed	=	P0^0;	//	LED='1' means ON
	sbit	LedGreen	=	P0^1;	//	These blink to indicate data transmission
	#define LedRedOn() LedRed=1;
	#define LedRedOff() LedRed=0;
	#define LedRedToggle() LedRed=!LedRed;
	#define LedGreenOn() LedGreen=1;
	#define LedGreenOff() LedGreen=0;
	#define LedGreenToggle() LedGreen=!LedGreen;
	#define LedBlueOn() 		// only two LEDs so these do nothing
	#define LedBlueOff() 
	#define LedBlueToggle() 
#endif


//	Constants Definitions
#define MAX_PACKET_SIZE	64  //	Use the maximum read block size of 64 bytes as specified by the USB2.0 full speed specs

//	Machine States
#define	ST_WAITING	0x01	//	Wait for application to open a device instance
#define	ST_ACTIVE	0x02	//	Connected, send events
#define AE_BUFFER_SIZE	225	// this is size of event buffer in events
							// each event takes 4 bytes consisting of 2 byte addr and 2 byte timestamp,
							// this is sized to almost fill xram of 1024 bytes. usbxpress uses some xram too.	
//unsigned char xdata	AEBuffer[4*AE_BUFFER_SIZE];	//	Temporary storage of events, this is in XRAM
//unsigned char xdata * data AEPtr;		// pointer to next write location. ptr in data, ptr to xdata
unsigned short	data AEByteCounter;	// counter of bytes collected
unsigned char data lastXmitTime;	// to hold last timestamp, to send buffer even before it is full. this is char for just high byte of timer0

//unsigned char	data	state;		//	Current Machine State
bit isActive;					// bit that is true if USB open and transmitting events
bit data lastSyncBitValue;	// to hold last value of sync input, when this changes fire off special sync event

void	Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void	Timer_Init(void);			// Init timer to use for spike event times
//void	Suspend_Device(void);		//  Place the device in suspend mode

void usbCommitByte(unsigned char dat); // This is the function that writes directly to the end point
void usbCommitPacket(void); // This is the function that commits the contents of the Fifo to the host PC
void delay(void);

void initVariables(void){
	AEByteCounter=0;
	NOTACK	=	1;		// start by not acknowledging, so that !req can come in
	lastXmitTime=TH0;	

	LedRedOff();			// we're not connected now
}

// sends a sync address with value 0xFFFF (-1 in int16)
void sendSync(){
	BYTE tsl, tsh;
	tsl=PCA0L;// read pca counter low byte, this captures entire counter into snapshot register (si labs ref 20.1)
	tsh=PCA0H;
	LedBlueToggle();
	EA=0;
	usbCommitByte(0xFF); // send address 0xFFFE for sync
	usbCommitByte(0xFE);
	usbCommitByte(tsh);	// counter MSB, first down pipe
	usbCommitByte(tsl);	// counter LSB.
	EA=1;
}

void sendWrap(){
	EA=0;
	LedRedToggle();
	usbCommitByte(0xFF); // send address 0xFFFF for wrap
	usbCommitByte(0xFF);
	usbCommitByte(0);	// counter MSB, first down pipe TS =0 for wrap event
	usbCommitByte(0);	// counter LSB.
	EA=1;
}

void checkSync(){
	if(SYNCBIT!=lastSyncBitValue){
			if(lastSyncBitValue==0) sendSync(); // sync was low, rising edge sync
			lastSyncBitValue=SYNCBIT;
	}
}

void checkWrap(){
	if(CF){ // overflow of PCA counter
		CF=0;
		sendWrap();
	}
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
	Timer_Init();			// Init Timer and Capture for event timing. Init PCA peripheral before port init.
	Port_Init();			//	Initialize crossbar and GPIO
	initVariables();
	LedGreenOff();
	LedBlueOff();

	isActive=0;
	USB_Int_Enable();					//	Enable USB_API Interrupts
	while (1){
	if(isActive){
			while(NOTREQ==1) { // wait for !req low
				if( TH1==0xFF){	// while polling req, check if we have wrapped timer1 since last transfer
					if(AEByteCounter>0){
						usbCommitPacket(); 	// if so just send available events
					} 
				}
				checkSync();
				checkWrap();
			}
			LedGreenOn();	// got req
		
			NOTACK=0;	// lower acknowledge

			EA=0; 	// disable interrupts during snapshot of AE to avoid USB interrupt during snapshot
			
			//note according to C51 compiler specs, shorts are stored big-endian, MSB comes first

			usbCommitByte(P2&0x7f);	// AE14:8, with bit 15 masked out 
			usbCommitByte(P1);	// AE7:0

			usbCommitByte(PCA0CPH0);	// captured PCA counter/timer MSB. This was captured by req low.
			usbCommitByte(PCA0CPL0);	// timer LSB.
							
			EA=1;			// reenable interrupts
			
			// if the device is powered off, then its req will be low (no power). so this code will come here and
			// will have lowered ack and stored a bogus address. now it will wait for req to go high. 
			// but req will be low from the device and won't go high
			// because ack is low. therefore we can get stuck here if the device is powered on after reset. 
			while(NOTREQ==0){ // wait for req to go high 
				checkSync();
				checkWrap();
				if( TH1==0xFF) {	// while polling req, check if we have wrapped timer1 since last transfer
					TH1=0;
					break;			// break from possibly infinite loop. this will raise ack
				}
			}
			NOTACK=1;	// raise acknowledge, completing handshake
			LedGreenOff();	// got req


		}else{	// isActive is false, USB not open, just handshake
			// plain handshake cycle is about 1+/-0.2us
			while(NOTREQ==1) { // wait for !req low
				if( TH1==0xFF) {	// while polling req, check if we have wrapped timer1 since last transfer
					TH1=0;
					NOTACK=0;
					NOTACK=1;	// toggle ack an extra time in case we are stuck
				}
				
			}
		
			LedGreenOn(); 	// !req received
			NOTACK=0;	// lower acknowledge
			while(NOTREQ==0){ // wait for req to go high 
				if( TH1==0xFF) {	// while polling req, check if we have wrapped timer1 since last transfer
					TH1=0;
					break;			// break from possibly infinite loop
				}
				
			}
			NOTACK=1;	// raise acknowledge, completing handshake
			LedGreenOff();
		}
	}
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
		isActive=1;
		return;
	}
	if	(INTVAL	&	TX_COMPLETE)	// same for TX_COMPLETE, assume we are connected and should send events
	{
		TH1=0;
		isActive=1;
		return;
	}
	// exceptional conditions
	if	(INTVAL	&	USB_RESET)					//	Bus Reset Event, go to Wait State
	{
		initVariables();
	}
	if	(INTVAL	&	DEVICE_OPEN)				//	Device opened on host, go to active state to send events
	{
		AEByteCounter=0;        // reset the byte counter
		NOTACK	=	1;			// start by not acknowledging, so that !req can come in
		LedRedOn();				// we're active now
		isActive=1;
	}
	if	(INTVAL	&	DEVICE_CLOSE)				//	Device closed, wait for re-open. only handshake in this state
	{
		LedRedOff();				// we're not connected
		isActive=0;
	}
	if	(INTVAL	&	FIFO_PURGE)	//	Fifo purged on host side. This happens when user code calls
								// SI_FlushBuffers. Don't do anything here because most likely
								// there was a driver buffer overrun and user code is just resetting
								// the overrun flag after reading available event. 
								// Just go to active state no matter what
	{
		isActive=1;
	}
	if	(INTVAL	&	DEV_SUSPEND)					//	USB suspended, shut down
	{
		USB_Suspend();	// turn off internal oscillator until usb event comes again (p.118)
		AEByteCounter=0;	// reset counter and pointer for event buffering
	}

}

// toggles ACK down and up a few times to 'initialize' the sender in case it is powering up

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

/*
Step 1.  Select the input mode (analog or digital) for all Port pins, using the Port Input Mode register (PnMDIN).
Step 2.  Select the output mode (open-drain or push-pull) for all Port pins, using the Port Output Mode register (PnMDOUT).
Step 3.  Select any pins to be skipped by the I/O Crossbar using the Port Skip registers (PnSKIP).
Step 4.  Assign Port pins to desired peripherals (XBR0, XBR1).
Step 5.  Enable the Crossbar (XBARE = ‘1’).
*/

// Configure the XBRn Registers
#ifdef INI_BOARD
	XBR0 = 0x00;	// 0000 0000 Crossbar Register 1. no peripherals are routed to output.
	XBR1 = 0x81;	// 1000 0001 Crossbar Register 2. no weak pullups, cex0 routed to port pins.
#else 
	XBR0 = 0x00;	// Crossbar Register 1. no peripherals are routed to output.
	XBR1 = 0x81;	// Crossbar Register 2. no weak pullups, cex0 routed to port pins.
#endif

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

#ifdef INI_BOARD
    P0MDOUT = 0x01; // Output configuration for P0, bit 0 is ack output, bit 1 is req input, 0000 0001, 
					// leds are bits 3,4,5 but are open drain, set bit low to pull down and turn on LED
    P1MDOUT = 0x00; // Output configuration for P1  // P1 is used for AE lsb 8 bits
    P2MDOUT = 0x00; // Output configuration for P2  // P2 is used for AE msb 8 bits
#else // sevilla bd
    P0MDOUT = 0x43; // Output configuration for P0, bit 7 is req input, bit 6 is ack output 0100 0000, LEDs are bits 0&1
    P1MDOUT = 0x00; // Output configuration for P1  // P1 is used for AE lsb 8 bits
    P2MDOUT = 0x00; // Output configuration for P2  // bits 6 and 7 are LEDs but P2 is also used for AE. OK because retina only has 6 bits for Y
#endif
    P3MDOUT = 0x00; // Output configuration for P3 



#ifdef INI_BOARD
    P0SKIP = 0x01;  //  0000 0001 Port 0 Crossbar Skip Register. Skip first pin so that bit 1 (req) P0.1 becomes CEX0 input to PCA capture module
#else 
    P0SKIP = 0x7F;  //  0111 1111 Port 0 Crossbar Skip Register. skip first 7 pins so that P0.7 (8th) (NOTREQ) becomes CEX0 input to PCA capture module
#endif

    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register
    P2SKIP = 0x00;  //  Port 2 Crossbar Skip Register


	XBR1|=0x40; 	// 0100 0000 enable xbar

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

// These two routines are added to directly communicate with EP2 in which double buffering is enabled according
// to the default USB Express configurations


void usbCommitByte(unsigned char dat) // This function is called when a request to write data to the FIFO is detected

{
   AEByteCounter++;  						// Increment our byte counter
   EA=0;									// Disable interrupts
   POLL_WRITE_BYTE(FIFO_EP2, dat); 			// write one byte to EP2
   EA=1; 									// Enable the Interrupts
   if(AEByteCounter==MAX_PACKET_SIZE)		// Checking if the FIFO is full
   {
      usbCommitPacket();					// Submitting a packet to the PC if the FIFO is full
   }
}

void usbCommitPacket() // This function is called when we detect a request to write data to the FIFO
{
      unsigned char reg; 						
	  EA=0;										// Disable the interrupts
	  POLL_WRITE_BYTE(INDEX, 2);				// Set up EP2 for communications
      POLL_WRITE_BYTE(EINCSR1, rbInINPRDY);		// Commit the Packet
	  EA=1;
	  do{
        POLL_READ_BYTE(EINCSR1, reg);			
		}
      while(reg & rbInINPRDY); 					// Wait until a new packet can be written.
      AEByteCounter=0;							// Reset the counter
}
