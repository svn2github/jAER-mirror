/* 	copyright Tobi Delbruck 11.11.09

This is firmware for the PAER DVS retina board. 

tobi 12.9.12 -
Search below for DVS128_PAER. This section of code that translates data from port to addresses to be sent is
currently hardcoded for the PAER retina board.

tobi 25.10.2011 - 
added #define HANDSHAKE_ENABLED to use the NOTACK pin to handshake. This is needed on the Tmpdiff128 CAVIAR board when
the REQ-ACK pins are not shorted by a jumper. But not needed on the PAER board.
Enabling handshake slightly slows down the loop.

tobi 17.11.2009 -
Setup AEMonitor.wsp is for SiLabs IDE 3.8 with USBXPress 3.1.1. This setup will not work with previous versions of USBXPress,
which used a single .lib for all controllers. Now the included lib is USBX_F320_1.LIB.
Added USB_Clock_Init.
Changed USB_Init to set VID explicitly.
Changed host side code to use Thesycon USBIO driver. VID/PID are in inf file in drivers/driverUSBIO_Tmpdiff128_USBAERmini2.

This firmware is for DVS128_PAER_PCB_2009 board by Angel Jimenez Fernandez with Tobi Delbruck
designed in Zurich Oct 2009. This board is intended for AER system use of the DVS128.
The SiLabs supplies bias values to the DVS128 and sniffs the AER bus to send to the PC
a subsample of the DVS activity.  Therefore the SiLabs does NOT handshake with the 
DVS, but only tries to read the address when Request goes low.  Therefore some addresses will not be read
properly because they change during the read (under heavy activity).
Risk of race is minimized by caching 2 bytes of address before writing to USB FIFO.

The code directly writes to EP2 with double budffering enabled and avoids the Xram completely.

Monitors address-events (AEs) and controls an on-chip bias 
generator, based on Silicon Labs C8051F320 USB1 microcontroller.

 on USB open from host, events are transmitted to host continuously, 
 
 addresses are 16 bits
 timestamps are 16 bit and tick is 1us
 
 Because C51 Keil compiler is big-endian (MSB at lower mem 
 addresses) these are transmitted as 
 addr0highbyte,  addr0lowbyte, 
 ts0highbyte,  ts0lowbyte, 
 addr1highbyte, 
 etc....
 
 address ports are defined below.
 handshake pins are also defined below. 

additional notes from silabs developers re USBXPress:

The USB_SUSPEND function takes care of the USB peripheral and halts 
the system clock until USB activity resumes. 
You should power down any other peripherals you are using before making this call.


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
//#include <stddef.h>			//	Used for NULL pointer definition
#include <INTRINS.H>
#include "USB_API.h"		//	Header file for USB_API.lib
#include "Register.h"		//	Header file for the Register definitions
#include "USB_Main.h"

// USB string identifier constants
// first element (num chars)*2+2
// 2nd element 3
// INI (3*2+2=8)
unsigned char code ManufacturerStr[]={26,0x03,'i',0,'n',0,'i',0,'l',0,'a',0,'b',0,'s',0,' ',0,'G',0,'m',0,'b',0,'H',0};
//USBAER (this shows up in Windows Device Manager under Other Devices if no driver is installed)
// and is returned by USBIO driver as product string
#ifdef DVS128_PAER
unsigned char code ProductStr[]={24,0x03,'D',0,'V',0,'S',0,'1',0,'2',0,'8',0,'_',0,'P',0,'A',0,'E',0,'R',0};
#endif
#ifdef TMPDIFF128_CAVIAR
unsigned char code ProductStr[]={36,0x03,'T',0,'m',0,'p',0,'d',0,'i',0,'f',0,'f',0,'1',0,'2',0,'8',0,'_',0,'C',0,'A',0,'V',0,'I',0,'A',0,'R',0};
#endif

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

sbit	BIAS_CLOCK=P0^0;		// output, biasgen clock, put this high and low after biasbit change
sbit	BIAS_LATCH=P0^1;		// output, biasgen latch, active high to make latch opaque while loading new bits
sbit	BIAS_BITIN=P0^2;		// output, biasgen input bit (for chip, output bit from here), active high to enable current splitter output

sbit	BIAS_POWERDOWN=P0^3;	// output, biasgen powerDown input, active high to power down

// NOTACK defined as output when HANDSHAKE_ENABLED
sbit	NOTACK	= P0^4;			// input, !ack line, normally output but set as input since we only sniff events here
sbit	NOTREQ	= P0^5;			// input, !req line

sbit	LedUSB	=	P0^6;	//	this is L2 on DVS128_PAER board. USB activity output, LED='1' means ON, outer LED, "L2", indicates control commands, e.g. biases
sbit	LedAER	=	P0^7;	//	 this is L1. AER activity output, blinks to indicate AER activity or transmission, inner LED, "L1"

#define LedUSBOn() LedUSB=0;
#define LedUSBOff()  LedUSB=1;
#define LedUSBToggle() LedUSB=!LedUSB; // this is L2 on DVS128_PAER board
#define LedAEROn() LedAER=0;
#define LedAEROff() LedAER=1;
#define LedAERToggle() LedAER=!LedAER; // this is L1


#define VID 0x152a // Thesycon VID
#define PID 0x8411 // in range owned by jAER

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
//	Constants Definitions
#define MAX_PACKET_SIZE	64  //	Use the maximum read block size of 64 bytes as specified by the USB2.0 full speed specs

//unsigned char xdata * data AEPtr;		// pointer to next write location. ptr in data, ptr to xdata
unsigned short	data AEByteCounter;	// counter of bytes collected
//unsigned char data lastXmitTime;	// to hold last timestamp, to send buffer even before it is full. this is char for just high byte of timer0
unsigned char p1val, p2val; // to cache port values for stuffing USB fifo
bit isActive=0;					// bit that is true if USB open and transmitting events

// function prototypes
void	portInit(void);			//	Initialize Ports Pins and Enable Crossbar
void	timerInit(void);			// Init timer to use for spike event times
void delay(void);
void sendBiases(BYTE *);
void flashBiases(BYTE *);
void sendFlashedBiases();
void config(void); // from Config.c, generated by Config Wizard
void spiwritebyte(BYTE);
void initVariables(void);
void sendWrap();
void checkWrap();
void usbCommitByte(unsigned char);
void usbCommitPacket();

code unsigned char biasFlashValues[BIAS_FLASH_SIZE] _at_ BIAS_FLASH_START;  // code (flash memory) where we store the bias values

//typedef struct {			//	Structure definition of a flash memory page
//	BYTE	FlashPage[FLASH_PAGE_SIZE];
//}	PAGE;


// all ports have reset value 0xff, so we don't really need to set these if we set bits to 1
void initVariables(void){
	AEByteCounter=0;
	NOTACK	=	1;	 // not using ACK here when !HANDSHAKE_ENABLED (since either req-ack shorted on board or ack comes from external receiver) but set high to avoid open drain pulldown
//	lastXmitTime=TH0;	

	BIAS_LATCH=1;  		// bias latch opaque
	BIAS_POWERDOWN=0;	// powerup biasgen

	LedUSBOff();			// we're not connected now
	isActive=0;
}


void sendWrap(){
	EA=0;
	usbCommitByte(0xFF); // send address 0xFFFF for wrap
	usbCommitByte(0xFF);
	usbCommitByte(0);	// counter MSB, first down pipe TS =0 for wrap event
	usbCommitByte(0);	// counter LSB.
	EA=1;
}


#define checkWrap(); if(CF){CF=0;sendWrap();}

// These two routines are added to directly communicate with EP2 in which double buffering is enabled according
// to the default USB Express configurations


void usbCommitByte(unsigned char dat) // This function is called when a request to write data to the FIFO is detected

{
   EA=0;									// Disable interrupts
   POLL_WRITE_BYTE(FIFO_EP2, dat); 			// write one byte to EP2
   AEByteCounter++;  						// Increment our byte counter
   if(AEByteCounter==MAX_PACKET_SIZE)		// Checking if the FIFO is full
   {
      usbCommitPacket();					// Submitting a packet to the PC if the FIFO is full
   }
   EA=1; 									// Enable the Interrupts
}

void usbCommitPacket() // This function is called when we detect a request to write data to the FIFO
{
      unsigned char reg; 						
	//	LedUSBToggle();
	  EA=0;										// Disable the interrupts
	  POLL_WRITE_BYTE(INDEX, 2);				// Set up EP2 for communications
      POLL_WRITE_BYTE(EINCSR1, rbInINPRDY);		// Commit the Packet
	  EA=1;
	  do{
        POLL_READ_BYTE(EINCSR1, reg);			
		}
      while(reg & rbInINPRDY); 					// Wait until a new packet can be written.
      AEByteCounter=0;							// Reset the counter
	  TH1=0xB2;  // reset timer to 65k-20k so that timer1 counts 20k=10ms to overflow (roughly) to ensure min packet rate
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
	USB_Clock_Start();
	USB_Init (VID, PID, ManufacturerStr, ProductStr, SerialNumberStr,30,0x80,0x0100); // USBIO Thesycon VID. SiLabs DVS128 PID for Thesycon USBIO driver.

	CLKSEL |= 0x02;		// system clock 24MHz (48MHz USB/2)
	RSTSRC	|=	0x02;	// power on reset
	IP=0x01; // ext int 0 high priority ??

	timerInit();
	portInit();

	initVariables();

	// send the bias values from flash memory out the SPI port
	sendFlashedBiases();

	USB_Int_Enable();					//	Enable USB_API Interrupts

	while (1){
	if(isActive){
			while(NOTREQ==1) { // wait for !req low
				if( TF1==1 ){	// while polling req, check if we have wrapped timer1 since last transfer
					TF1=0;
					LedUSBToggle();  // flash USB led when timed xfers occur
					if(AEByteCounter>0){
						usbCommitPacket(); 	// if so just send available events
					} 
				}
				checkWrap();
			}
			LedAERToggle();	// got req
#ifdef HANDSHAKE_ENABLED // see USB_Main.h and make sure DVS128_PAER or TMPDIFF128 is chosen there!!!!!!!!!
			NOTACK=0;	// lower acknowledge
#endif
			EA=0; 	// disable interrupts during snapshot of AE to avoid USB interrupt during snapshot

			// On the DVS128_PAER_PCB_2009 board, the AE outputs from the DVS are wired up differently than in
			// the Tmpdiff128_CAVIAR (according to past convention).
			// The X bits + polarity are wired as though they were AE15:8 and the y bits Y6:0 are wired to AE6:0.
			// Therefore we swap the order of sending the bytes over USB here.
			// The PCB has X7:0 (X0 is polarity) are wired to AE15:8, and Y7:0 (Y7 is not used) are wired to AE7:0
			// The SiLabs has P1=AE7:0, P2=AE15:8. 
			// Therefore P1=Y7:0 and P2=X7:0
			
			//note according to C51 compiler specs, shorts are stored big-endian, MSB comes first.
			// We send the MSB first which are the Y address bits

// original PAER board has mistake of swapping bytes. On new rev from 2012 (marked that same unfortunately) this has been fixed.
// That's why below is commmented.
//#ifdef DVS128_PAER
			p1val=P1;
			p2val=P2;
//#else
//			p1val=P2;
//			p2val=P1;
//#endif

			usbCommitByte(p1val); // AE14:8, with bit 15 masked out, 7 bit y address	
			usbCommitByte(p2val);	// AE7:0 - 7 bit x address + 1 bit polarity (AE0)  // P2

			usbCommitByte(PCA0CPH0);	// captured PCA counter/timer MSB. This was captured by req low.
			usbCommitByte(PCA0CPL0);	// timer LSB.
							
			EA=1;			// reenable interrupts
	
#ifdef HANDSHAKE_ENABLED
// following disabled if we are sniffing (Req shorted to Ack on board)

			// if the device is powered off, then its req will be low (no power). so this code will come here and
			// will have lowered ack and stored a bogus address. now it will wait for req to go high. 
			// but req will be low from the device and won't go high
			// because ack is low. therefore we can get stuck here if the device is powered on after reset. 
			while(NOTREQ==0){ // wait for req to go high 
				checkWrap();
				if( TF1==1 ) {	// while polling req, check if we have wrapped timer1 since last transfer
					TF1=0;
					if(AEByteCounter>0){
						usbCommitPacket(); 	// if so just send available events
					} 
					break;			// break from possibly infinite loop. this will raise ack
				}
			}
			NOTACK=1;	// raise acknowledge, completing handshake
#endif
			//LedAEROff();	// got req

			// measured time from led on to off is 7 to 8 us
			// measured req low time is 100ns



		}else{	// isActive is false, USB not open, just handshake
			// plain handshake cycle is about 1+/-0.2us
			while(NOTREQ==1) { // wait for !req low
				if( TF1==1 ) {	// while polling req, check if we have wrapped timer1 since last transfer
					TF1=0;
				}
				
			}
		
			LedAEROn(); 	// !req received
			// this firmware does not handshake since it sniffs the addresses
#ifdef HANDSHAKE_ENABLED
			NOTACK=0;	// lower acknowledge
#endif
			while(NOTREQ==0){ // wait for req to go high 
				if( TF1==1 ) {	// while polling req, check if we have wrapped timer1 since last transfer
					TF1=0;
					break;			// break from possibly infinite loop
				}
				
			}
#ifdef HANDSHAKE_ENABLED
			NOTACK=1;	// raise acknowledge, completing handshake
#endif
			LedAEROff();
		}
	}
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

	EA_Save=EA;
	EA=0;	// diable interrupts -- inportant because spiwritebyte is also called from interrupt handler
//	SPIF=0;	// clr the transmit done flag (in case it was set somehow)
	x=0; 

	while(x++<numBytes){
		y= *pread;
		spiwritebyte(y); 
		//SPI0DAT = y;	// write out a byte
		//while(!SPIF);		// wait for it to be done
		//SPIF=0;				// reset the done flag
		pread++;
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

//-----------------------------------------------------------------------------
// Force_Stall
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : None
//
// Force a procedural stall to be sent to the host
//
//-----------------------------------------------------------------------------

void Force_Stall(void)
{
   POLL_WRITE_BYTE(INDEX, 0);
   POLL_WRITE_BYTE(E0CSR, rbSDSTL);       // Set the send stall bit
}


//-----------------------------------------------------------------------------
// Fifo_Read
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   :
//                1) BYTE addr : target address
//                2) unsigned int uNumBytes : number of bytes to unload
//                3) BYTE * pData : read data destination
//
// Read from the selected endpoint FIFO
//
//-----------------------------------------------------------------------------

void Fifo_Read(BYTE addr, unsigned int uNumBytes, BYTE * pData)
{
   int i;

   if (uNumBytes)                         // Check if >0 bytes requested,
   {
      USB0ADR = (addr);                   // Set address
      USB0ADR |= 0xC0;                    // Set auto-read and initiate
                                          // first read

      // Unload <NumBytes> from the selected FIFO
      for(i=0;i<uNumBytes-1;i++)
      {
         while(USB0ADR & 0x80);           // Wait for BUSY->'0' (data ready)
         pData[i] = USB0DAT;              // Copy data byte
      }

      USB0ADR = 0;                           // Clear auto-read

      while(USB0ADR & 0x80);               // Wait for BUSY->'0' (data ready)
      pData[i] = USB0DAT;                  // Copy data byte
   }
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
   	BYTE ControlReg;

	if (INTVAL	&	RX_COMPLETE)				//	RX Complete, assume we should send data
	{
		
		LedUSBToggle();

   		POLL_WRITE_BYTE(INDEX, 2);          // Set index to endpoint 2 registers
   		POLL_READ_BYTE(EOUTCSR1, ControlReg);

      if (ControlReg & rbOutSTSTL)     // Clear sent stall bit if last packet 
                                       // was a stall
      {
         POLL_WRITE_BYTE(EOUTCSR1, rbOutCLRDT);
      }

      POLL_READ_BYTE(EOUTCNTL, numBytes);
      Fifo_Read(FIFO_EP2, numBytes, (BYTE*)&receivedMsg);   
      POLL_WRITE_BYTE(EOUTCSR1, 0);    // Clear Out Packet ready bit

	//	numBytes=Block_Read(&receivedMsg,64);	// on rcv, read all the data
										// we don't do anything with it now
										// msg/command is always 64 bytes.
										// for now this simplifies things because message can just be processed here
		cmd=receivedMsg[0];
		if(numBytes==0||cmd==0){
			Force_Stall(); // command error
			return;
		}
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
			Force_Stall();
		}
		return;
	}
	if	(INTVAL	&	TX_COMPLETE)	// same for TX_COMPLETE, assume we are connected and should send events
	{
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
	// never gets here
		AEByteCounter=0;        // reset the byte counter
		LedUSBOn();				// we're active now
		isActive=1;
	}
	if	(INTVAL	&	DEVICE_CLOSE)				//	Device closed, wait for re-open. only handshake in this state
	{
	// never gets here
		LedUSBOff();				// we're not connected
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
		AEByteCounter=0;	// reset counter and pointer for event buffering
	}

}




