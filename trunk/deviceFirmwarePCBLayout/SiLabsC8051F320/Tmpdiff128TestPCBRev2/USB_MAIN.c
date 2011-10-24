/* 	copyright Tobi Delbruck 28.1.05, 10.19.05

This firmware is for Tmpdiff128TestPCB rev2, with fixes for SPI interface to biasgen.
It goes with PCB design in CAVIAR/wp1/PCBs/Tmpdiff128
Nov 2007, patrick/tobi

monitors address-events (AEs) and controls an on-chip bias 
generator, based on Silicon Labs C8051F320 USB1 microcontroller.

 on USB open from host, events are transmitted to host continuously, 
 are buffered in the host USBXPress USB driver (up to 64k=16kEvents) and are acquired into matlab with
 the java native interface (JNI) DLL through the java class SiLabsC8051F320.java.

 addresses are 16 bits
 timestamps are 16 bit and tick is 2us
 
 Because C51 Keil compiler is big-endian (MSB at lower mem 
 addresses) these are transmitted as 
 addr0highbyte,  addr0lowbyte, 
 ts0highbyte,  ts0lowbyte, 
 addr1highbyte, 
 etc....

 the AE buffer here is in XRAM and its size is defined in events
 
 address ports are defined below.
 handshake pins are also defined below. 

additional notes from silabs developers re USBXPress:

The USB_SUSPEND function takes care of the USB peripheral and halts 
the system clock until USB activity resumes. 
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


#pragma small code 
// optimize(speed)		// use small model, show assembly in .lst file

//	Include files
#include <c8051f320.h>		//	Header file for SiLabs c8051f320  
#include <stddef.h>			//	Used for NULL pointer definition
#include <INTRINS.H>
#include "USB_API.h"		//	Header file for USB_API.lib

// USB string identifier constants
// first element (num chars)*2+2
// 2nd element 3
// INI (3*2+2=8)
unsigned char code ManufacturerStr[]={8,0x03,'I',0,'N',0,'I',0};
//USBAER (this shows up in Windows Device Manager under Other Devices if no driver is installed)
// this string is not returned when USBXPress device driver is loaded. Then product string is "USBXpress Device"
unsigned char code ProductStr[]={14,0x03,'U',0,'S',0,'B',0,'A',0,'E',0,'R',0};
// 20000
unsigned char code SerialNumberStr[]={12,0x03,'2',0,'0',0,'0',0,'0',0,'0',0};

//	Bit Definitions

/*
>> biasClock  P0.0 (pin2)
>> biasBit  P0.2 (pin32)
>> biasLatch  P0.1 (pin1)
>> powerDown  P0.3 (pin31)
>> req  P0.5 (pin29)
>> ack  P0.4 (pin30)
>> LED0  P0.6 (pin28)
>> LED1  P0.7 (pin27)
*/

sbit	BIAS_CLOCK=P0^0;		// biasgen clock, put this high and low after biasbit change
sbit	BIAS_LATCH=P0^1;		// biasgen latch, active high to make latch opaque while loading new bits
sbit	BIAS_BITIN=P0^2;		// biasgen input bit (for chip, output bit from here), active high to enable current splitter output

sbit	BIAS_POWERDOWN=P0^3;	// biasgen powerDown input, active high to power down
sbit	NOTACK	= P0^4;		// !ack line, output
sbit	NOTREQ	= P0^5;		// !req line, input
sbit	LedGreen	=	P0^6;	//	LED='1' means ON
sbit	LedOrange	=	P0^7;	//	These blink to indicate data transmission
#define LedGreenOn() LedGreen=0;
#define LedGreenOff()  LedGreen=1;
#define LedGreenToggle() LedGreen=!LedGreen; // this probably doesn't work because it reads port and then writes opposite, but since all ports are tied together somewhat it may not work
#define LedOrangeOn() LedOrange=0;
#define LedOrangeOff() LedOrange=1;
#define LedOrangeToggle() LedOrange=!LedOrange;

// commands


#define CMDMSG_BIAS_SENDBIASES 1	// send biases out on SPI
#define CMDMSG_BIAS_SETPOWER 2	// set the biasgen powerDown input
#define CMDMSG_BIAS_FLASH 4	//  flash the biases

#define CMDMSG_SET_EVENT_ACQUISTION_ENABLED 5 // set isActive (whether or not to send events)
#define CMDMSG_RESETTIMESTAMPS 6  // reset the timestamps

//	Constants Definitions
#define	FLASH_PAGE_SIZE	512	        //	Size of each flash page
#define CMDMSG_MAXLENGTH 64 // these are command messages for controlling biasgen
#define MAX_BLOCK_SIZE_READ	64	//	Use the maximum read block size of 64 bytes
#define MAX_BLOCK_SIZE_WRITE 4096	//	Use the maximum write block size of 4096 bytes
#define BIAS_FLASH_START 0x2000 // start of flash memory for biases
								// the F320 has 16k flash, but top part is reserved so it really has from 0 to 0x3dff=15871
								// program memory is in lower part of flash.
								// it's not clear how to determine end of program/constant space from the compiler/linker
								// by looking at USBAEMON.m51 we can tell size of program
								// it is not possible using _at_ to specify memory contents, so initial values
								// may be crap.
#define BIAS_FLASH_SIZE FLASH_PAGE_SIZE	// size of bias value storage (this is size of flash page)
#define AE_BUFFER_SIZE	225	// this is size of event buffer in events
							// each event takes 4 bytes consisting of 2 byte addr and 2 byte timestamp,
							// this is sized to almost fill xram of 1024 bytes. usbxpress uses some xram too.	

// variables
unsigned char xdata	AEBuffer[4*AE_BUFFER_SIZE];	//	Temporary storage of events, this is in XRAM
unsigned char xdata * data AEPtr;		// pointer to next write location. ptr in data, ptr to xdata
unsigned short	data AECounter;	// counter of bytes collected
bit isActive=0;					// bit that is true if USB open and transmitting events

// function prototypes
void	Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void	Timer_Init(void);			// Init timer to use for spike event times
//void	Suspend_Device(void);		//  Place the device in suspend mode
void sendEvents(void);
void flushEvents(void);
void delay(void);
void sendBiases(BYTE *);
void flashBiases(BYTE *);
void sendFlashedBiases();
void config(void); // from Config.c, generated by Config Wizard
void spiwritebyte(BYTE);

code unsigned char biasFlashValues[BIAS_FLASH_SIZE] _at_ BIAS_FLASH_START;  // code (flash memory) where we store the bias values

//typedef struct {			//	Structure definition of a flash memory page
//	BYTE	FlashPage[FLASH_PAGE_SIZE];
//}	PAGE;


// all ports have reset value 0xff, so we don't really need to set these if we set bits to 1
void initVariables(void){
	AEPtr=AEBuffer;		// reset AE buffer pointer and AE counter
	AECounter=0;
	NOTACK	=	1;		// start by not acknowledging, so that !req can come in
	BIAS_LATCH=1;  		// bias latch opaque
	BIAS_POWERDOWN=0;	// powerup biasgen

	LedGreenOff();			// we're not connected now
}

//-----------------------------------------------------------------------------
// Main Routine
// after initialization, the program simply polls the !req input and when 
// !req goes low, !ack on is lowered to acknowledge, 
// the address is captured in P1 (AE0-7) and P2 (AE8-15) and is copied to XRAM.
// Then !ack is raised, we wait for !req to go high and start over.
// We initiate BlockWrite in main after disabling interrupts. This is not advised because
// device is not supposed to intiate transfers, but it works fine, at least in USBXPress v2.1
// Commands are handled in the USB ISR.
//-----------------------------------------------------------------------------
void main(void) 
{
	PCA0MD &= ~0x40;					//	Disable Watchdog timer

	/** SPI info
	18.1.4. Slave Select (NSS)
	The function of the slave-select (NSS) signal is dependent on the 
	setting of the NSSMD1 and NSSMD0 bits in the SPI0CN register. There are three 
	possible modes that can be selected with these bits:
	1.NSSMD[1:0] = 00: 3-Wire Master or 3-Wire Slave Mode: SPI0 operates in 3-wire mode, 
	and NSS is disabled. When operating as a slave device, SPI0 is always selected in 3-wire mode. 
	Since no select signal is present, SPI0 must be the only slave on the bus in 3-wire mode. 
	This is intended for point-to-point communication between a master and one slave.

	http://www.cygnal.org/ubb/Forum1/HTML/000157.html
	"The SPI0 is set in 3-wire single master mode."
	
	To configure the SPI to 3-wire mode, set it to 3-wire mode before attaching it to the crossbar. If this order is reversed, NSS signal is assigned overlapping on other peripheral pins.
	
	SPI0CN = 0x00; // 3-wire master mode
	XBR0 = 0x02; // attach SPI to crossbar
	*/

	config();

	/*
	3.1. USB_Init
	Description: Enables the USB interface and the use of Device Interface Functions. On return, the USB interface
	is configured, including the USB clock and memory. Neither the system or USB clock configurations
	should be modified by user software after calling the USB_Init function. See Appendix A for a
	complete list of SFRs that should not be modified after USB_Init is called. In addition, C8051F32x
	interrupts are globally enabled on the return of this function. User software should not globally disable
	interrupts (set EA = 0) but should enable/disable user configured interrupts individually using
	the interrupt's source interrupt enable flag.
	This function allows the user to specify the Vendor and Product IDs as well as a Manufacturer,
	Product Description and Serial Number string returned as part of the device's USB descriptor during
	the USB enumeration (connection).
	
	note that ProductID is important that windows hardware installation wizard can find the USBXPress driver
	this driver must be preinstalled before plugging in device
	see the Preinstaller but note that path in .ini file may need to be changed for preinstaller to locate driver files 
	so that they can be copied to standard windows driver search folder for drivers.
	this initVariables is for 60mA device, bus powered, serial number 1.00
	*/
	
	//void USB_Init (int VendorID, int ProductID, uchar *ManufacturerStr,uchar *ProductStr, uchar *SerialNumberStr, byte MaxPower, byte PwAttributes, uint bcdDevice)
	USB_Init (0, 0xEA61, ManufacturerStr, ProductStr, SerialNumberStr,30,0x80,0x0100);
	// very important, USB_Init should be called AFTER config() so that USB clock is setup correctly. 
	//Config doesn't deal with USB at all.

	CLKSEL |= 0x02;		// system clock 24MHz (48MHz USB/2)
	RSTSRC	|=	0x02;	// power on reset
	IP=0x01; // ext int 0 high priority ??

	LedOrangeOn();
	//SPIEN=1; // enable SPI interface -- leave it enabled so that output port SCK and MOSI don't float

	initVariables();


	isActive=0;
	USB_Int_Enable();					//	Enable USB_API Interrupts

	// send the bias values from flash memory out the SPI port
	sendFlashedBiases();

	while (1){
	if(isActive){
			while(NOTREQ==1) { // wait for !req low
				if( TH1==0xFF){	// while polling req, check if we have wrapped timer1 since last transfer
					if(AECounter>0){
						sendEvents(); 	// if so just send available events
					} 
				}
			}
			LedOrangeOn();	// got req
		
			NOTACK=0;	// lower acknowledge

			//USB_Int_Disable(); // using these functions increases cycle time to >8us
			EA=0; 	// disable interrupts during snapshot of AE to avoid USB interrupt during snapshot
			
			//note according to C51 compiler specs, shorts are stored big-endian, MSB comes first
			*AEPtr++=P2;	// AE8-15
			*AEPtr++=P1;	// AE07

			*AEPtr++=PCA0CPH0;	// captured PCA counter/timer MSB. This was captured by req low.
			*AEPtr++=PCA0CPL0;	// timer LSB.
							
			AECounter++;	// increment counter for events
			EA=1;			// reenable interrupts
			// USB_Int_Enable(); // using these functions increases cycle time to >8us

			// very important!!!!
			// check HERE if buffer is full so that last request is acknowledged and retina can take away its
			// request before the pause to transmit events over USB. during this transfer, the usb chip 
			// has acknowledged and the retina takes away its request, but it cannot generate a new request
			// until the USB chip takes away its ack, below.
			// if this is not done in this order, you get vertical streaks of events, because (hyppothesis)
			// the retina is not rapidly acknowledged and therefore it is still pulling down on the column req
			// line and pulling it to ground. this makes it easier for other pixels in the same column to generate
			// new events, compared with normally-timed handshake cyles. with the present timing scheme, the retina
			// is acknowledged with normal timing, and therefore the pixel takes away its request with normal timing.
			// this is the working hypothesis.
			if(AECounter==AE_BUFFER_SIZE){
				// when we have collected buffer, initiate transfer
				// during this 860us no handshaking is occurring
				sendEvents();
			}
		
			// if the retina is powered off, then its req will be low (no power). so this code will come here and
			// will have lowered ack and stored a bogus address. now it will wait for req to go high. 
			// but req will be low from the retina and won't go high
			// because ack is low. therefore we can get stuck here if the retina is powered on after reset. 
			while(NOTREQ==0){ // wait for req to go high 
				if( TH1==0xFF) {	// while polling req, check if we have wrapped timer1 since last transfer
					TH1=0;
					AECounter--;	// throw away that event
					break;			// break from possibly infinite loop. this will raise ack
				}
			}
			NOTACK=1;	// raise acknowledge, completing handshake
			LedOrangeOff();	// raised ack

//		}else if(state==ST_WAITING){
		}else{	// isActive is false, USB not open, just handshake
			// plain handshake cycle is about 1+/-0.2us
			while(NOTREQ==1) { // wait for !req low
				if( TH1==0xFF) {	// while polling req, check if we have wrapped timer1 since last transfer
					TH1=0;
					NOTACK=0;
					NOTACK=1;	// toggle ack an extra time in case we are stuck
				}
			}
		
			LedOrangeOn(); 	// !req received
			NOTACK=0;	// lower acknowledge
			while(NOTREQ==0){ // wait for req to go high 
				if( TH1==0xFF) {	// while polling req, check if we have wrapped timer1 since last transfer
					TH1=0;
					break;			// break from possibly infinite loop
				}
			}
			NOTACK=1;	// raise acknowledge, completing handshake
			LedOrangeOff();
		}
	}
}

// sends all accumulated events. if a xmit fifo is empty then this call returns in about 14us.
// it takes about 860us if we send 225 events.
void sendEvents(){
//	EA=0; //USB_Int_Disable();	// disable USB interrupt while writing buffer to FIFO
	EIE1 &= ~0x02; // disable USB interrupt
	Block_Write((BYTE*)AEBuffer, AECounter*4);
	EIE1 |= 0x02; // enable USB interrupt
	AECounter=0;	// reset counter and pointer for event buffering
	AEPtr=AEBuffer;
	TH1=0;
	TL1=0; // reset timer1 because we only want advance xfer if we haven't sent events when timer1 wraps from 0
//	EA=1; //USB_Int_Enable();
}

// loads the onchip biasgenerator with the biases stored in flash memory
void sendFlashedBiases(){
	unsigned char code * data pread;	// Read Pointer for program (code) memory (flash memory)
	BYTE data x; 	// counter	
	BYTE data y;	// debug
	BYTE data numBytes;		// will hold number of biases
	BYTE data EA_Save;

	// delay 20ms -- more than needed
//	while(TH1!=0xFF);  // delay for SPI to come up...?  this is neccessary after powerup or reset for SPI to function correctly.
					// but is not documented
//	while(TH1!=0x80);  // delay for SPI to come up...?  this is neccessary after powerup or reset for SPI to function correctly.
					// but is not documented

	// we use AE buffer to buffer flash values of biases so we can check them
	pread=biasFlashValues+1; 			// biases stored here
	numBytes=*biasFlashValues;			// 1st byte is number of bytes
/*
	x=0; 
	AEPtr=AEBuffer;
	while(x++<numBytes){
		*AEPtr=*pread;
		pread++;
		AEPtr++;
	}
*/
	EA_Save=EA;
	EA=0;	// diable interrupts -- inportant because spiwritebyte is also called from interrupt handler
//	SPIF=0;	// clr the transmit done flag (in case it was set somehow)
	x=0; 
/*
	AEPtr=AEBuffer;
*/
	while(x++<numBytes){
		y= *pread;
		spiwritebyte(y); 
		//SPI0DAT = y;	// write out a byte
		//while(!SPIF);		// wait for it to be done
		//SPIF=0;				// reset the done flag
		pread++;
/*
		AEPtr++;
*/
	}
	BIAS_LATCH=0;			// make the bias latches transparent
	_nop_();
	_nop_();
	_nop_();
	_nop_();
	_nop_();
	_nop_();
	BIAS_LATCH=1; 			// make latch opaque
	EA=EA_Save;	// reenable interrupts
	//SPIEN=0;				// disable SPI  -- always enabled so pins don't float
}

//	ISR for USB_API, run when API interrupts are enabled, and an interrupt is received
//  no data transmission is initiated here except for reception (OUT transfers). only state is set or counters are reset
void 	My_USB_ISR(void)	interrupt	16
{
//	BYTE msg;
	BYTE	INTVAL	=	Get_Interrupt_Source();	//	Determine type of API interrupts
	BYTE	data receivedMsg[CMDMSG_MAXLENGTH];	// rcvd msg buffer, for later use in host commands
	BYTE	data *bPtr;						// pointer for receivedMsg
	BYTE	EA_Save;					//	Used to save state of global interrupt enable
	BYTE	xdata* data	pwrite;			//	Write Pointer for program (code) memory (flash memory)
	BYTE	x;			
	BYTE	numBytes;
	BYTE	cmd;

	if (INTVAL	&	RX_COMPLETE)				//	RX Complete, assume we should send data
	{
		
		LedGreenToggle();
		numBytes=Block_Read(&receivedMsg,64);	// on rcv, read all the data
										// we don't do anything with it now
										// msg/command is always 64 bytes.
										// for now this simplifies things because message can just be processed here
		cmd=receivedMsg[0];
		switch(cmd){
		case CMDMSG_BIAS_SENDBIASES:
			// next byte is number of bytes to output on SPI
			/*
			Hi pingk,
			"SPIF" is set to a '1' by the SPI hardware whenever the SPI transaction has completed. You must clear the flag in software. Try the following:

			cs = 0; // assert CS signal
			SPI0CN |= 0x03; // enable SPI in master mode
			SPIF = 0; // clear end-of-transaction indicator
			SPI0DAT = reg_number; // transmit a byte
			while (!SPIF); // wait for transaction to complete
			SPIF = 0; // clear end-of-transaction indicator
			SPI0DAT = dataout; // transmit a byte
			while (!SPIF); // wait for transaction to complete
			SPI0CN = 0x00; // disable SPI
			cs = 1; // deassert CS signal
			*/
			EA_Save=EA;
			EA=0; 	// disable all interrupts
			//SPIEN=1; // enable SPI interface
			//SPIF=0;	// clr the transmit done flag (in case it was set somehow)
			x=0;
			numBytes=receivedMsg[1];
			bPtr=receivedMsg+2; 	// point to actual bias bytes
			while(x++<numBytes){
				spiwritebyte(*bPtr);
				//SPI0DAT=*bPtr;		// write out a byte
				//while(!SPIF);		// wait for it to be done
				//SPIF=0;				// reset the done flag
				bPtr++;
			}
			BIAS_LATCH=0;			// make the bias latches transparent  for a moment
			_nop_();
			_nop_();
			_nop_();
			_nop_();
			_nop_();
			_nop_();
			BIAS_LATCH=1; 			// make latch opaque
			//SPIEN=0;				// disable SPI
			EA=EA_Save;  			// enable all enabled interrupts
			break;
		case CMDMSG_BIAS_SETPOWER:
			BIAS_POWERDOWN=(receivedMsg[1]&1); // set the powerDown bit to the lsb of the argument
			break;
		case CMDMSG_BIAS_FLASH:
			// takes a message as sent by the host and writes the contained bias values to 
			// the flash memory for biases.
			// the message has contents
			// 1st byte is command
			// 2nd byte is number of bias bytes (must be less than 255)
			// following bytes are bias bytes
			// see http://www.cygnal.org/ubb/Forum7/HTML/000083.html
			// see http://www.cygnal.org/ubb/Forum1/HTML/000398.html for helpful hints about memory access for flash
			// see https://www.mysilabs.com/public/documents/tpub_doc/anote/Microcontrollers/Precision_Mixed-Signal/en/an129.pdf for the best app note for flash


			// erase the flash page
			EA_Save	=	EA;						//	Save current EA
			EA	=	0;							//	Turn off interrupts
			pwrite	=	biasFlashValues; // (BYTE xdata *)(Page_Address);	//	Set write pointer to Page_Address
			PSCTL	=	0x03;					//	Enable flash erase and writes
			FLKEY	=	0xA5;					//	Write flash key sequence to FLKEY
			FLKEY	= 	0xF1;
			*pwrite	=	0x00;					//	Erase flash page using a write command
			PSCTL	=	0x00;					//	Disable flash erase and writes

			// flash holds bias bytes in order. first byte is number of bias bytes.

			numBytes=1+(*(receivedMsg+1)); // 1+number of actual bias bytes. first byte is number of bytes.
			bPtr	=	receivedMsg+1; // point to numBytes followed by bytes // (BYTE *)(TempStorage);
			pwrite	=	biasFlashValues; // (BYTE xdata *)(PageAddress);
			PSCTL	=	0x01;					//	Enable flash writes
			for(x = 0;	x<numBytes;	x++)//	Write biases 512 bytes
			{
				FLKEY	=	0xA5;				//	Write flash key sequence
				FLKEY	=	0xF1;
				*pwrite	=	*bPtr;				//	Write data byte to flash

				bPtr++;						//	Increment pointers
				pwrite++;
			}
			PSCTL	=	0x00;					//	Disable flash writes
			EA	=	EA_Save;					//	Restore EA
			break;
		case CMDMSG_SET_EVENT_ACQUISTION_ENABLED:
			isActive=receivedMsg[1];
			break;
		case CMDMSG_RESETTIMESTAMPS:
			PCA0CPH0=0;
			PCA0CPL0=0;
			break;
		default: 
		// signal error condition by blinking LEDs
		// we can't use just write bytes because the back channel is used for events
//			long i;
//			int j;
//			for(j=0;j<30;j++){
//				LedOrangeOff();
//				LedGreenOff();
//				i=50000;
//				while(i-->0);
//					LedOrangeOn();
//					LedGreenOn();
//				}
//			}
			break;
		}
		return;
	}
	if	(INTVAL	&	TX_COMPLETE)	// same for TX_COMPLETE, assume we are connected and should send events
	{
		TH1=0;
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
		LedGreenOn();				// we're active now
		isActive=1;
	}
	if	(INTVAL	&	DEVICE_CLOSE)				//	Device closed, wait for re-open. only handshake in this state
	{
		LedGreenOff();				// we're not connected
		isActive=0;
	}
	if	(INTVAL	&	FIFO_PURGE)	//	Fifo purged on host side. This happens when user code calls
								// SI_FlushBuffers. Don't do anything here because most likely
								// there was a driver buffer overrun and user code is just resetting
								// the overrun flag after reading available event. 
								// Just go to active state no matter what
	{
		//state	=	ST_ACTIVE;
		isActive=1;
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

//void	Timer_Init(void)
//{
////----------------------------------------------------------------
//// Timers Configuration
////----------------------------------------------------------------
//
//    CKCON = 0x04; // t0 clked by sysclk=24MHz 0x00
//    TMOD = 0x12;    // Timer Mode Register, timer0 8 bit with reload, timer1 16 bit
//   	TCON = 0x50;    // Timer Control Register , timer0 and 1 running
//    TH0 = 0xFF-23; 	    // Timer 0 High Byte, reload value. this clocks 24 cycles so that it overflows every 1us
//    TL0 = 0x00;     // Timer 0 Low Byte
// 	
//	CR=1;			// run PCA counter/timer (PCA0CN, PCA0 run control)
//	PCA0MD|=0x84;	// use timer0 overflow to clock PCA counter. leave wdt bit undisturbed. turn off PCA in idle.
//	PCA0CPM0=0x10;	// negative edge on CEX0 captures PCA, which is req from sender
//	
//}

//void	Port_Init(void)
//{  
//
//// P  1	212          O: bit 1 is ACK output, others are inputs (incl REQ on P0.0)
//// P2: bit 6,7 are LEDs are outputs
//// don't connect any internal functions to ports
//// no weak pullups, no internal functions to ports
//
//// following from silabs config wizard 2.05 bundled as utility with IDE
//// Config template saved as ConfigWizardTemplate.dat
////----------------------------------------------------------------
//// CROSSBAR REGISTER CONFIGURATION
////
//// NOTE: The crossbar register should be configured before any  
//// of the digital peripherals are enabled. The pinout of the 
//// device is dependent on the crossbar configuration so caution 
//// must be exercised when modifying the contents of the XBR0, 
//// XBR1 registers. For detailed information on 
//// Crossbar Decoder Configuration, refer to Application Note 
//// AN001, "Configuring the Port I/O Crossbar Decoder". 
////----------------------------------------------------------------
//
///*
//Step 1.  Select the input mode (analog or digital) for all Port pins, using the Port Input Mode register (PnMDIN).
//Step 2.  Select the output mode (open-drain or push-pull) for all Port pins, using the Port Output Mode register (PnMDOUT).
//Step 3.  Select any pins to be skipped by the I/O Crossbar using the Port Skip registers (PnSKIP).
//Step 4.  Assign Port pins to desired peripherals (XBR0, XBR1).
//Step 5.  Enable the Crossbar (XBARE = ‘1’).
//*/
//
//// Configure the XBRn Registers
//	XBR0 = 0x00;	// 0000 0000 Crossbar Register 1. no peripherals are routed to output.
//	XBR1 = 0x81;	// 1000 0001 Crossbar Register 2. no weak pullups, cex0 routed to port pins.
//
//// Select Pin I/0
//
//// NOTE: Some peripheral I/O pins can function as either inputs or 
//// outputs, depending on the configuration of the peripheral. By default,
//// the configuration utility will configure these I/O pins as push-pull 
//// outputs.
//	// Port configuration (1 = Push Pull Output)
//    P0MDIN = 0xFF;  // Input configuration for P0. Not using analog input.
//    P1MDIN = 0xFF;  // Input configuration for P1
//    P2MDIN = 0xFF;  // Input configuration for P2
//    P3MDIN = 0xFF;  // Input configuration for P3
///*
//>> biasClock  P0.0 (pin2) output SCK
//>> biasLatch  P0.1 (pin1) output MOSI
//>> biasBit  P0.2 (pin32) output (MISO overdriven)
//>> powerDown  P0.3 (pin31) output
//>> ack  P0.4 (pin30) output
//>> req  P0.5 (pin29) input CEX0
//>> LED0  P0.6 (pin28) output
//>> LED1  P0.7 (pin27) output
//P0 1101 1111=0xdf
//*/
//
//    P0MDOUT = 0xdf; // Output configuration for P0 
//					// all bits are outputs except for req
//					// leds are bits 6,7 but are open drain, set bit low to pull down and turn on LED
//    P1MDOUT = 0x00; // Output configuration for P1  // P1 is used for AE lsb 8 bits
//    P2MDOUT = 0x00; // Output configuration for P2  // P2 is used for AE msb 8 bits
//    P3MDOUT = 0x00; // Output configuration for P3 
//
//
//
//    P0SKIP = 0x1f;  //  0000 0001 Port 0 Crossbar Skip Register. 
//					//  Skip first 5 pins so that P0.5 (6th bit) becomes CEX0 input to PCA capture module
//
//    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register
//    P2SKIP = 0x00;  //  Port 2 Crossbar Skip Register
//
//
//	XBR1|=0x40; 	// 0100 0000 enable xbar
//
//}
