#pragma NOIV               // Do not generate interrupt vectors
//-----------------------------------------------------------------------------
//   File:      main.c
//   Description: FX2LP firmware for the SBRet10 retina chip   
//
// created: 1/2008, cloned from tmpdiff128 stereo board firmware
// Revision: 0.01 
// authors raphael berner, patrick lichtsteiner, tobi delbruck
// 
// July 2013: Luca added gyro SPI interface that writes data to EP2 (the async endpoint in jAER)
// Oct 2013: Tobi added a lot more code for IMU
//
//-----------------------------------------------------------------------------
#include "lp.h"
#include "lpregs.h"
#include "syncdly.h"            // SYNCDELAY macro
#include "biasgen.h" 
#include "portsFX2.h"
//#include "ports.h"
//#include "micro.h"
//#include "opcode.h"

extern BOOL GotSUD;             // Received setup data flag
//extern BOOL Sleep;
extern BOOL Rwuen;
extern BOOL Selfpwr;

//BYTE Configuration;             // Current configuration
//BYTE AlternateSetting;          // Alternate settings

//WORD packetSize;

// port E, not bit addressable - more bits are in biasgen.h
#define CPLD_NOT_RESET 			0x80  // PE7 called nCPLDReset on host 
#define DVS_nReset 				0x08  // PE3 called nChipReset on host, resets DVS array and AER logic
#define BIAS_ADDR_SEL			0x01  // PE0 called biasAddrSel selects the address shift register

#define setArrayReset() 	IOE=IOE&~DVS_nReset;	
#define releaseArrayReset()	IOE=IOE|DVS_nReset;

#define releaseAddrSR()		IOE=IOE|BIAS_ADDR_SEL;
#define selectAddrSR()		IOE=IOE&~BIAS_ADDR_SEL;	

#define BIAS_DIAG_SEL			PA0
#define RESET_TS				PA7
#define TIMESTAMP_MASTER 		PA1
#define RUN_CPLD				PA3  // called runCpld on host

#define RUN_ADC 		PC0  // called runAdc on host
#define CPLD_SR_CLOCK	PC1
#define CPLD_SR_LATCH	PC2
#define CPLD_SR_BIT		PC3

#define DB_Addr 1 // zero if only one byte address is needed for EEPROM, one if two byte address

#define LEDmask 	0x40  // PE6
BOOL LEDon;


//#define MAX_NAME_LENGTH 8
//#define STRING_ADDRESS (EEPROM_SIZE - MAX_NAME_LENGTH)

#define MSG_TS_RESET 1

// vendor requests
#define VR_ENABLE_AE_IN 0xB3 // enable IN transfers
#define VR_DISABLE_AE_IN 0xB4 // disable IN transfers
#define VR_TRIGGER_ADVANCE_TRANSFER 0xB7 // trigger in packet commit (for host requests for early access to AE data) NOT IMPLEMENTED
#define VR_RESETTIMESTAMPS 0xBb 
//#define VR_SET_DEVICE_NAME 0xC2
//#define VR_TIMESTAMP_TICK 0xC3
#define VR_RESET_FIFOS 0xC4
#define VR_DOWNLOAD_CPLD_CODE 0xC5 
#define VR_READOUT_EEPROM 0xC9
#define VR_IS_TS_MASTER 0xCB
//#define VR_MISSED_EVENTS 0xCC
#define VR_WRITE_CPLD_SR 0xCF
//#define VR_RUN_ADC		0xCE

#define VR_WRITE_CONFIG 0xB8 // write bytes out to SPI
				// the wLengthL field of SETUPDAT specifies the number of bytes to write out (max 64 per request)
				// the bytes are in the data packet
#define VR_EEPROM_BIASGEN_BYTES 0xBa // write bytes out to EEPROM for power on default

#define VR_SETARRAYRESET 0xBc // set the state of the array reset which resets communication logic, and possibly also holds pixels in reset
#define VR_DOARRAYRESET 0xBd // toggle the array reset low long enough to reset all pixels and communication logic 

#define BIAS_FLASH_START 9 // start of bias value (this is where number of bytes is stored

#define	VR_UPLOAD		0xc0
#define VR_DOWNLOAD		0x40
#define VR_EEPROM		0xa2 // loads (uploads) EEPROM
#define	VR_RAM			0xa3 // loads (uploads) external ram


#define EP0BUFF_SIZE	0x40
#define NUM_CONFIG_BITS_PRECEDING_BIAS_BYTES 40 
// 10 muxes, each with 4 bits of config info. not a multiple of 8 so needs to be handled specially for SPI interface.
// we handle this by just padding the most signif nibble of the first byte written - this nibble will get shifted out.

xdata unsigned int numBiasBytes; // number of bias bytes saved

extern int g_iMovingAlgoIndex;	    
extern int g_iMovingDataIndex;

BOOL JTAGinit;

#define NUM_BIAS_BYTES 97 // 22 biases a 4 bytes, 1 Vdac a one byte plus 4 shifted source a 2 bytes 
// (remember there are also 10 muxes a 4 bits, so the total bitstream is 102 bytes)
// cDVSTest10 does not have the Vdac and the first four biases, but it does not matter if we shift in too many bits
xdata unsigned char biasBytes[]={0x00,					// Vdac readout reference
								 0x00,0x00,0x00,0x00,	// RObuffer
								 0x00,0x00,0x00,0x00,	// refcurrent
								 0x00,0x00,0x00,0x00,   // ROcas
								 0x00,0x00,0x00,0x00,   // ROgate
								 0x00,0x00,0x00,0x00,	// follPad
								 0x00,0x00,0x00,0x00,	// if_refr
								 0x00,0x00,0x00,0x00,	// if_threshol
								 0x00,0x00,0x00,0x00,	// AEpuY
								 0x00,0x00,0x00,0x00,	// AEpuX
								 0x00,0x00,0x00,0x00,	// AEReqEndPd
								 0x00,0x00,0x00,0x00,	// AEReqPD
								 0x00,0x00,0x00,0x00,	// refr
								 0x00,0x00,0x00,0x00,	// fb
								 0x00,0x00,0x00,0x00,	// pr
								 0x00,0x00,0x00,0x00,	//pixInv
								 0x00,0x00,0x00,0x00,	// pcas
								 0x00,0x00,0x00,0x00,	// amp
								 0x00,0x00,0x00,0x00,	// blue
								 0x00,0x00,0x00,0x00,	// red
								 0x00,0x00,0x00,0x00,	// off
								 0x00,0x00,0x00,0x00,	// On
								 0x00,0x00,0x00,0x00,	// diff
								 0x00,0x00,		// SSNmid
								 0x00,0x00,		// SSN
								 0x00,0x00,  // SSPmid
								 0x00,0x00}; // SSP
									 

long cycleCounter; // counts main loop cycles
unsigned long imuTimestamp; // IMU imuTimestamp register
int i;



void startMonitor(void);
void stopMonitor(void);
void configTimestampCounter(void);
void toggleLED(void);

void EEPROMWrite(WORD addr, BYTE length, BYTE xdata *buf);
void EEPROMWriteBYTE(WORD addr, BYTE value);
void EEPROMRead(WORD addr, BYTE length, BYTE xdata *buf);

void downloadSerialNumberFromEEPROM(void);

void latchConfigBits(void);

#define	I2C_EEPROM_Addr 0x51 //adress is 0101_0001 of the external serial EEPROM that holds FX2 program and static data

// IMU
#define I2C_GYRO_ADDR 0x68 // Address is: 0110_1000
#define VR_IMU 0xC6 // this VR is for dealing with IMU
#define IMU_CMD_WRITE_REGISTER 1 // arguments are 8-bit bit register address and 8-bit value to write
#define IMU_CMD_READ_REGISTER 2 // argument is 9-bit register address to read

void IMU_init(void);
void timer_init(void); // 1MHz counter for timestamping IMU samples
void ISR_Timer2(void);
#define I2C_GYRO_DATA_ADDR 0x3B // Address to query on the gyro for data
#define I2C_GYRO_DATA_LEN 14 // accel x/y/z, temp, gyro x/y/z => 7 x 2 bytes = 14 bytes 
BOOL imuDataReady; // bit to signal IMU data ready to read, set by I2C ISR
BOOL checkImuDataReady();

// see page 7 of RM-MPU-6100A.pdf (register map for MPU6150 IMU)
// data is sent big-endian (MSB first for each sample, in twos-complement 16 bit form).
// data is scaled according to product specification datasheet PS-MPU-6100A.pdf

//-----------------------------------------------------------------------------
// Task Dispatcher hooks
//   The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------

void TD_Init(void)              // Called once at startup
{  

	// set the CPU clock to 48MHz. CLKOUT is at 48MHz
	CPUCS = ((CPUCS & ~bmCLKSPD) | bmCLKSPD1) ;
	CPUCS = CPUCS & 0xFD ; // 1111_1101

	// set the slave FIFO interface to 30MHz, slave fifo mode
	IFCONFIG = 0xA3; // 1010_0011

	IOE &= ~CPLD_NOT_RESET; // put CPLD in reset

	// disable interrupts by the input pins and by timers and serial ports:
	IE &= 0x00; // 0000_0000 

	// disable interrupt pins 4, 5 and 6
	EIE &= 0xE3; // 1110_0011;

	
	
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
  
	//enable Port C and port E
	SYNCDELAY;
	PORTCCFG = 0x00;
	SYNCDELAY;
	PORTACFG = 0x00; // do not use interrupts 0 and 1
	SYNCDELAY;
	PORTECFG = 0x00;

	
	OEC = 0x0F; // 0000_1111 // JTAG, shift register stuff
	OEE = 0xFF; // 1111_1111 
	OEA = 0x89;  // 1000_1001 PA1: timestampMaster

	// 
	IOC = 0x00; 
	IOA = 0x00;
	IOE=  0x20;          //set BiasClock high 
	setPowerDownBit();	// tie biases to rail

	EP1OUTCFG = 0x00;			// EP1OUT disabled
	SYNCDELAY;
	EP1INCFG = 0xb0;			// EP1IN enabled, bulk 0xb0 is interrupt, 0xa0 is bulk
	SYNCDELAY;                   
	EP2CFG = 0x00;				// EP2 disabled
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

	SYNCDELAY;
	EP6FIFOCFG = 0x09 ; //0000_1001

	//set FIFO flag configuration: FlagB: EP6 full, flagC and D unused
	SYNCDELAY;
	PINFLAGSAB = 0xE8; // 1110_1000

	cycleCounter=0;

	biasInit();	// init biasgen ports and pins                             
	EZUSB_InitI2C(); // init I2C to enable EEPROM read and write
	I2CTL=0x01;  // set I2C to 400kHz to speed up IMU data transfers
	IMU_init(); // initialize IMU gyro chip
	// initialize I2C interrupt
	EIE|=0x02; // EI2C enable I2C interrupt I2CINT


	setArrayReset(); // keep pixels from spiking, reset all of them
	// pump powerdown to make sure masterbias is really started up
/*	for(i=0;i<20;i++)
	{
		setPowerDownBit();
		//EZUSB_Delay1ms();
		releasePowerDownBit();
		//EZUSB_Delay1ms();
	}
	EZUSB_Delay(10); // ms delay after masterbias (re)startup
	for (i=0;i<NUM_BIAS_BYTES;i++)
	{
		spiwritebyte(biasBytes[i]); // load hardcoded biases
	}
	latchNewBiases();	*/
	

	
  	IT0=1;		// make INT0# edge-sensitive
	EX0=0;		// disable INT0# (this interrupt was used to signal to the host to reset WrapAdd)

	IT1=1; // INT1# edge-sensitve
	EX1=0; // disable INT1#

	LEDon=FALSE;
	timer_init(); // start the timer2 to run imuTimestamp timer
   	IOE |= CPLD_NOT_RESET; // take CPLD out of reset
	 
	EZUSB_Delay(100);

	// make this device timestamp master as default
	IOA|=1; 



}

// initializes IMU
// IMU starts in sleep mode. We need to disable sleep and select gyro clock as the clock source for better stability
void IMU_init(void){
   	BYTE xdata b[2]; // to talk to FX2 I2C we use this byte array
	// set up IMU
	b[0] = 0x6b; // IMU power management register and clock selection, sec 4.36 of IMU register map PDF
	b[1] = 0x02; // disable sleep, select x axis gyro as clock source 
	EZUSB_WriteI2C(I2C_GYRO_ADDR, 2, &b); // select this register for writing on IMU and supply data to write to it
	b[0] = 26; // DLPF
	b[1] = 1; // FS=1kHz, gyro 188Hz, 1.9ms delay
	EZUSB_WriteI2C(I2C_GYRO_ADDR, 2, &b); // select this register for writing on IMU and supply data to write to it
	b[0] = 25; // sample rate divider
	b[1] = 0; // sample rate divider =1, 1Khz sample rate when DLPF is enabled
	EZUSB_WriteI2C(I2C_GYRO_ADDR, 2, &b); // select this register for writing on IMU and supply data to write to it
	b[0] = 27; // GYRO_CONFIG register. gyro FS_SEL bits are 4:3 full scale select bits, gyro sensitivity
	b[1] = 0x08; // set FS_SEL to 1, which is 500 deg/s, 65.5 LSB per deg/s
	EZUSB_WriteI2C(I2C_GYRO_ADDR, 2, &b); // select this register for writing on IMU and supply data to write to it
	b[0] = 28; // ACCEL_CONFIG register. accel AFS_SEL bits are 4:3 full scale select bits, gyro sensitivity
	b[1] = 0x08; // set AFS_SEL to 1, which is 4g, 8192 LSB per g
	EZUSB_WriteI2C(I2C_GYRO_ADDR, 2, &b); // select this register for writing on IMU and supply data to write to it
	// enable data ready interrupt
	// actually we don't enable this interrupt but just check the register flag to see if there is new data available
	//b[0] = 0x38; // INT_ENABLE, sec 4.36 of IMU register map PDF
	//b[1] = 0x01; // DATA_RDY_EN interrupt enabled
	//EZUSB_WriteI2C(I2C_GYRO_ADDR, 2, &b); // select this register for writing on IMU and supply data to write to it
}

// initializes Timer2 to be timestamp counter for timestamping IMU data
// Timer2 is clocked at 12MHz, and therefore clocks 12 times per microsecond.
// We use it to make a timer interrupt every 100us (which is 1200 counts at 12MHz) that increments the 32-bit timestamp value sent to host over EP1 along with the IMU sample.
void timer_init(void){
// registers T2CON (SFR 0xC8), TL2 (SFR 0xCC), TH2 (SFR 0xCD), RCAP2L (SFR 0xCA), RCAP2H (SFR 0xCB), CKCON (SFR 0x8E)
	CKCON=0; 	// timers clock with CLKOUT/12=4MHz.
	T2CON=0x04; // Timer2 is 16-bit counter with auto-reload. When timer increaments from 0xFFFF the reload value is loaded.
	RCAP2H=0xfe;
	RCAP2L=0x70;// reload register is set to overflow every 100us which is 400 counts which is 0xFFFF-400=65536-400=0xfe70
	// Timer2 interrupt
	// IE.5 ET2 - Enable Timer2 interrupt. ET2 = 0 disables Timer2 interrupt (TF2). ET2=1 enables interrupts generated by the TF2 or EXF2 flag.
	IE |= 0x20;  // sets IE.5 which enables timer2 interrupt
	//IP |= 0x20; 	// sets IE.5 which sets timer2 interrupt to high priority.
	TL2=0;
    TH2=0; // reset timer2 timestamper
	imuTimestamp=0;
	
	
}


void TD_Poll(void) // Called repeatedly while the device is idle
{
	// Try to get and send data from the IMU gyro/accelerometer every so many cycles, and check EP1IN's BUSY flag:
	// if still set, the last data from the gyro wasn't yet read, so we can't add any new data.
	imuDataReady=checkImuDataReady();

	if (imuDataReady && (EP1INCS != 0x02)) { // if we have data and EP1 is ready to write to
		// Set the address of where the data is located on the gyro.
		BYTE xdata dataAddr;
		
		// write the current imuTimestamp to the buffer
		while(EA==0); // wait for interrupts to be enabled, since we disable them in the ISR for timer2
		ET2=0; // disable timer2 interrupt is ISR_Timer2
		EP1INBUF[1]=imuTimestamp>>24;
		EP1INBUF[2]=imuTimestamp>>16;
		EP1INBUF[3]=imuTimestamp>>8;
		EP1INBUF[4]=imuTimestamp;
		ET2=1; // enable timer2 interrupt

		dataAddr = I2C_GYRO_DATA_ADDR;
		// TODO check that VR_IMU doesn't do things the same time as we are transmitting data here
		// Get the data from the gyro ... write 1 byte to IMU I2C from dataAddr which contains the IMU data register address
		EZUSB_WriteI2C(I2C_GYRO_ADDR, 1, &dataAddr);

		// ... and now read the data back directly into the EP1IN buffer, starting at offset 5.
		EZUSB_ReadI2C(I2C_GYRO_ADDR, I2C_GYRO_DATA_LEN, &EP1INBUF[5]);

		// Put 0xFF at offset 0 to distinguish this message as being gyro data on the host.
		EP1INBUF[0] = 0xFF;
		SYNCDELAY;
		EP1INBC = 1 + I2C_GYRO_DATA_LEN + 4; // send 19 bytes in total, 1 header + 4 timestamp + 14 IMU sample
		SYNCDELAY;
		toggleLED(); // toggle LED to show rate of capturing IMU samples using scope
	}
}


// reads the IMU INT_STATUS register via I2C and returns true if
// the DATA_RDY_INT is set
BOOL checkImuDataReady(void)
{
	BYTE xdata status;
	BYTE xdata dataAddr;
	dataAddr=58; // INT_STATUS register address
	// write the address of the INT_STATUS register to the IMU 
	EZUSB_WriteI2C(I2C_GYRO_ADDR, 1, &dataAddr);
	// ... and now read the data back directly into status.
	EZUSB_ReadI2C(I2C_GYRO_ADDR, 1, &status);
	// bit 0 is DATA_RDY_INT
	if ((status & 0x01) == 0)
		return FALSE;
	else
		return TRUE;
 }

void toggleLED(void)
{
	if (LEDon==TRUE)
	{
		IOE &= ~LEDmask;
		LEDon=FALSE;
	}
	else
	{
		IOE |= LEDmask;
		LEDon=TRUE;
	}
}

void latchConfigBits(void)
{
	short count;
	IOE&=~biasLatch;
	for (count=0; count<50;count++)
	{
 		_nop_();  
	}
	IOE|=biasLatch;
}
/*void downloadSerialNumberFromEEPROM(void)
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
}*/

void startMonitor(void)
{

	
 	RUN_CPLD=1;
	RESET_TS=1; // assert RESET_TS pin for one instruction cycle (four clock cycles)
	RESET_TS=0;
	imuTimestamp=0; // reset timestamp counter for IMU samples


	releasePowerDownBit();
//	IOE = IOE | DVS_nReset; //start dvs statemachines
 
}

void stopMonitor(void)
{

  	// force last paket
  	
//  	EP6FIFOCFG = 0x01; //0000_0001 disable auto-in
//	SYNCDELAY;

//	if(EP6FIFOFLGS==0x00)
//	{ // if buffer available
//    	INPKTEND=0x06; // force in paket
//		SYNCDELAY;
//	}

  	// reset fifo  	
  	FIFORESET = 0x80;
  	SYNCDELAY;
  	FIFORESET = 0x06;
  	SYNCDELAY;
  	FIFORESET = 0x00;
	SYNCDELAY;

	EP6FIFOCFG =0x09;  //0000_1001 set back to autoin
	SYNCDELAY;

	RUN_CPLD=0;

//	IOE &= ~DVS_nReset;
}

// writes the byte in big endian order, e.g. from msb to lsb
void CPLDwriteByte(BYTE dat)
{
	BYTE i=0;
	BYTE mask=0x80;

	CPLD_SR_CLOCK = 0;
	for (i=0; i<8;i++)
	{
		CPLD_SR_BIT= dat & mask;
		CPLD_SR_CLOCK = 1;
		CPLD_SR_CLOCK = 0;
		mask= mask >> 1;	
	}
}

void EEPROMWriteByte(WORD addr, BYTE value)
{
	BYTE		i = 0;
	BYTE xdata 	ee_str[3];
	if(DB_Addr)
		ee_str[i++] = MSB(addr); // if 16 bit, we need 2-byte address and 1 byte data

	ee_str[i++] = LSB(addr);
	ee_str[i++] = value;

	IOE |= LEDmask;
	EZUSB_WriteI2C(I2C_EEPROM_Addr, i, ee_str);
	IOE &= ~LEDmask;
	LEDon=FALSE;
    EZUSB_WaitForEEPROMWrite(I2C_EEPROM_Addr);
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

	EZUSB_WriteI2C(I2C_EEPROM_Addr, i, ee_str);

	for(j=0; j < length; j++)
		*(buf+j) = 0xcd;

	EZUSB_ReadI2C(I2C_EEPROM_Addr, length, buf);
}


BOOL TD_Suspend(void)          // Called before the device goes into suspend mode
{
  // reset CPLD
  IOE &= ~CPLD_NOT_RESET;  
  IOE &= ~DVS_nReset; 

  return(TRUE);
}

BOOL TD_Resume(void)          // Called after the device resumes
{

   IOE |= CPLD_NOT_RESET;
   IOE |= DVS_nReset;
	TL2=0;
    TH2=0; // reset timer2 timestamper
	imuTimestamp=0;

   return(TRUE);
}

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

/*BOOL DR_GetStatus(void)
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
}*/

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
	WORD value; 
	WORD len,ind, bc; // xdata used here to conserve data ram; if not EEPROM writes don't work anymore

	WORD addr; // xdata used here to conserve data ram; if not EEPROM writes don't work anymore
	WORD i;
	bit oldbit;
//	char *dscrRAM;
//	unsigned char xdata JTAGdata[400];

	// we don't actually process the command here, we process it in the main loop
	// here we just do the handshaking and ensure if it is a command that is implemented
	switch (SETUPDAT[1]){
		case VR_ENABLE_AE_IN: // enable IN transfers
			{
				startMonitor();
				break;  // handshake phase triggered below
			}
		case VR_DISABLE_AE_IN: // disable IN transfers
			{
				stopMonitor();
					break;
			}
		case VR_RESET_FIFOS: // reset in and out fifo
			{
				SYNCDELAY;
				EP6FIFOCFG = 0x01; //0000_0001  disable auto-in
				SYNCDELAY;
				FIFORESET = 0x80;
				SYNCDELAY;
				FIFORESET = 0x06;
				SYNCDELAY;
				FIFORESET = 0x00;


				SYNCDELAY;
				EP6FIFOCFG = 0x09 ; //0000_1001 reenable auto-in
				break;
			}
	/*	case VR_DOWNLOAD_CPLD_CODE:
			{
			if (SETUPDAT[0]==VR_DOWNLOAD) {
		
				if (SETUPDAT[4]) {
					xsvfReturn = ispEntryPoint();
				} else
				{
					addr = SETUPDAT[2];		// Get address and length
					addr |= SETUPDAT[3] << 8;
					len = SETUPDAT[6];
					len |= SETUPDAT[7] << 8;
	
					// first download programming data to EEPROM
					addr= addr + EEPROM_CPLDCODE_START; 
					while(len)					// Move new data through EP0OUT 
					{							// one packet at a time.
						// Arm endpoint - do it here to clear (after sud avail)
						EP0BCH = 0;
						EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
	
						while(EP0CS & bmEPBUSY);
	
						bc = EP0BCL; // Get the new bytecount
	
						for(i=0; i<bc; i++)
								EEPROMWriteBYTE(addr+i, EP0BUF[i]);							
	
						addr += bc;
						len -= bc;
					}
				}

				break;
			}
 			else //case VR_XSVF_ERROR_CODE:
			{
				 // program CPLD when host ask

				EP0BUF[0] = SETUPDAT[1];
				EP0BUF[1]= xsvfReturn;

				EP0BUF[2] = 0xFF & (g_iMovingAlgoIndex >> 24);
	    		EP0BUF[3] = 0xFF & (g_iMovingAlgoIndex >> 16);
				EP0BUF[4] = 0xFF & (g_iMovingAlgoIndex >> 8);
				EP0BUF[5] = 0xFF & (g_iMovingAlgoIndex);

				EP0BUF[6] = 0xFF & (g_iMovingDataIndex >> 24);
	    		EP0BUF[7] = 0xFF & (g_iMovingDataIndex >> 16);
				EP0BUF[8] = 0xFF & (g_iMovingDataIndex >> 8);
				EP0BUF[9] = 0xFF & (g_iMovingDataIndex);

				EP0BCH = 0;
				EP0BCL = 10;
				EP0CS |= bmHSNAK;

				return(FALSE);
			} 
			}*/
	/*	case VR_SET_DEVICE_NAME:
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
			}*/		
		case VR_RESETTIMESTAMPS:
			{
				RESET_TS=1; // assert RESET_TS pin for one instruction cycle (four clock cycles)
				RESET_TS=0;
				imuTimestamp=0; // reset timestamp counter for IMU samples

				// reset dvs statemachines
//				IOE= IOE & ~DVS_nReset;
//				_nop_();
//				_nop_();
//				_nop_();
//				IOE = IOE | DVS_nReset; //start dvs statemachines

				break;
			}
		case VR_IMU: // setup1: control the IMU
					SYNCDELAY;
					switch(SETUPDAT[2]){  // setupdat[2] is LSB of value
						case IMU_CMD_WRITE_REGISTER:
							// writes a value to a specified IMU register address
							EZUSB_WriteI2C(I2C_GYRO_ADDR, 2, &SETUPDAT[4]); // SETUPDAT[3] has register address, SETUPDAT[4] has the new register value
						break;
						case IMU_CMD_READ_REGISTER:
							// Get the register value from the IMU ... write 1 byte to IMU I2C which contains the IMU register address
							EZUSB_WriteI2C(I2C_GYRO_ADDR, 1, &SETUPDAT[3]); // SETUPDAT[3] has register address
							// ... and now read the register value back directly into the EP0IN buffer, starting at offset 5.
							while(EP0CS & bmEPBUSY); // wait for EP0 to be free (should be free already)
							EZUSB_ReadI2C(I2C_GYRO_ADDR, 1, &EP0BUF[2]);
							EP0BCH = 0;
							EP0BCL = (BYTE)1; // Arm endpoint with # bytes to transfer
						break;
						default:
							return TRUE; // error, create stall
					 }
			return FALSE;// return here, don't fall out where by default the sent VR is returned to host in acknowledge phase
			break;
		case VR_WRITE_CONFIG: // write bytes to SPI interface and also handles other configuration of board like CPLD and port bits on FX2
		case VR_EEPROM_BIASGEN_BYTES: // falls through and actual command is tested below
			{
				// the value bytes are the specific config command
			 	// the index bytes are the arguments
				// more data comes in the setupdat
				
				SYNCDELAY;
				value = SETUPDAT[2];		// Get request value
				value |= SETUPDAT[3] << 8;	// data comes little endian
				ind = SETUPDAT[4];			// Get index
				ind |= SETUPDAT[5] << 8;
				len = SETUPDAT[6];      	// length for data phase
				len |= SETUPDAT[7] << 8;
				switch(value&0xFF){ // take LSB for specific setup command 
 
// from SeeBetter.Biasgen inner class 
#define CMD_IPOT  1
#define CMD_AIPOT  2
#define CMD_SCANNER  3
#define CMD_CHIP  4
#define	CMD_SETBIT  5
#define CMD_CPLDCONFIG 8

				case CMD_IPOT:

					numBiasBytes=len;
					while(len){	// Move new data through EP0OUT, one packet at a time, 
						// eventually will get len down to zero by bc=64,64,15 (for example)
						// Arm endpoint - do it here to clear (after sud avail)
						EP0BCH = 0;
						EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
						SYNCDELAY;
						while(EP0CS & bmEPBUSY);  // spin here until data arrives
						bc = EP0BCL; // Get the new bytecount
						for(i=0; i<bc; i++){
							spiwritebyte(EP0BUF[i]); // writes out the bits big endian (msb to lsb)
						}
//						value += bc;	// inc eeprom value to write to, in case that's what we're doing
						len -= bc; // dec total byte count
					}
					latchNewBiases();
					break;

				case CMD_AIPOT:
					
					EP0BCH = 0;
					EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
					BIAS_DIAG_SEL = 0;
					selectAddrSR();
					SYNCDELAY;
					while(EP0CS & bmEPBUSY);  // spin here until data arrives
					bc = EP0BCL; // Get the new bytecount
					spiwritebyte(EP0BUF[0]); // write bias address
					latchNewBiases();
					releaseAddrSR();
					//two data bytes per bias
					for(i=1; i<3; i++){
						spiwritebyte(EP0BUF[i]); // writes out the bits big endian (msb to lsb)
					}
					latchNewBiases();
					break;

					
				case CMD_SETBIT:
					EP0BCH = 0;
					EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
					SYNCDELAY;
					while(EP0CS & bmEPBUSY);  // spin here until data arrives
					// sends value=CMD_SETBIT, index=portbit with (port(b=0,d=1,e=2)<<8)|bitmask(e.g. 00001000) in MSB/LSB, byte[0]=value (1,0)
					// also if button is tristable type in GUI, then byte[0] has tristate in bit1
					{
						bit bitval=(EP0BUF[0]&1); // 1=set, 0=clear
						bit tristate=(EP0BUF[0]&2?1:0); // 1=tristate, 0=drive
						unsigned char bitmask=SETUPDAT[4]; // bitmaskit mask, LSB of ind
						switch(SETUPDAT[5]){ // this is port, MSB of ind
							case 0: // port a
								if(bitval) IOA|=bitmask; else IOA&= ~bitmask;
								if(tristate) OEA&= ~bitmask; else OEA|=bitmask; 
							break;
							case 1: // port c
								if(bitval) IOC|=bitmask; else IOC&= ~bitmask;
								if(tristate) OEC&= ~bitmask; else OEC|=bitmask; 
							break;
							case 2: // port d
								if(bitval) IOD|=bitmask; else IOD&= ~bitmask;
								if(tristate) OED&= ~bitmask; else OED|=bitmask; 
							break;
							case 3: // port e
								if(bitval) IOE|=bitmask; else IOE&= ~bitmask;
								if(tristate) OEE&= ~bitmask; else OEE|=bitmask; 
							break;
							default:
								return TRUE; // error
						}
					}
					break;
				case CMD_SCANNER:
					// scanner is controlled by CPLD entirely, we just write the correct bits to the CPLD config SR.  This legacy cmd now returns a stall.
					return TRUE;
					break;

				case CMD_CHIP:
					// send diagnose SR values to chip
					BIAS_DIAG_SEL = 1;
					numBiasBytes=len;
					while(len){	// Move new data through EP0OUT, one packet at a time, 
						// eventually will get len down to zero by bc=64,64,15 (for example)
						// Arm endpoint - do it here to clear (after sud avail)
						EP0BCH = 0;
						EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
						SYNCDELAY;
						while(EP0CS & bmEPBUSY);  // spin here until data arrives
						bc = EP0BCL; // Get the new bytecount
						for(i=0; i<bc; i++){
							spiwritebyte(EP0BUF[i]); // writes out the bits big endian (msb to lsb)
						}
//						value += bc;	// inc eeprom value to write to, in case that's what we're doing
						len -= bc; // dec total byte count
					}
					latchConfigBits();
					BIAS_DIAG_SEL = 0;
					break;

				case CMD_CPLDCONFIG: // send bit string to CPLD configuration shift register (new feature on cochleaAMS1c board/cpld/firmware)
						// len holds the number of bytes to send
						// the bytes should be sent from host so that the first byte
						// holds the MSB, i.e., the bytes should be sent big endian from the host.
						// i.e., the msb of the first byte should be the biggest-numbered bit
						// and the lsb of the last byte is bit 0 as specified in the CPLD HDL configuration.
						// Each byte here is written out big endian, from msb to lsb.
						// Only integral bytes are written, so if the number of bytes is not a multiple of 8, 
						// then the first byte written (the MSB) should be left padded so that the msb ends up at the corret
						// position.
					
					oldbit=RUN_ADC;
					RUN_ADC=0;
					while(len){					// Move new data through EP0OUT, one packet at a time
						// Arm endpoint - do it here to clear (after sud avail)
						EP0BCH = 0;
						EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
						while(EP0CS & bmEPBUSY);  // spin here until data arrives
						bc = EP0BCL; // Get the new bytecount
					
						for(i=0; i<bc; i++){
							CPLDwriteByte(EP0BUF[i]); // writes the byte in big endian order, e.g. from msb to lsb
						}
						len -= bc; // dec total byte count
					}
			
					CPLD_SR_LATCH=0;
					CPLD_SR_LATCH=1;
					RUN_ADC=oldbit;
	
						break; // very important, otherwise get stall

				default:
					return(TRUE);  // don't recognize command, generate stall
				} // end of subcmd switch

				EP0BCH = 0;
				EP0BCL = 0;                   // Arm endpoint with 0 byte to transfer
				toggleLED();
				return(FALSE); // very important, otherwise get stall								default:
			} // end of subcmds to config cmds
/* commented out because these VR's are replaced by direct bit control from host side via general interface to ports
	case VR_WRITE_CPLD_SR: // write bytes to SPI interface
			{
				SYNCDELAY;
				len = SETUPDAT[6];
				len |= SETUPDAT[7] << 8;
				oldbit=RUN_ADC;
				RUN_ADC=0;
				while(len){					// Move new data through EP0OUT, one packet at a time
					// Arm endpoint - do it here to clear (after sud avail)
					EP0BCH = 0;
					EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
					while(EP0CS & bmEPBUSY);  // spin here until data arrives
					bc = EP0BCL; // Get the new bytecount
				
					for(i=0; i<bc; i++){
						CPLDwriteByte(EP0BUF[i]);					
					}
				
					len -= bc; // dec total byte count
				}
		
				CPLD_SR_LATCH=0;
				CPLD_SR_LATCH=1;

				EP0BCH = 0;
				EP0BCL = 0;                   // Arm endpoint with 0 byte to transfer
				toggleLED();
				return(FALSE); // very important, otherwise get stall
			}
		case VR_RUN_ADC:
			{	
				if (SETUPDAT[2])
				{
					RUN_ADC=1;
				} else 
				{
					RUN_ADC=0;
				}
				break;
			}
		case VR_SET_POWERDOWN: // control powerDown output bit
			{
				if (SETUPDAT[2])
				{
					setPowerDownBit();
				} else 
				{
					releasePowerDownBit();
				}
				break;

			}


		case VR_SETARRAYRESET: // set array reset, based on lsb of argument. This also resets the AER logic.
			{
				if (SETUPDAT[2]&0x01)
				{
					IOE &= ~DVS_nReset;
				} else
				{
					IOE |= DVS_nReset;
				}
			
				break;
			}

		case VR_DOARRAYRESET: // reset array for fixed reset time
			{
				IOE &= ~DVS_nReset;
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
				IOE |= DVS_nReset;
				break;
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
		case VR_SYNC_ENABLE: // sets sync event output or master/slave clocking, based on lsb of argument
			{
				if (SETUPDAT[2]&0x01)
				{
					enableSyncEvents(); //IOE|=arrayReset; // TODO change to SYNC_ENABLE
				} else
				{
					disableSyncEvents(); 
				}
			
				*EP0BUF=VR_SYNC_ENABLE;
				SYNCDELAY;
				EP0BCH = 0;
				EP0BCL = 1;                   // Arm endpoint with 1 byte to transfer
				EP0CS |= bmHSNAK;             // Acknowledge handshake phase of device request
				return(FALSE); // very important, otherwise get stall

			}

// all these special VRs are done by bit control from host now
*/
		case VR_RAM:
		case VR_EEPROM:
		{
			addr = SETUPDAT[2];		// Get address and length
			addr |= SETUPDAT[3] << 8;
			len = SETUPDAT[6];
			len |= SETUPDAT[7] << 8;
			// Is this an upload command ?
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

// no interrupts are used for TCVS320
// RESET HOST TIMESTAMP INTERRUPT not used
/*void ISR_TSReset(void) interrupt 3 {
	LED=0;
	
	SYNCDELAY; // reset fifos to delete events with the old timestamps
	FIFORESET = 0x80;
	SYNCDELAY;
	FIFORESET = 0x06;
	SYNCDELAY;
	FIFORESET = 0x00;

	SYNCDELAY;
	EP6FIFOCFG = 0x09 ; //0000_1001


	if (EP1INCS!=0x02)
	{
		EP1INBUF[0]=MSG_TS_RESET;
		SYNCDELAY;
		EP1INBC=1;
		SYNCDELAY;
		IE0=0; // clear interrupt
		EX0=1; // enable INT0# external interrupt
		LED=1;
	}
}

*/

// Timer2 interrupt handler
// TF2 or EXF2 Timer 2 interrupt T2CON.7 (TF2)
// T2CON.6 (EXF2)
// IE.5 IP.5 6 0x002B
void ISR_Timer2(void) interrupt 5 // http://www.keil.com/support/man/docs/c51/c51_le_interruptfuncs.htm
// for vector address 0x002b
{
	// comes here every 100us to increment 32-bit timestamp
	EA=0; // disable interrupts
	imuTimestamp+=100;
	TF2=0; // clear timer2 overflow flag
	EA=1; // enable interrupts
}

// below is dumb idea, but left for reference in case we ever need I2C interrupt
// I2C interrupt, set up to signal interrupt on IMU data reaady
// I2CINT I2C Bus 0x004B
//void ISR_I2C(void) interrupt 9
//{
//	imuDataReady=1;	
//	EXIF&=~0x40; // EXIF.5=I2CINT, clear this flag
//}

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
