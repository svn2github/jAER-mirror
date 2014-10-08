#pragma NOIV               // Do not generate interrupt vectors
//-----------------------------------------------------------------------------
//   File:      USBAERmini2_firmware.c
//   Description: FX2 firmware for the USBAERmini2 project   
//
// created: 11/08/05 
// Revision: 0.01 
//
//-----------------------------------------------------------------------------
#include "fx2.h"
#include "fx2regs.h"
#include "syncdly.h"            // SYNCDELAY macro
#include "portsFX2.h"

#include "micro.h" // jtag stuff
#include "ports.h"

extern BOOL GotSUD;             // Received setup data flag
//extern BOOL Sleep;
extern BOOL Rwuen;
extern BOOL Selfpwr;

//BYTE Configuration;             // Current configuration
//BYTE AlternateSetting;          // Alternate settings

//WORD packetSize;

#define CPLD_NOT_RESET 			PC0
#define RESET_TS				PC6
#define MONITOR 				PC7
#define SYNTHESIZER 			PC5
#define TIMESTAMP_MASTER 		PC4
#define CFG_TIMESTAMP_COUNTER 	PC3
#define TIMESTAMP_MODE			PC2
#define ENABLE_MISSED_EVENTS	PC1

#define DB_Addr 1 // zero if only one byte address is needed for EEPROM, one if two byte address

#define LED PA7

#define EEPROM_SIZE 0x8000
#define MAX_NAME_LENGTH 8
#define STRING_ADDRESS (EEPROM_SIZE - MAX_NAME_LENGTH)

#define MSG_TS_RESET 1

// vendor requests
#define VR_ENABLE_AE_IN 0xB3 // enable IN transfers
#define VR_DISABLE_AE_IN 0xB4 // disable IN transfers
#define VR_TRIGGER_ADVANCE_TRANSFER 0xB7 // trigger in packet commit (for host requests for early access to AE data) NOT IMPLEMENTED
#define VR_RESETTIMESTAMPS 0xBb 
#define VR_ENABLE_AE_OUT 0xD0
#define VR_DISABLE_AE_OUT 0xC1
#define VR_SET_DEVICE_NAME 0xC2
#define VR_TIMESTAMP_TICK 0xC3
#define VR_RESET_FIFOS 0xC4
#define VR_DOWNLOAD_CPLD_CODE 0xC5
#define VR_XSVF_ERROR_CODE 0xD5 
#define VR_ENABLE_AE 0xC6  // start monitor and sequencer
#define VR_DISABLE_AE 0xC7 // stop monitor and sequencer
#define VR_READOUT_EEPROM 0xC9
#define VR_IS_TS_MASTER 0xCB
#define VR_MISSED_EVENTS 0xCC
#define VR_ENABLE_MISSED_EVENTS 0xCD

#define	VR_UPLOAD		0xc0
#define VR_DOWNLOAD		0x40
#define VR_EEPROM		0xa2 // loads (uploads) EEPROM
#define	VR_RAM			0xa3 // loads (uploads) external ram

#define EP0BUFF_SIZE	0x40

BOOL monitorRunning;
BOOL synthesizerRunning;
BYTE operationMode;

BOOL JTAGinit;

long cycleCounter;
long missedEvents;

#define	I2C_Addr 0x51 //adress is 0101_0001

void startSequencer(void);
void startMonitor(void);
void stopMonitor(void);
void stopSequencer(void);
void configTimestampCounter(void);

void EEPROMRead(WORD addr, BYTE length, BYTE xdata *buf);
void EEPROMWrite(WORD addr, BYTE length, BYTE xdata *buf);
void EEPROMWriteBYTE(WORD addr, BYTE value);

void downloadSerialNumberFromEEPROM(void);

//-----------------------------------------------------------------------------
// Task Dispatcher hooks
//   The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------

void TD_Init(void)              // Called once at startup
{  
	// set the CPU clock to 48MHz
	CPUCS = ((CPUCS & ~bmCLKSPD) | bmCLKSPD1) ;

	// set the slave FIFO interface to 30MHz, slave fifo mode
	IFCONFIG = 0xA3; // 1010_0011

	// disable interrupts by the input pins and by timers and serial ports:
	IE &= 0x00; // 0000_0000 

	// disable interrupt pins 4, 5 and 6
	EIE &= 0xE3; // 1110_0011; //  TODO: disable interrupt 3 (reset timestamps)

	//enable Port C and port E
	SYNCDELAY;
	PORTCCFG = 0x00;
	SYNCDELAY;
	PORTACFG = 0x03; // use interrupts 0 and 1
	SYNCDELAY;
	PORTECFG = 0x00;

	// hold CPLD in reset and configure 
	// TimestampCounter to 1 us Tick (0): 0000_0000
	IOC = 0x00; // do not set it to 0x00, stops working, but i don't know why....
	
	//enable Port C as output, except timestamp_master pin (4)
	OEC = 0xEF; // 1110_1111
	//OEE = 0xDF;  //
	OEE = 0x0F; // float JTAG pins  
	IOE = 0xFF;

	OEA = 0x88; // configure remaining two pins as output to avoid floating inputs: 1000_1000


	// Registers which require a synchronization delay, see section 15.14
	// FIFORESET        FIFOPINPOLAR
	// INPKTEND         OUTPKTEND
	// EPxBCH:L         REVCTL
	// GPIFTCB3         GPIFTCB2
	// GPIFTCB1         GPIFTCB0
	// EPxFIFOPFH:L     EPxAUTOINLENH:L
	// EPxFIFOCFG       EPxGPIFFLGSEL
	// PINFLAGSxx       EPxFIFOIRQ
	// EPxFIFOIE        GPIFIRQ
	// GPIFIE           GPIFADRH:L
	// UDMACRCH:L       EPxGPIFTRIG
	// GPIFTRIG
  
	EP1OUTCFG = 0x00;			// EP1OUT disabled
	SYNCDELAY;
	EP1INCFG = 0xA0;			// EP1IN enabled, bulk
	SYNCDELAY;                   
	EP2CFG = 0xA0;				// EP2 enabled, out, bulk, quad buffered
	SYNCDELAY;                     
	EP4CFG = 0x00;				// EP4 disabled
	SYNCDELAY;                 
	EP6CFG = 0xE0;				// EP6 enabled, in bulk, quad buffered 
	SYNCDELAY;               
	EP8CFG = 0x00;				// EP8 disabled

	SYNCDELAY;
	REVCTL= 0x03;

	EP6AUTOINLENH=0x02;
	EP6AUTOINLENL=0x00;

	// out endpoints do not come up armed
	SYNCDELAY;
	FIFORESET = 0x80;
	SYNCDELAY;
	FIFORESET = 0x02;
	SYNCDELAY;
	FIFORESET = 0x06;
	SYNCDELAY;
	FIFORESET = 0x00;
	SYNCDELAY;
	OUTPKTEND = 0x82;
	SYNCDELAY;
	OUTPKTEND = 0x82;
	SYNCDELAY;
	OUTPKTEND = 0x82;
	SYNCDELAY;
	OUTPKTEND = 0x82;

	// config fifos: wordwide=16 bit, auto-in and -out enabled, zerolength pakets disabled
	SYNCDELAY;
	EP2FIFOCFG = 0x11; //0001_0001
	SYNCDELAY;
	EP6FIFOCFG = 0x09 ; //0000_1001

	//set FIFO flag configuration: FlagA: EP2 empty, FlagB: EP6 full, flagC and D unused
	SYNCDELAY;
	PINFLAGSAB = 0xE8; // 1110_1000


	

	// initialize variables
	monitorRunning = FALSE;
	synthesizerRunning = FALSE;
	operationMode=0;

	JTAGinit=TRUE;

	cycleCounter=0;
	missedEvents=0xFFFFFFFF; // one interrupt is generated at startup, maybe some cpld registers start in high state
	LED=1;

	EZUSB_InitI2C(); // init I2C to enable EEPROM read and write

	IT1=1; // INT1# edge-sensitve
	EX1=1; // enable INT1#

	CPLD_NOT_RESET = 1; 
}

void TD_Poll(void)              // Called repeatedly while the device is idle
{ 	
	if(cycleCounter++>=50000){

		LED=!LED;
		cycleCounter=0; // this makes a slow heartbeat on the LED to show firmware is running
	}	
}

void startSequencer(void)
{   
  // start synthesizer state machine
  synthesizerRunning = TRUE;
  SYNTHESIZER = 1;
}

void downloadSerialNumberFromEEPROM(void)
{
	BYTE i;

	char *dscrRAM;
	BYTE xdata buf[MAX_NAME_LENGTH];

	// get pointer to string descriptor 3
	dscrRAM =  (char *)EZUSB_GetStringDscr(3);

	// read string description from EEPROM
	EEPROMRead(STRING_ADDRESS, MAX_NAME_LENGTH, buf);
	
	//write string description (serial number) to RAM
	for (i=0;i<MAX_NAME_LENGTH;i++)
	{
		dscrRAM[2+i*2] = buf[i];
	}
}

void startMonitor(void)
{
	//start monitor state machine
	monitorRunning = TRUE;
	MONITOR=1;
}

void stopMonitor(void)
{
  	monitorRunning = FALSE;
  	MONITOR=0;

	_nop_(); // wait, so CPLD can finish the last transaction
	_nop_();
	_nop_();
	_nop_();
	_nop_();

  	// force last paket
  	
  	EP6FIFOCFG = 0x01; //0000_0001 disable auto-in
	SYNCDELAY;

	if(EP6FIFOFLGS==0x00)
	{ // if buffer available
    	INPKTEND=0x06; // force in paket
		SYNCDELAY;
	}

  	// reset fifo  	
  	FIFORESET = 0x80;
  	SYNCDELAY;
  	FIFORESET = 0x06;
  	SYNCDELAY;
  	FIFORESET = 0x00;
	SYNCDELAY;

	EP6FIFOCFG =0x09;  //0000_1001 set back to autoin
	SYNCDELAY;
}

void stopSequencer(void)
{
	synthesizerRunning = FALSE;
	SYNTHESIZER=0;

	_nop_(); // wait, so CPLD can finish the last transaction
	_nop_();
	_nop_();
	_nop_();
	_nop_();

	
	EP2FIFOCFG = 0x01; //0001_0001 disable auto-in

	SYNCDELAY;
  	FIFORESET = 0x80;
  	SYNCDELAY;
  	FIFORESET = 0x02;
  	SYNCDELAY;
  	FIFORESET = 0x00;

	//rearm fifos
	SYNCDELAY;
	OUTPKTEND = 0x82;
	SYNCDELAY;
	OUTPKTEND = 0x82;
	SYNCDELAY;
	OUTPKTEND = 0x82;
	SYNCDELAY;
	OUTPKTEND = 0x82;
	SYNCDELAY;
		
	EP2FIFOCFG = 0x11; //0001_0001 set auto in
	SYNCDELAY;
}

void EEPROMWriteByte(WORD addr, BYTE value)
{
	BYTE		i = 0;
	BYTE xdata 	ee_str[3];
	if(DB_Addr)
		ee_str[i++] = MSB(addr); // if 16 bit, we need 2-byte address and 1 byte data

	ee_str[i++] = LSB(addr);
	ee_str[i++] = value;

	LED=1;
	EZUSB_WriteI2C(I2C_Addr, i, ee_str);
	LED=0;
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


/*BOOL TD_Suspend(void)          // Called before the device goes into suspend mode
{
  // reset CPLD
  CPLD_NOT_RESET =0;  
  
  return(TRUE);
}

BOOL TD_Resume(void)          // Called after the device resumes
{
  // activate CPLD if monitorRunning and/or synthesizerRunning is true
  if (monitorRunning || synthesizerRunning)
    {
      CPLD_NOT_RESET=1;
    }

   return(TRUE);
}*/

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------

/*BOOL DR_GetDescriptor(void)
{
   return(TRUE);
}

BOOL DR_SetConfiguration(void)   // Called when a Set Configuration command is received
{
//   Configuration = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}*/

BOOL DR_GetConfiguration(void)   // Called when a Get Configuration command is received
{
   EP0BUF[0] = 0x00;//Configuration;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

/*BOOL DR_SetInterface(void)       // Called when a Set Interface command is received
{
//   AlternateSetting = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}*/

BOOL DR_GetInterface(void)       // Called when a Set Interface command is received
{
   EP0BUF[0] = 0x00;//AlternateSetting;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

// the SETUPDAT array has the following 8 elements (see FX2 TRM Section 2.3)
//SETUPDAT[0] VendorRequest 0x40 for OUT type, 0xC0 for IN type
//SETUPDAT[1] The actual vendor request (e.g. VR_ENABLE_AE_IN below)
//SETUPDAT[2] wValueL 16 bit value LSB
//         3  wValueH MSB
//         4  wIndexL 16 bit field, varies according to request
//         5  wIndexH
//         6  wLengthL Number of bytes to transfer if there is a data phase
//         7  wLengthH

BYTE xsvfReturn;

BOOL DR_VendorCmnd(void)
{	
	WORD addr, len, bc; // xdata used here to conserve data ram; if not EEPROM writes don't work anymore
	WORD i;

	char *dscrRAM;
	unsigned char xdata JTAGdata[400];

	switch (SETUPDAT[1]){
		case VR_ENABLE_AE_IN: // enable IN transfers
			{
				
				startMonitor();
				break;
			}
		case VR_DISABLE_AE_IN: // disable IN transfers
			{
				stopMonitor();
				break;
			}
		case VR_ENABLE_AE_OUT: // enable IN transfers
			{
				startSequencer();
				break;
			}
		case VR_DISABLE_AE_OUT: // disable IN transfers
			{
				stopSequencer();
				break;
			}
		case VR_ENABLE_AE: // enable IN transfers
			{
				startSequencer();
				startMonitor();
				break;
			}
		case VR_DISABLE_AE: // disable IN transfers
			{
				stopMonitor();
				stopSequencer();
				break;
			}
		case VR_SET_DEVICE_NAME:
			{
				*EP0BUF = SETUPDAT[1];
				EP0BCH = 0;
				EP0BCL = 1;
				EP0CS |= bmHSNAK;

				while(EP0CS & bmEPBUSY); //wait for the data packet to arrive

				dscrRAM = (char*)EZUSB_GetStringDscr(3); // get address of serial number descriptor-string in RAM

				if (EP0BCL > MAX_NAME_LENGTH)
				{
					len=MAX_NAME_LENGTH;
				} else 
				{
					len=EP0BCL;
				}
	
				for (i=0;i<len;i++)
				{
					EEPROMWriteBYTE(STRING_ADDRESS+i, EP0BUF[i]); // write string to EEPROM
					dscrRAM[2+i*2] = EP0BUF[i]; // write string to RAM
				}

				for (i=len; i<MAX_NAME_LENGTH; i++) // fill the rest with stop characters
				{
					EEPROMWriteBYTE(STRING_ADDRESS+i, ' '); // write string to EEPROM				
					dscrRAM[2+i*2] = ' '; // write string to RAM
				}

				EP0BCH = 0;
				EP0BCL = 0;

				return(FALSE);
			}		
		case VR_RESETTIMESTAMPS:
			{
				RESET_TS=1; // assert RESET_TS pin for one instruction cycle (four clock cycles)
				RESET_TS=0;

				break;
			}
		case VR_DOWNLOAD_CPLD_CODE:
			{
			if (SETUPDAT[0]==VR_DOWNLOAD) {
				if (JTAGinit)
				{
					IOE=0x00;
					OEE = 0xDF;   // configure only TDO as input (bit 5) : 1101_1111
				//	IOE=0xFF;
				//	IOE=0x00;
					xsvfInitialize();
					JTAGinit=FALSE;
					
				}

				len = SETUPDAT[6];
				len |= SETUPDAT[7] << 8;

				if (len>400)
				{
					xsvfReturn=10;
					OEE = 0x0F;   // configure JTAG pins to float : 0000_1111
					JTAGinit=TRUE;
					break;
				}

				addr=0;

				resetReadCounter(JTAGdata);

				while(len)					// Move new data through EP0OUT 
				{							// one packet at a time.
					// Arm endpoint - do it here to clear (after sud avail)
					EP0BCH = 0;
					EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing

					while(EP0CS & bmEPBUSY);

					bc = EP0BCL; // Get the new bytecount

					for(i=0; i<bc; i++)
							JTAGdata[addr+i] = EP0BUF[i];							

					addr += bc;
					len -= bc;
				}
			

				if (SETUPDAT[2]==0x00) //complete
				{
					OEE = 0x0F;   // configure JTAG pins to float : 0000_1111
					JTAGinit=TRUE;
				} else
				{
					xsvfReturn=xsvfRun();
					if (xsvfReturn>0) // returns true if error
					{
						OEE = 0x0F;   // configure JTAG pins to float : 0000_1111
						JTAGinit=TRUE;
				
					//	return TRUE;
					}

				}
	
				/* EP0BUF[0] = SETUPDAT[1];
				EP0BCH = 0;
				EP0BCL = 1;
				EP0CS |= bmHSNAK;

				return(FALSE); */
				break;
			}
 			else //case VR_XSVF_ERROR_CODE:
			{
				EP0BUF[0] = SETUPDAT[1];
				EP0BUF[1]= xsvfReturn;
				EP0BCH = 0;
				EP0BCL = 2;
				EP0CS |= bmHSNAK;

				return(FALSE);
			}
			}
		case VR_TIMESTAMP_TICK:
			{
				if (SETUPDAT[0]==VR_UPLOAD) //1010_0000 :vendor request to device, direction IN
				{
					EP0BUF[0] = SETUPDAT[1];
				
					EP0BUF[1]= operationMode;
					
					EP0BCH = 0;
					EP0BCL = 2;
					EP0CS |= bmHSNAK;
				} else
				{
					operationMode=SETUPDAT[2];
					if (operationMode==0)
					{
						TIMESTAMP_MODE = 0;
						CFG_TIMESTAMP_COUNTER = 0;
					}else if (operationMode==1)
					{
  						CFG_TIMESTAMP_COUNTER = 1;
						TIMESTAMP_MODE = 0;	
					}else if (operationMode==2)
					{
  						CFG_TIMESTAMP_COUNTER = 0;
						TIMESTAMP_MODE = 1;	
					}else if (operationMode==3)
					{
  						CFG_TIMESTAMP_COUNTER = 1;
						TIMESTAMP_MODE = 1;	
					}

					*EP0BUF = SETUPDAT[1];
					EP0BCH = 0;
					EP0BCL = 1;
					EP0CS |= bmHSNAK;	
				}
				return(FALSE);
			}
		case VR_IS_TS_MASTER:
			{
				EP0BUF[0] = SETUPDAT[1];
				EP0BUF[1]= TIMESTAMP_MASTER;
				EP0BCH = 0;
				EP0BCL = 2;
				EP0CS |= bmHSNAK;

				return(FALSE);
			}
		case VR_ENABLE_MISSED_EVENTS:
		{
				if (SETUPDAT[2])
				{
					ENABLE_MISSED_EVENTS=1;
				}
				else
				{
					ENABLE_MISSED_EVENTS=0;
				}
				break;
		}
		case VR_MISSED_EVENTS:
			{
				EX1=0;
				EP0BUF[0] = SETUPDAT[1];
				EP0BUF[4]= (missedEvents & 0xFF000000) >> 24;
				EP0BUF[3]= (missedEvents & 0x00FF0000) >> 16;
				EP0BUF[2]= (missedEvents & 0x0000FF00) >> 8;
				EP0BUF[1]= missedEvents & 0x000000FF;
				EP0BCH = 0;
				EP0BCL = 5;
				EP0CS |= bmHSNAK;

				missedEvents=0;
				EX1=1;
				return(FALSE);
			}
		case VR_RAM:
		case VR_EEPROM:
		{
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
			return(FALSE);
		}
		default:
		{ // we received an invalid command
			return(TRUE);
		}
	}

	*EP0BUF = SETUPDAT[1];
	EP0BCH = 0;
	EP0BCL = 1;
	EP0CS |= bmHSNAK;

	return(FALSE);
}

void ISR_MissedEvent(void) interrupt 3 {	
	missedEvents++;
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
   if (EZUSB_HIGHSPEED())
   {
      pConfigDscr = pHighSpeedConfigDscr;
      pOtherConfigDscr = pFullSpeedConfigDscr;
    //  packetSize = 512;

   }
   else
   {
      pConfigDscr = pFullSpeedConfigDscr;
      pOtherConfigDscr = pHighSpeedConfigDscr;
    //  packetSize = 64;
   }
   
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmURES;         // Clear URES IRQ
}

void ISR_Susp(void) interrupt 0
{
//   Sleep = TRUE;
//   EZUSB_IRQ_CLEAR();
//   USBIRQ = bmSUSP;
}

void ISR_Highspeed(void) interrupt 0
{
   if (EZUSB_HIGHSPEED())
   {
      pConfigDscr = pHighSpeedConfigDscr;
      pOtherConfigDscr = pFullSpeedConfigDscr;
    //  packetSize = 512;

   }
   else
   {
      pConfigDscr = pFullSpeedConfigDscr;
      pOtherConfigDscr = pHighSpeedConfigDscr;
    //  packetSize = 64;
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
