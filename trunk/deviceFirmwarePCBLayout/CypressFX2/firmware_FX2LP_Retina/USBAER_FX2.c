#pragma NOIV               // Do not generate interrupt vectors
//#pragma SRC // use this to generate asembly code, INSTEAD of object file (will not compile then)

/* this is firmware 'main' (actual main is in fw.c) for AE monitor firmware for FX2
This uVision project, when built, generates hex and binary firmware files of the following
hex -- the intel hex format file
bix -- the binary file to download as soft firmware
iic -- the binary file for EEPROM load on USB AE Monitor board

the generation of the binary firmware files is done by the Cypress tool hex2bix in c:\cypress\bin.
From its command line help 

C:\Cypress\USB\Bin>hex2bix -h
Intel Hex file to EZ-USB Binary file conversion utility
Copyright (c) 1997-1999, Cypress Semiconductor Inc.

HEX2BIX [-AIBRH?] [-S symbol] [-M memsize] [-C Config0Byte] [-F firstByte] [-O f
ilename] Source

    Source - Input filename
    A      - Output file in the A51 file format
    B      - Output file in the BIX file format (Default)
    BI     - Input file in the BIX file format (hex is default)
    C      - Config0 BYTE for AN2200 and FX2 (Default = 0x04)
    F      - First byte (0xB0, 0xB2, 0xB6, 0xC0, 0xC2) (Default = 0xB2)
    H|?    - Display this help screen
    I      - Output file in the IIC file format
    M      - Maximum memory size, also used as BIX out file size. (Default = 8k)

    O      - Output filename
    P      - Product ID (Default = 2131)
    R      - Append bootload block to release reset
    S      - Public symbol name for linking
    V      - Vendor ID (Default = 0x0547)

C:\Cypress\USB\Bin>

These command are run automatically in the project from the 
project 'output' options for target 1 (right click on 
target) The switch for the bix file needs to be -b -M 8000 
to generate a binary bix file for 8k ram (default of 8kB in 
help is incorrect, it is actually 64kB)

Address bus is PortB (AE0-7) and PortD (AE8-15).
/REQ is on RDY1 (pin 5 on 128 package)
/AERACK is on CTL0 (pin 69 on 128)
/CLKACK is on CTL1 (pin 70 on 128)
	/CLKACK is actually an output-enable for enabling the mux that muxes addresses from the sender and timestamps from the counter

This file was based originally on the cypress example 
FX2_to_extsyncFIFO.c which used the FlowState feature of the 
GPIF. here this flowstate feature is not used and only 
normal GPIF functionality is used. The FX2 is the FIFO 
master and 'requests' data from the AE sender by making 
\AERACK high. when the sender lowers \REQ, a set of states 
is marched through to capture the address and then the 
timestamp.

In addition, early transfers are committed at least every 10.1ms.

A number of vendor requests are supported -- see DR_VendorCmnd function

*/

// The Ez-USB FX2LP/FX1 registers are defined here. We use lpregs.h for register 
// address allocation by using "#define ALLOCATE_EXTERN". 
// When using "#define ALLOCATE_EXTERN", you get (for instance): 
// xdata volatile BYTE OUT7BUF[64]   _at_   0x7B40;
// Such lines are created from lp.h by using the preprocessor. 
// Incidently, these lines will not generate any space in the resulting hex 
// file; they just bind the symbols to the addresses for compilation. 
// You just need to put "#define ALLOCATE_EXTERN" in your main program file; 
// i.e. fw.c or a stand-alone C source file. 

// only define ALLOCATE_EXTERN in one file, others will use extern
#define ALLOCATE_EXTERN

#include "lp.h"
#include "lpregs.h"
#include "syncdly.h"            // SYNCDELAY macro, see Section 15.14 of FX2 Tech.
                                // Ref. Manual for usage details.
#include "biasgen.h"

// following for bug in original cypress header file fx2regs.h
//sfr AUTOPTRH1     = 0x9A;
//sfr AUTOPTRL1     = 0x9B;

#define EXTFIFONOTFULL   GPIFREADYSTAT & bmBIT1
#define EXTFIFONOTEMPTY  GPIFREADYSTAT & bmBIT0

#define GPIFTRIGRD 4

#define MSG_TS_RESET 1	// this is message sent on EP1 IN to tell host to reset timestamp wrap counter
#define RESETFIFO FIFORESET=0x80;SYNCDELAY;FIFORESET=0x06;SYNCDELAY;FIFORESET=0x00; // reset EP6

#define GPIF_EP2 0
#define GPIF_EP4 1
#define GPIF_EP6 2
#define GPIF_EP8 3

#define SERIAL_ADDR		0x50 // this is address of serial EEPROM

extern BOOL GotSUD;             // Received setup data flag
extern BOOL Sleep;
extern BOOL Rwuen;
extern BOOL Selfpwr;

BYTE Configuration;                 // Current configuration
BYTE AlternateSetting;              // Alternate settings
BOOL in_enable=FALSE;             // flag to enable IN transfers, AEs sent to host. 
					// Must be set FALSE for proper init, otherwise transfers start before endpoint it set up on host. 
BOOL enum_high_speed = FALSE;       // flag to let firmware know FX2 enumerated at high speed
BOOL early_transfer = FALSE;		// flog that verndor request sets (host) to trigger early trasnfer of availble AE data

BYTE			DB_Addr;					// Dual Byte Address stat
BYTE			I2C_Addr;					// I2C address

xdata unsigned int cycleCounter; // used for heartbeat, this is 16 bit int, max 65k
xdata unsigned int numBiasBytes; // number of bias bytes saved
xdata unsigned char biasBytes[255]; // bias bytes values saved here

// define retina and board-specific bits for tmpdiff128FX2 board
// biasgen pins and bits are defined in biasgen.c

sbit tsReset=IOA^0;		// tsReset=0 to reset timestamp counter 
sbit arrayReset=IOA^1;	// arrayReset=0 to reset all pixels

sbit led0=IOA^6;		// led=0 to turn it ON, 1 to turn off
sbit led1=IOA^7;
sbit timestampClock=IOA^7;  // this was the led1, but we must use it for timestamp clocking because this rev of FX2LP doesn't
					// have T1OUT coming out, instead sysclk comes out there. so instead we timer1 interrupt every 10u and in firmware
					// clock the timestamp counter.

unsigned char transactionCount;

//-----------------------------------------------------------------------------
// Task Dispatcher hooks
//   The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------

void GpifInit ();

void EEPROMWrite(WORD addr, BYTE length, BYTE xdata *buf); //TPM EEPROM Write
void EEPROMRead(WORD addr, BYTE length, BYTE xdata *buf);  //TPM EEPROM Read
void EEPROMWriteByte(WORD addr, BYTE value);

void TD_Init(void)             // Called once at startup
{

	// set the CPU clock to 24MHz
	CPUCS = ((CPUCS & ~bmCLKSPD) | bmCLKSPD0);
	CPUCS=(CPUCS& ~bmCLKOE); // disable CLKOUT on CLKOUT pin

	// set renum so that we dont renumerate every time firmware is downloaded.
	//USBCS=USBCS & bmRENUM;
	 
	// clear renum so that we renumerate every time firmware is downloaded.
	//USBCS=USBCS & ~bmRENUM;

	// set up port pins

	// INT0# on PA0 will be used later for timestamp external reset input

	// initialize IO ports
	PORTACFG = 0x00; //Turn off special functions for all port A
					// this still leaves INT0# listening on A.0 because it is an input function
	OEA =0xfe;  // all bits are outputs except for bit A.0 which is tsReset which is input with pullup resistor

	biasInit();	// init biasgen ports and pins

	EZUSB_InitI2C();

	// init port pins for board and retina
	led0=0;		// turn ON led
	
	
	arrayReset=1;	// un-reset all the pixels
	


	SYNCDELAY;

	// there are two endpoints used besides the control endpoint.
	// EP6 is the AE IN endpoint, 4x512
	// EP1 is an IN endpoint used for the device to send status information to the host, e.g.
	//    to reset the timestamp wrap counter

	EP1INCFG=0xA0;  // EP1 valid, bulk endpoint
	SYNCDELAY;

//	EP2CFG = 0xA0;     // EP2OUT, bulk, size 512, 4x buffered
//	SYNCDELAY;
	EP2CFG = 0x00;     // EP2 not valid
	SYNCDELAY;
	EP4CFG = 0x00;     // EP4 not valid
	SYNCDELAY;
	EP6CFG = 0xE0;     // EP6IN, bulk, size 512, 4x buffered
	SYNCDELAY;
	EP8CFG = 0x00;     // EP8 not valid
	SYNCDELAY;


	FIFORESET = 0x80;  // set NAKALL bit to NAK all transfers from host
	SYNCDELAY;
//	FIFORESET = 0x02;  // reset EP2 FIFO
//	SYNCDELAY;
	FIFORESET = 0x06;  // reset EP6 FIFO
	SYNCDELAY;
	FIFORESET = 0x00;  // clear NAKALL bit to resume normal operation
	SYNCDELAY;

//	EP2FIFOCFG = 0x01; // allow core to see zero to one transition of auto out bit
//	SYNCDELAY;
//	EP2FIFOCFG = 0x11; // auto out mode, disable PKTEND zero length send, word ops
//	SYNCDELAY;
	EP6FIFOCFG = 0x09; // auto in mode, disable PKTEND zero length send, word ops
	SYNCDELAY;

	GpifInit (); // initialize GPIF registers
	SYNCDELAY;
	IFCONFIG&=0xfb;  // make sure IFCONFIG.2 is zero to workaround feature/bug in GPIF designer.
	// the timestamps come from a 16 bit counter that is clocked by T1OUT/PE1
	// this IFCONFIG.2 bit controls whether GPIF takes over PortE pins for debug output.
	// forcing it to 0 ensures that T1OUT can come out to drive the counter.
	// the designer may turn these on in GPIF designer but then our counter timer clock output won't work
	// Three GPIF State lines, GSTATE[2:0], are available
	// as an alternate configuration of PORTE[2:0].
	// These default to general-purpose inputs; setting GSTATE (IFCONFIG.2) to 1
	// selects the alternate configuration and overrides PORTECFG[2:0] bit settings.

	// Only one FIFO flag at a time may be made available to the GPIF as a control input. 
	// The FS1:FS0 bits select which flag is made available to GPIF engine for controlling states.
	//	EP2GPIFFLGSEL = 0x01; // For EP2OUT, GPIF uses EF flag
	SYNCDELAY;
	EP6GPIFFLGSEL = 0x02; // For EP6IN, GPIF can use FF flag
	SYNCDELAY;


	// timers: timer1 is used for generating the 100kHz clock output to clock the timestamp counters.
	//		it was the intention to use the timer1 overflow output on a pin if we had the Cypress part that brings out timer1 overflow to a port pin.
	//		instead, we generate an internal 10us interrupt that we service in an ISR to toggle the timestamp counter clock.
	//      we use one of the LEDs (leaving it off the board) to do this now.
	// 		on the revised board we directly tie the port pin to the timestamp counter reset.

	//         timer0 is used to trigger advance (periodic) transfers of events

	// setup timers
	TMOD = 0x21;	//timers mode, timer1 8 bit with reload, timer0 16 bit

	// disable timer interrupt for timer0, which is used for advance transfers
	ET1 = FALSE;	//disble interrupt T1


	// timer 1 generates a 100kHz clock for the external 16 bit counter that makes the timestamp for each event
	// this was meant to come out on the T1OUT pin but the
	// 56 pin FX2LP part number CY7C68013A-56PVXC that we have does NOT have T1OUT coming to a port pin! (the 15A part has it, but the 15A
	// doesn't seem to be in production in the 56pin DIP package..., at least tobi couldn't find a supplier

	//PORTECFG = bmT1OUT;	//set PORTE.1 as T1OUT output -- not useful for our part
	//TH1 = 0x00; // set TH1 reload for longest possible overflow condition -- this generates an interrupt every 127us, i.e. 255-x generates interrupt every x/2 us
	//TH1=0xFE;	//set TH1 reload for 1MHz output ie 255-2/2
	// sysclock is 24MHz, and CKCON.4 is 0 and TMOD.6=0, so timer 1 is clocked by sysclock/12=2MHz
	TH1 = 255-19; // set TH1 reload to clock 20 cycles for overflow, this is 20 times 1/2 us or 10us interrupt. in practice it is (10 +- 0.5)us
	
	ET1=1; // enable timer1 interrupt. this will call ISR_Timer1 interrupt

	TR1 = 1;   // run timer T1

	// timer 0 is also used on rollover to generate advance transfers of events so that we don't need to always wait for
	// 128 events before committing them. this is done in TD_Poll routine.
	// timer 0 is 16 bit counter so it will roll over every 64k counts
	TR0=1; // timer0 enabled (this is bitaddressable CKCON bit)
	
	CKCON|=0x08; // clock timer 0 every sysclk/4=6MHz, timer 1 every sysclk/12. sysclk=24MHz. Timer0 16 bit will overflow every 10.1ms, 
	SYNCDELAY;

	// now we set up the external interrupt for the timestamp reset pin. This pin can be pulled low externally to 
	// do an instantaneous reset of the timestamp counters on the board. At the same time, pulling this pin
	// low generates an interrupt that sends a status message back to the host to reset the timestamp wrap counter
	// tsReset is pin A^0.
	// the interrupt vector is 0x0003
	EX0=0;		// disable interrupt for tsReset, or we'll trigger it here in software
	IT0=1;		// set TCON.0 so that INT0# is edge triggered low (rather than level low) to make sure that intterupt is seen even if pulse is short
	tsReset=0;
	_nop_();
	_nop_();	// 2 nop here makes about 1/2 us pulse
	tsReset=1;
	IE0=0;		// clear any pending interrupt INT0#
	EX0=1;		// reenable INT0#, this will trigger interrupt on low going edge of A.0


} // TD_init

void TD_Poll(void){

	// autoin=1, so fifo buffer is autocommitted when full, but after transaction is completed, a new one needs to be
	// initiated by setting a transaction count and triggering the GPIF engine.
	// here we are using AUTOIN mode, where the autoin length has been set by the SetConfiguration command 
	// received from host.
	
	// 10.4.4  GPIF Flag Selection. The GPIF can examine the 
	//	PF, EF, or FF (of the current FIFO) during a waveform. 
	//	One of the three flags is selected by the FS[1:0] bits 
	//	in the EPxGPIFFLGSEL register; that selected flag is 
	//	called the GPIF Flag.
	// 10.4.5  GPIF Flag Stop
	//  When EPxGPIFPFSTOP.0 is set to 1, FIFO-Read and -Write 
	//	transactions are terminated by the assertion of the GPIF 
	//	Flag. When this feature is used, it overrides the 
	//	Transaction Counter; the GPIF waveform terminates (sets 
	//	DONE to 1) only when the GPIF Flag asserts. No special 
	//	programming of the Waveform Descriptors is necessary, 
	//	and FIFO Waveform Descriptors that transition through 
	//	the Idle State on each transaction (i.e., waveforms that 
	//	don’t use the Transaction Counter) are unaffected. 
	//	Automatic throttling of the FIFOs in IDLE still occurs, 
	//	so there’s no danger that the GPIF will write to a full 
	//	FIFO or read from an empty FIFO. Unless the firmware 
	//	aborts the GPIF transfer by writing to the GPIFABORT 
	//	register, only the GPIF Flag assertion will terminate 
	//	the waveform and set the DONE bit. A waveform can 
	//	potentially execute forever if the GPIF Flag never 
	//	asserts. 
		/*
		15.15 Synchronization Delay
	Under certain conditions, some read and write accesses to EZ-USB registers must be separated by a synchronization delay.
	The delay is necessary only under the following conditions:
	¦ Between a write to any register in the 0xE600-0xE6FF range and a write to one of the registers in Table 15-6.
	¦ Between a write to one of the registers in Table 15-6 and a read from any register in the 0xE600-0xE6FF range.
	*/

	if(!in_enable){
		if(cycleCounter++==50000){
	 		led0=!led0;
			cycleCounter=0; // this makes a slow heartbeat on the LED to show firmware is running
		}
	}else{ // if IN transfers are enabled

/*		// clock the timestamp counter in main loop
		if(TF1){
			// timer 1 has rolled over, so clock the timestamp counters
			timestampClock=0;
			_nop_();
			_nop_();
			_nop_();
			timestampClock=1;
			TF1=0;
		}
*/

		// handle advance xfers
		if(TF0 || early_transfer){ // if overflow timer0 flag set or xfer has been called for
			led0=0; led0=1;
			if(!(EP2468STAT&0x20)){ // EP6 USB Fifo full flag is zero (ok to commit a packet to USB domain now
											// meaning endpoint buffer is available to commit to. as stated below,
											// EP2468STAT refers to FIFO under control of 8051/USB domain, not the one
											// presently in peripheral domain

				//led0=0;_nop_();_nop_();_nop_();_nop_();_nop_();_nop_();led0=1;
				TR0=0;	// stop timer0 for now
				early_transfer=0; // reset semaphore set from vendor request		
				//EP6GPIFPFSTOP|=1; // set the EP6 GPIF stop transaction bit
								// GPIF does NOT stop immediately, it would stop when GPIF flag is asserted.
								// This GPIF flag is selected by EP6GPIFFLGSEL.
								// This flag was set in TD_Init to be the EP6 FIFO FF (full flag).
								// IMPORTANT: Using the GPIF flag overrides the transaction counter, used in the GPIF to 
								// terminate the waveform. Therefore we do NOT need it here. We leave it in comments
								// as guidance.
								// Actually we now immediately abort GPIF as well, with GPIFABORT
				//SYNCDELAY;
	
				// following GPIFABORT necessary, if we don't have it, then packets are sent with nonsense values for addresses
				// and timestamps
				GPIFABORT=0xFF; // abort any GPIF transaction happening now because we timed out or are forcing xfer
				SYNCDELAY;
				INPKTEND=0x06; // force commit of EP6 In
				SYNCDELAY; // must delay so GPIFTRIG read is OK
				TF0=0; // clear timer0 overflow
				TH0=0;
				TL0=0; // reset timer0 to zero (it should already be there though)
	
				TR0=1; // (re)start timer0
			} // we don't do advance transfer unless the host can take it, we keep checking until host is free
		}
		
		// read the FIFO transaction counter, it it has increased by at least one FIFO size, i.e. bit 1 of
		// of the GPIF byte counter has changed since the last check, then reset the 
		// early transfer timer
/*
		if(GPIFTCB1 < transactionCount-1){ // if byte 1 of transaction counter has decreased by at least 2 (512 bytes) then reset early xfer timer
			led0=0; led0=1;
			TR0=0;
			TH0=0;
			TL0=0;
			TR0=1; // reset timer0, because we just finished a transaction. we don't want to fire early transfer until 
					// this timeout since the last one actually finished
			transactionCount=GPIFTCB1; // save byte 1 of transaction counter
		}
*/
		// start a new fifo read transaction if the GPIF is done with 512 bytes (128 events)
		if ( GPIFTRIG & 0x80 ) { // if GPIF interface IDLE, we finished the previous transaction of 128 events (hispeed)
				
				// if ever timer 0 overflows and we GPIFABORT and INPKTEND, then from then on, GPIF is NEVER done!
				// we never call the following code
				//led0=0; // led on
				TR0=0;
				TF0=0;
				TH0=0;
				TL0=0;	// reset timer0, because we just finished a transaction. we don't want to fire early transfer until 
						// this timeout since the last one actually finished
				TR0=1;
				
				// spin here waiting for free FIFO to launch new transaction
				while ( ( EP68FIFOFLGS & 0x01 ) ){
					//led0=1; // the GPIF is done with a transaction, but we must wait for a free FIFO to give it to start a new one
				}

				// EP6 fifo free to launch transaction

				// page 15.8. this is EP6 slave FIFO FF (full flag) 
				// if EP6 FIFO is not full, so there is room to start a FIFO read transaction using GPIF
				// is this different to EP2468&0x20?  not clear.
				// i think this refers to the slave FIFO for EP6, while EP2468STAT refers to the endpoint itself... but still not clear
				// from cypress discussion forum: 
				// http://www.cypress.com/portal/server.pt/gateway/PTARGS_0_601877_739_205_211_43/http%3B/sjapp20/cf_apps/design_supports/forums/messageview.cfm?catid=77&threadid=12605
				// Depending on the domain that has access to the FIFO, 
				// different registers are used to query the FIFO status. 
				// The EP2468FIFOFLGS register indicates the status of the FIFO under the control of the 
				// peripheral domain. EP2468STAT register is used to indicate the status of the FIFOs 
				// under the control of the 8051 domain.
				// see the cypress doc Endpoint FIFO Architecture of EZ-USB FX1/FX2

				if(enum_high_speed){
					GPIFTCB1 = 0x02; // setup big tranaction // setup transaction count (512 bytes/2 for word wide -> 0x0100)
					SYNCDELAY;
					GPIFTCB0 = 0x00;
					SYNCDELAY;
				}else{
					GPIFTCB1 = 0x00; // setup transaction count (64 bytes/2 for word wide -> 0x20)
					SYNCDELAY;
					GPIFTCB0 = 0x20;
					SYNCDELAY;
				}
				//					Setup_FLOWSTATE_Read();           // setup FLOWSTATE registers for FIFO Read operation
				//					SYNCDELAY;
				GPIFTRIG = GPIFTRIGRD | GPIF_EP6; // launch/trigger GPIF FIFO READ Transaction to EP6 FIFO
				SYNCDELAY;
				//led0=1; // led off
		} // gpif idle 
	} // in_enable
} // TD_Poll

// resume and suspend handling are not functional now

BOOL TD_Suspend(void)          // Called before the device goes into suspend mode
{
   	xdata int i;
	for(i=0;i<numBiasBytes;i++){
		spiwritebyte(0);
	} // set all the biases to zero current
	return(TRUE);
}

BOOL TD_Resume(void)          // Called after the device resumes
{
   	xdata int i;
	for(i=0;i<numBiasBytes;i++){
		spiwritebyte(biasBytes[i]);
	} // set all the biases back to saved values
   return(TRUE);
}

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------

BOOL DR_GetDescriptor(void)
{
   return(TRUE);
}

BOOL DR_SetConfiguration(void)   // Called when a Set Configuration command is received
{
  if( EZUSB_HIGHSPEED( ) )
  { // FX2 enumerated at high speed
    SYNCDELAY;                  // 
    EP6AUTOINLENH = 0x02;       // set AUTOIN commit length to 512 bytes
    SYNCDELAY;                  // 
    EP6AUTOINLENL = 0x00;
    SYNCDELAY;                  
    enum_high_speed = TRUE;
    }
  else
  { // FX2 enumerated at full speed
    SYNCDELAY;                   
    EP6AUTOINLENH = 0x00;       // set AUTOIN commit length to 64 bytes
    SYNCDELAY;                   
    EP6AUTOINLENL = 0x40;
    SYNCDELAY;                  
    enum_high_speed = FALSE;
  }

  Configuration = SETUPDAT[2];
  return(TRUE);            // Handled by user code
}

BOOL DR_GetConfiguration(void)   // Called when a Get Configuration command is received
{
   EP0BUF[0] = Configuration;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_SetInterface(void)       // Called when a Set Interface command is received
{
   AlternateSetting = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}

BOOL DR_GetInterface(void)       // Called when a Set Interface command is received
{
   EP0BUF[0] = AlternateSetting;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_GetStatus(void)
{
   return(TRUE);
}

BOOL DR_ClearFeature(void)
{
   return(TRUE);
}

BOOL DR_SetFeature(void)
{
   return(TRUE);
}


// here are vendor specific commands, i.e. AE monitor commands
// DR_VendorCmnd is called from main polling loop. The USB setup data is in SETUPDAT
// and the data itself, up to 64 bytes, is in EP0, which is a bidirectional buffer.
// to acknowledge the vendor command, the FX2 firmware must write the command back, along
// with reply data.

// the SETUPDAT array has the following 8 elements (see FX2 TRM Section 2.3)
//SETUPDAT[0] VendorRequest 0x40 for OUT type, 0xC0 for IN type
//SETUPDAT[1] The actual vendor request (e.g. VR_ENABLE_AE_IN below)
//SETUPDAT[2] wValueL 16 bit value LSB
//         3  wValueH MSB
//         4  wIndexL 16 bit field, varies according to request
//         5  wIndexH
//         6  wLengthL Number of bytes to transfer if there is a data phase
//         7  wLengthH

//#define VX_B2 0xB2 // reset the external FIFO
#define VR_ENABLE_AE_IN 0xB3 // enable IN transfers
#define VR_DISABLE_AE_IN 0xB4 // disable IN transfers
#define VR_READ_GPIFREADYSTAT 0xB5 // read GPIFREADYSTAT register
#define VR_READ_GPIFTRIG 0xB6 // read GPIFTRIG register
#define VR_TRIGGER_ADVANCE_TRANSFER 0xB7 // trigger in packet commit (for host requests for early access to AE data)

#define VR_WRITE_BIASGEN 0xB8 // write bytes out to SPI
				// the wLengthL field of SETUPDAT specifies the number of bytes to write out (max 64 per request)
				// the bytes are in the data packet
#define VR_SET_POWERDOWN 0xB9 // control powerDown. wValue controls the powerDown pin. Raise high to power off, lower to power on.
#define VR_EEPROM_BIASGEN_BYTES 0xBa // write bytes out to EEPROM for power on default
#define VR_RESETTIMESTAMPS 0xBb // reset the timestamp counters
#define VR_SETARRAYRESET 0xBc // set the state of the array reset
#define VR_DOARRAYRESET 0xBd // toggle the array reset low long enough to reset all pixels
//#define VR_WRITE_EEPROM 0xBe // write the eeprom with arbitrary data
#define VR_SET_LED 0xbf // set the LED state

#define BIAS_FLASH_START 9 // start of bias value (this is where number of bytes is stored

// following from Vend_Ax Cypress example, used in EEPROM and RAM download and upload
#define	VR_UPLOAD		0xc0
#define VR_DOWNLOAD		0x40
#define VR_EEPROM		0xa2 // loads (uploads) EEPROM
#define	VR_RAM			0xa3 // loads (uploads) external ram

#define EP0BUFF_SIZE	0x40 // 64 bytes for this control endpoint
				
// these vendor requests are constucted and sent from the host using the USBIO ClassOrVendorOutRequest method

BOOL DR_VendorCmnd(void)
{
	WORD		addr, len, bc;
	WORD i;

	// the retina board tmpdiff128FX2 has EEPROM 24LC64, 64K 2-byte address part

	// FX2 sets I2CS register on boot to show what type of EEPROM is attached. ID bits 4:3 are 10 for 16 bit EEPROM. TRM 15.8.5.
	// SERIAL_ADDR=0x50= b0101 0000
	// ((I2CS & 0x10) >> 4) will be 1 for dual byte device, 0 for single byte device

	// (see TRM 13.4.1) The EEPROM itself has slave address 1010 followed by device address, in this case since it
	// is a 2-byte address EEPROM the device address is 001. The whole device address is thus
	// b x1010001 where x is the direction bit determined by writing or reading. Thus the device address used
	// is 0x5y where y is 1 for us, because we use 2-byte EEPROM, thus address is 0x50 | 1.

	// Determine I2C boot eeprom device address; 
	I2C_Addr = SERIAL_ADDR | ((I2CS & 0x10) >> 4); // lsb addr = 0x0 for 8 bit addr eeproms (24LC00), lsb addr=0x01 for 16 bit addr eeprom (LC65)
	// Indicate if it is a dual byte address part; this var used in EEPROMWriteByte
	DB_Addr = (BOOL)(I2C_Addr & 0x01); 

	// Indicate if it is a dual byte address part
	//DB_Addr = (BOOL)(I2C_Addr & 0x01); //TPM: ID1 is 16 bit addr bit - set by rocker sw or jumper

	switch (SETUPDAT[1]){
		case VR_ENABLE_AE_IN: // enable IN transfers
			{
				in_enable = TRUE;

				*EP0BUF = VR_ENABLE_AE_IN;  // send back one byte to acknowledge -- the same as vendor request byte
				EP0BCH = 0;	// byte count high
				EP0BCL = 1;	// byte count low
				EP0CS |= bmHSNAK;
				break;
			}
		case VR_DISABLE_AE_IN: // disable IN transfers
			{
				in_enable = FALSE;

				*EP0BUF = VR_DISABLE_AE_IN;
				EP0BCH = 0;
				EP0BCL = 1;
				EP0CS |= bmHSNAK;
				break;
			}
		case VR_READ_GPIFREADYSTAT: // read GPIFREADYSTAT register
			{
				EP0BUF[0] = VR_READ_GPIFREADYSTAT;
				SYNCDELAY;
				EP0BUF[1] = GPIFREADYSTAT;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 2;
				EP0CS |= bmHSNAK;
				break;
			}
		case VR_READ_GPIFTRIG: // read GPIFTRIG register
			{
				EP0BUF[0] = VR_READ_GPIFTRIG;
				SYNCDELAY;
				EP0BUF[1] = GPIFTRIG;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 2;
				EP0CS |= bmHSNAK;
				break;
			}
		case VR_TRIGGER_ADVANCE_TRANSFER:	// set flag to commit buffer even if not yet full
			{
				early_transfer=TRUE; // semaphore that is reset in TD_Poll
				*EP0BUF = VR_TRIGGER_ADVANCE_TRANSFER;		// return this byte as acknowledgement of command
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 1;                   // Arm endpoint with # bytes to transfer
				EP0CS |= bmHSNAK;             // Acknowledge handshake phase of device request
				break;
			}
		case VR_WRITE_BIASGEN: // write bytes to SPI interface
		case VR_EEPROM_BIASGEN_BYTES: // falls through and actual command is tested below
			{
				SYNCDELAY;
				addr = SETUPDAT[2];		// Get address and length
				addr |= SETUPDAT[3] << 8;
				len = SETUPDAT[6];
				len |= SETUPDAT[7] << 8;
				numBiasBytes=len;
				while(len){					// Move new data through EP0OUT, one packet at a time
					// Arm endpoint - do it here to clear (after sud avail)
					EP0BCH = 0;
					EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
					while(EP0CS & bmEPBUSY);  // spin here until data arrives
					bc = EP0BCL; // Get the new bytecount
					// Is this a  download to biasgen shift register?
					if(SETUPDAT[1] == VR_WRITE_BIASGEN){
						for(i=0; i<bc; i++){
							spiwritebyte(EP0BUF[i]);
							biasBytes[i]=EP0BUF[i];
						}
					}else{ // we write EEProm starting at addr with bc bytes from EP0BUF
						//					EEPROMWrite(addr,bc,(WORD)EP0BUF);
					}
					addr += bc;	// inc eeprom addr to write to, in case that's what we're doing
					len -= bc; // dec total byte count
				}
				if(SETUPDAT[1]==VR_WRITE_BIASGEN) {
					latchNewBiases();
					//setLatchTransparent(); // let values pass through latch from shift register -- these are new values
					//setLatchOpaque();
				}
				EP0BCH = 0;
				EP0BCL = 0;                   // Arm endpoint with 0 byte to transfer
				break; // very important, otherwise get stall
			}
		case VR_SET_POWERDOWN: // control powerDown output bit
			{
				setPowerDownBit(SETUPDAT[2]);
				*EP0BUF=VR_SET_POWERDOWN;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 1;                   // Arm endpoint with 1 byte to transfer
				EP0CS |= bmHSNAK;             // Acknowledge handshake phase of device request
				break; // very important, otherwise get stall

			}
		case VR_RESETTIMESTAMPS: // reset external timestamp counters by  tsReset low/high
			{
				EX0=0;		// disable interrupt for tsReset, or we'll trigger it here in software
				OEA =0xff;  // all bits are outputs here including bit A.0 which is tsReset which is normally input with pullup resistor
				tsReset=0;
				_nop_();
				_nop_();	// 2 nop here makes about 1/2 us pulse
				tsReset=1;
				OEA=0xfe;	// A.0 is input again so another board can pull it low
				IE0=0;		// clear any pending interrupt INT0#
				RESETFIFO;	// reset data fifo
				EX0=1;		// reenable INT0#
				*EP0BUF=VR_RESETTIMESTAMPS;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 1;                   // Arm endpoint with 1 byte to transfer
				EP0CS |= bmHSNAK;             // Acknowledge handshake phase of device request
				break; // very important, otherwise get stall

			}
		case VR_SETARRAYRESET: // set array reset, based on lsb of argument
			{
				arrayReset=SETUPDAT[2]&1;
				*EP0BUF=VR_SETARRAYRESET;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 1;                   // Arm endpoint with 1 byte to transfer
				EP0CS |= bmHSNAK;             // Acknowledge handshake phase of device request
				break; // very important, otherwise get stall

			}
		case VR_DOARRAYRESET: // reset array for fixed reset time
			{
				arrayReset=0;
				_nop_();
				_nop_();
				_nop_();
				_nop_();
				_nop_();
				_nop_();
				_nop_();
				_nop_();	// a few us
				_nop_();
				_nop_();
				_nop_();
				_nop_();
				_nop_();
				_nop_();
				arrayReset=1;
				*EP0BUF=VR_DOARRAYRESET;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 1;                   // Arm endpoint with 1 byte to transfer
				EP0CS |= bmHSNAK;             // Acknowledge handshake phase of device request
				break; // very important, otherwise get stall

			}
		case VR_SET_LED: // set array reset, based on lsb of argument
			{
				led0=SETUPDAT[2]&1;
				*EP0BUF=VR_SET_LED;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 1;                   // Arm endpoint with 1 byte to transfer
				EP0CS |= bmHSNAK;             // Acknowledge handshake phase of device request
				break; // very important, otherwise get stall

			}

			// following cases handle download (to device) and upload (to host) of both RAM and EEPROM
			// taken from Cypress Vend_Ax example code
		case VR_RAM:
		case VR_EEPROM:
			addr = SETUPDAT[2];		// Get address and length
			addr |= SETUPDAT[3] << 8;
			len = SETUPDAT[6];
			len |= SETUPDAT[7] << 8;
			// Is this an upload command ?
			//	led0=!led0;
			if(SETUPDAT[0] == VR_UPLOAD)  // this is automatically defined on host from direction of vendor request
			{
				while(len)					// Move requested data through EP0IN 
				{							// one packet at a time.

					while(EP0CS & bmEPBUSY);

					if(len < EP0BUFF_SIZE)
						bc = len;
					else
						bc = EP0BUFF_SIZE;

					// Is this a RAM upload ?
					if(SETUPDAT[1] == VR_RAM)
					{
						for(i=0; i<bc; i++)
							*(EP0BUF+i) = *((BYTE xdata *)addr+i);
					}
					else
					{
						for(i=0; i<bc; i++)
							*(EP0BUF+i) = 0xcd;
						EEPROMRead(addr,(WORD)bc,(WORD)EP0BUF);
					}

					EP0BCH = 0;
					EP0BCL = (BYTE)bc; // Arm endpoint with # bytes to transfer

					addr += bc;
					len -= bc;

				}
			}
			// Is this a download command ?
			else if(SETUPDAT[0] == VR_DOWNLOAD) // this is automatically defined on host from direction of vendor request
			{
				while(len)					// Move new data through EP0OUT 
				{							// one packet at a time.
					// Arm endpoint - do it here to clear (after sud avail)
					EP0BCH = 0;
					EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing

					while(EP0CS & bmEPBUSY);

					bc = EP0BCL; // Get the new bytecount

					// Is this a RAM download ?
					if(SETUPDAT[1] == VR_RAM)
					{
						for(i=0; i<bc; i++)
							*((BYTE xdata *)addr+i) = *(EP0BUF+i);
					}
					else
						EEPROMWrite(addr,bc,(WORD)EP0BUF);

					addr += bc;
					len -= bc;
				}
			}
			//	led0=!led0;
			break;

		default:
			return(TRUE); // getting here means error, a true return stalls endpoint in fw.c
	}

	return(FALSE);
}

/* from anchor fw library docs:
void EZUSB_InitI2C(void)

Description: This function initializes the EZ-USB i2c interface. It must be called once before calling
EZUSB_WriteI2C() or EZUSB_ReadI2C().

BOOL EZUSB_WriteI2C(BYTE addr, BYTE length, BYTE xdata *dat)

Description: This function writes a string of data to the EZ-USB i2c interface. The parameter addr
specifies the i2c device address. The parameters length and *dat specify the data to be
sent and its length. This function returns immediately before all of the provided data is sent
(the i2c library code is interrupt driven). If data is currently being sent or received at the time
of this function call it will return FALSE, and the data will not be sent. Else if the i2c port is
not busy then the data is queued up and the function returns TRUE.

BOOL EZUSB_ReadI2C(BYTE addr, BYTE length, BYTE xdata *dat)

Description: This function read a string of data from the EZ-USB i2c interface. The parameter addr
specifies the i2c device address. The parameters length and *dat specify the buffer into
which the data will be copied and its length. This function returns immediately, before all of
the requested data is read into the buffer. The user must poll the i2c status to determine when
the data is available. If data is currently being sent or received at the time of this function call
it will return FALSE, and the data will not be read. Else if the i2c port is not busy then the
read is queued up and the function returns TRUE.
*/


void EEPROMWriteByte(WORD addr, BYTE value)
{
	BYTE		i = 0;
	BYTE xdata 	ee_str[3];
	if(DB_Addr)
		ee_str[i++] = MSB(addr); // if 16 bit, we need 2-byte address and 1 byte data

	ee_str[i++] = LSB(addr);
	ee_str[i++] = value;

	EZUSB_WriteI2C(I2C_Addr, i, ee_str);
   	EZUSB_WaitForEEPROMWrite(I2C_Addr);
}

void EEPROMWrite(WORD addr, BYTE length, BYTE xdata *buf)
{
	BYTE	i;
	for(i=0;i<length;++i)
		EEPROMWriteByte(addr++,buf[i]);
}

void EEPROMRead(WORD addr, BYTE length, BYTE xdata *buf)
{
	BYTE		i = 0;
	BYTE		j = 0;
	BYTE xdata 	ee_str[2];

	if(DB_Addr)
		ee_str[i++] = MSB(addr);

	ee_str[i++] = LSB(addr);

	EZUSB_WriteI2C(I2C_Addr, i, ee_str);

	for(j=0; j < length; j++)
		*(buf+j) = 0xcd;

	EZUSB_ReadI2C(I2C_Addr, length, buf);
}

// to prevent messages about uncalled segment, this ISR has it's own jump table vector defined in the
// assembly file ISR_Timer1_JumpVector.a51. This is necessary because of the #pragma NOIV that
// is used in conjunction with the Cypress Frameworks USB interrupt handlers.
void ISR_Timer1(void) interrupt 3 { // timer1 is interrupt 3 because vector is 0x1b and 3 codes this in C51
//	if(GPIFTRIG&0x80) _nop_(); // force sync to GPIF clock (peripheral domain)
	timestampClock=1; // clock the timetamp counter, which is positive edge triggered
	_nop_();
	_nop_();
	_nop_();
	timestampClock=0;
}

// this ISR is called when external device (or user) pulls tsReset low
void ISR_TSReset(void) interrupt 3 {
	if(EP1INCS & 0x02) return; // if ep1 is busy, don't bother to send a message, assume a message has been sent eariler
//	while(EP1INCS & 0x02) led0=0; // bit 1 will be set as long as EP1 is not ready
//	led0=1;
	EP1INBUF[0]=MSG_TS_RESET;
	SYNCDELAY;
	EP1INBC=1;
	SYNCDELAY;
	tsReset=1; // it seems to become latched low by external pull low, don't understand why
	IE0=0;		// clear any pending interrupt INT0# (should happen on vector)
	RESETFIFO;	// reset data fifo
	EX0=1; // enable INT0# external interrupt

}

//-----------------------------------------------------------------------------
// USB Interrupt Handlers
//   The following functions are called by the USB interrupt jump table.
//-----------------------------------------------------------------------------


// Setup Data Available Interrupt Handler
void ISR_Sudav(void) interrupt 0
{
   GotSUD = TRUE;            // Set flag
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUDAV;         // Clear SUDAV IRQ
}

// Setup Token Interrupt Handler
void ISR_Sutok(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUTOK;         // Clear SUTOK IRQ
}

void ISR_Sof(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSOF;            // Clear SOF IRQ
}

void ISR_Ures(void) interrupt 0
{
   // whenever we get a USB reset, we should revert to full speed mode
   pConfigDscr = pFullSpeedConfigDscr;
   ((CONFIGDSCR xdata *) pConfigDscr)->type = CONFIG_DSCR;
   pOtherConfigDscr = pHighSpeedConfigDscr;
   ((CONFIGDSCR xdata *) pOtherConfigDscr)->type = OTHERSPEED_DSCR;

   EZUSB_IRQ_CLEAR();
   USBIRQ = bmURES;         // Clear URES IRQ
}

void ISR_Susp(void) interrupt 0
{
   Sleep = TRUE;
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUSP;
}

void ISR_Highspeed(void) interrupt 0
{
   if (EZUSB_HIGHSPEED())
   {
      pConfigDscr = pHighSpeedConfigDscr;
      ((CONFIGDSCR xdata *) pConfigDscr)->type = CONFIG_DSCR;
      pOtherConfigDscr = pFullSpeedConfigDscr;
      ((CONFIGDSCR xdata *) pOtherConfigDscr)->type = OTHERSPEED_DSCR;
   }

   EZUSB_IRQ_CLEAR();
   USBIRQ = bmHSGRANT;
}
void ISR_Ep0ack(void) interrupt 0
{
}
void ISR_Stub(void) interrupt 0
{
}
void ISR_Ep0in(void) interrupt 0
{
}
void ISR_Ep0out(void) interrupt 0
{
}
void ISR_Ep1in(void) interrupt 0
{
}
void ISR_Ep1out(void) interrupt 0
{
}
void ISR_Ep2inout(void) interrupt 0
{
}
void ISR_Ep4inout(void) interrupt 0
{
}
void ISR_Ep6inout(void) interrupt 0
{
}
void ISR_Ep8inout(void) interrupt 0
{
}
void ISR_Ibn(void) interrupt 0
{
}
void ISR_Ep0pingnak(void) interrupt 0
{
}
void ISR_Ep1pingnak(void) interrupt 0
{
}
void ISR_Ep2pingnak(void) interrupt 0
{
}
void ISR_Ep4pingnak(void) interrupt 0
{
}
void ISR_Ep6pingnak(void) interrupt 0
{
}
void ISR_Ep8pingnak(void) interrupt 0
{
}
void ISR_Errorlimit(void) interrupt 0
{
}
void ISR_Ep2piderror(void) interrupt 0
{
}
void ISR_Ep4piderror(void) interrupt 0
{
}
void ISR_Ep6piderror(void) interrupt 0
{
}
void ISR_Ep8piderror(void) interrupt 0
{
}
void ISR_Ep2pflag(void) interrupt 0
{
}
void ISR_Ep4pflag(void) interrupt 0
{
}
void ISR_Ep6pflag(void) interrupt 0
{
}
void ISR_Ep8pflag(void) interrupt 0
{
}
void ISR_Ep2eflag(void) interrupt 0
{
}
void ISR_Ep4eflag(void) interrupt 0
{
}
void ISR_Ep6eflag(void) interrupt 0
{
}
void ISR_Ep8eflag(void) interrupt 0
{
}
void ISR_Ep2fflag(void) interrupt 0
{
}
void ISR_Ep4fflag(void) interrupt 0
{
}
void ISR_Ep6fflag(void) interrupt 0
{
}
void ISR_Ep8fflag(void) interrupt 0
{
}
void ISR_GpifComplete(void) interrupt 0
{
}
void ISR_GpifWaveform(void) interrupt 0
{
}

// not used since we're not using flowstate in GPIF
//void Setup_FLOWSTATE_Read ( void )
//{
//   FLOWSTATE = FlowStates[18];  // 1000 0011b - FSE=1, FS[2:0]=003
//   SYNCDELAY;
//   FLOWEQ0CTL = FlowStates[20]; // CTL1/CTL2 = 0 when flow condition equals zero (data flows)
//   SYNCDELAY;
//   FLOWEQ1CTL = FlowStates[21]; // CTL1/CTL2 = 1 when flow condition equals one (data does not flow)
//   SYNCDELAY;
//}
//
//void Setup_FLOWSTATE_Write ( void )
//{ 
//   FLOWSTATE = FlowStates[27];  // 1000 0001b - FSE=1, FS[2:0]=001
//   SYNCDELAY;
//   FLOWEQ0CTL = FlowStates[29]; // CTL0 = 0 when flow condition equals zero (data flows)
//   SYNCDELAY;
//   FLOWEQ1CTL = FlowStates[30]; // CTL0 = 1 when flow condition equals one (data does not flow)
//   SYNCDELAY;
//}
