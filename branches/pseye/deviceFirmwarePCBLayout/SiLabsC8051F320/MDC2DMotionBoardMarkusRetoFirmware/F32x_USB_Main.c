// This is part of the USB MDC2D short project. It is an adaptation of the ServoController
// Firmware which in turn was designed using a sample supplied by Silicon Labs. 


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
// Project Name:   F32x_USB_Main
//
//
// Release 2.0
//    -All changes by TR
//    -03 DEC 2010
//    -Changed to fit the requirements of the MDC2D motion chip

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
#include <intrins.h>
#include <c8051f320.h>              //  Special Function Registers for c8051f320.  
#include "F32x_USB_Register.h"      //  USB registers
#include "F32x_USB_Main.h"          //  USB function prototypes, constants 
#include "F32x_USB_Descriptor.h"
 

//-----------------------------------------------------------------------------
// Globals
//-----------------------------------------------------------------------------

// Different testing modes:
//#define NOCHIP  //Debugging without motion chip
//#define DEBUG   //General debugging
//#define TESTIMAGE
//#define LOAD_DAC_AT_INIT
#define NOT_USE_ONCHIP_BIASGEN

#define MAX_X 20        // number of pixel in x-direction NOTE that in the code below MAX_X is always used as MAX_X -1 since the position counter srtarts at 0. Thus the edge is reached when the counter is at MAX_X-1                                                               //CHANGE TO MDC2D
#define MAX_Y 20        // number of pixel in y-direction                                                                   //CHANGE TO MDC2D                                                                          //CHANGE TO MDC2D
#define MAX_PACKET_SIZE EP1_PACKET_SIZE 
#define FRAME_START_MARKER 0xAC
#define LED_ON 0
#define LED_OFF 1 //The number that marks the beginning of each image frame





//Macros------------------------------------------------------------
// Some of the often called functions are rewritten as macros.

//MDC2DclockH: send a single clocking pulse to the MDC2Ds horizontal shift register.
#define MDC2DclockH()  	hclock = 0;\
						hclock = 1;


//MDC2DclockV: send a single clocking pulse to the MDC2Ds vertical shift register.
#define MDC2DclockV()  vclock = 0;\
	                      vclock = 1; 


//MDC2DgoToNextPixel: send the clocking pulses that direct the MDC2Ds reading to the next pixel.
//                       when at the end of the line, go to the next one.
#ifdef NOCHIP
#define MDC2DgoToNextPixel() if(posX >= MAX_X -1) {	\
								posX=0;			\
								posY++;			\
							 } else {			\
							 	posX++;			\
							 }
#else
#define MDC2DgoToNextPixel() if(posX>= MAX_X -1 && posY >= MAX_Y -1){\
								MDC2DresetToOrigin()\
							 }else if(posX >= MAX_X -1) {	\
								MDC2DresetX()		\			
								MDC2DclockV()		\
								posY++;				\
							 } else {				\
							 	MDC2DclockH()		\
								posX++;				\
							 }						\

#endif

//MDC2DresetX: reset the horizontal shift register to the 0 position.
#ifndef NOCHIP
#define MDC2DresetX() {		\                                                                                                                                                            
   	while(hsync) {			\                                                                                                         
     	MDC2DclockH();		\
  	}						\
    while(!hsync){			\
     	MDC2DclockH();		\ 
  	}						\
	MDC2DclockH();			\
  	posX=0;					\
}
#endif




//MDC2DresetToOrigin: reset the MDC2Ds shift registers to the pixel (0,0)
#ifndef NOCHIP
#define MDC2DresetToOrigin()\
{\
  MDC2DresetX();\
  while(vsync)\
  {\
     MDC2DclockV();\  
  }\
  while(!vsync)\
  {\
     MDC2DclockV();\
  }\
  MDC2DclockV();\
  posX=0;\
  posY=0;\
  doSetup = 1;\
 }


#endif
#ifdef NOCHIP
#define MDC2DresetToOrigin()\
{\
  posX=0;\
  posY=0;\
  doSetup = 1;\
}
#endif

 
        
//LED toggle: toggles the LED
#define upperLEDtoggle() upperLED=!upperLED
#define lowerLEDtoggle() lowerLED=!lowerLED





//------------------------------------------------------------------- 
                                                                                      
sbit ADCclock =    	P0^0;
sbit serialout =    P0^1;
sbit NSS =          P0^3;       //goes to nSync
sbit SCK =          P0^4;		//goes to SCLK
sbit ADCreset =     P0^5;
sbit upperLED =     P0^6;      // xxxLed='1' means OFF
sbit lowerLED =     P0^7;  

sbit MOSI =         P1^0;		//goes to DIN
sbit ADCclockFirmware =		P1^1;
sbit ADCReady =      P1^2;
sbit enableBiasScr = P1^3;
sbit pd =           P1^4;
sbit bitin =        P1^5;
sbit bitlatch =     P1^6;
sbit biasclock =    P1^7;

sbit bitout =       P2^0;
sbit hclock =       P2^1;   //MDC2D clocking signals (uC -> MDC2D)
sbit vclock =       P2^2;
sbit hsync =        P2^3;   //signals from the MDC2D chip (MDC2D -> uC)
sbit vsync =        P2^4;
sbit scanVrecep =   P2^5;
sbit scanLmc1 =     P2^6;
sbit scanLmc2 =     P2^7;


                    



// Bitvariables to define what channels from the motion chip are to be read
                                                                                                                         //check if it really fits to chip and if so delete above commented section
bit putVrecep, putLmc1, putLmc2;    //Set by the host
bit vrecepIsRequested, lmc1IsRequested, lmc2IsRequested; //Working copies for the present frame   
  

// Bitvariables to control the program flow
bit hostInRequest, doReset, doStream, allLocalChannels, doSetup;

bit toggle =0;

char onChipBiases[36]; //contains the values of the on-chip biases
char controlRegister =0x2; // the control register content which controls the channel read by the on chip ADC

unsigned char posX=0; //the actual position of the motionChip registers
unsigned char posY=0;
unsigned int i = 0;
unsigned char c = 0;
unsigned char j=0;
unsigned char k=0;
unsigned char isrj;
unsigned char isrk;
unsigned char byteBuf, bitsInBuf; //Variables that are used for the packaging of the 10bit values

//Declare function Prototypes
void Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void Timer_Init(void);			// Init timer to use for spike event times
void initDAC(void);             // Initialize the DAC (not on uController)
void initADC(void);             // Initialize the ADC (on uC)
void MDC2D_init(void);           // Initialize the motion detection chip
void signalLED(unsigned  int); //signals successful completation of one init step
void setBiasV( unsigned char msb, unsigned char lsb, unsigned char address);
void setBiasV_decimal (unsigned long int set_mV,unsigned char address);
void sendSPI(unsigned char dat1, unsigned char dat2, unsigned char dat3);
void readVoltage(char amxPort);
void readAndStartNext(char nextPort);
void readAndSelectNext(char nextPort);
void usbCommitByte(unsigned char dat);
void usbCommitPacket(void);
void countDelay(unsigned char c);
void delayTime(unsigned long int t);
void delay(void);
void writeToOnChipBiasRegister(unsigned char dataToSet);
void writeToOnChipBiasRegister_4Bits(unsigned char dataToSet);
void writeOnChipBiases(void);
void biasLatchToggle();
void readOnChipADC(void);




//-----------------------------------------------------------------------------
// Main Routine
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	None
//
// Initialized the microcontroller and then enters a loop which waits for the
// host to send start command. If so, all pixels are read and sent to the host.
//-----------------------------------------------------------------------------
void main(void) {

   	unsigned char frameDescriptor;     //' The frame-descriptor holds information about the data in the frame.

   
   	//Initialize variables
   	putVrecep=1;
   	putLmc1=1;
   	putLmc2=1;
   	vrecepIsRequested=1;
   	lmc1IsRequested=1;
   	lmc2IsRequested=1;

   	upperLED = LED_OFF;
   	lowerLED = LED_OFF;
        
   	doReset=0;
   	doStream=0;
   	allLocalChannels=1;
   	doSetup = 1;

   	hostInRequest = 0; //' We start without IN transfer initiated by the host.
   	byteBuf=0;
   	bitsInBuf=0;
  
   	PCA0MD &= ~0x40;                    // Disable Watchdog timer
   


   	//Initialize uController
   	Sysclk_Init();                      // Initialize oscillator
   	Port_Init();                        // Initialize crossbar and GPIO
   	Usb0_Init();                        // Initialize USB0
   	initADC();                          // Initialize the ADC

   	//Initialize external devices (DAC, MDC2D) 
	#ifdef NOT_USE_ONCHIP_BIASGEN  //if the on chip biasgenerator is nit used it is powered down
		pd=1;
		enableBiasScr=1;
	#else 
		pd=0;
		enableBiasScr=1;
	#endif
   	initDAC(); //' Initialize the external DAC
   	MDC2D_init(); // Initialize the motion chip (bias generator, ADC, Scanner), also set scanner to 0/0

    //switch upper LED on to signal comletation of Initialization
	upperLED = LED_ON;
	lowerLED = LED_ON;



   	//Initialization done. Enter main loop.
   	i=0;
   	while (1) { 
		// stream command is recieved. start streaming
	   	if(doReset) { //For the case of reset set scanner to 0/0
	      	MDC2DresetToOrigin();
          	doReset=0;
			doSetup=1;
	   	}
	   	if(doSetup) { // If we are at (0,0) 
	       	EA=0; // Disable interrupts
	       	vrecepIsRequested =putVrecep;   //make working copies for the present frame settings
    	   	lmc1IsRequested =putLmc1;
		   	lmc2IsRequested =putLmc2; 
			//reset onchip ADC
			ADCreset=1;
			delay();
			ADCreset=0;
			while(!ADCReady){
				ADCclockFirmware=0;
				ADCclockFirmware=1;
			}
			ADCclockFirmware=0;
			ADCclockFirmware=1;

           	EA=1; // Enable interrupts
		   	doSetup=0;

		   	usbCommitByte(FRAME_START_MARKER); //send start marker to the FIFO
			//create the frame descriptor: it indicates which data is present in th frame.
			// The 3MSB stand for VLMC2,VLMC2,VRECEP
           	frameDescriptor = ((unsigned char)DESCR_FLAG_VRECEP)|
							  ((unsigned char)DESCR_FLAG_VLMC1)	|
							  ((unsigned char)DESCR_FLAG_VLMC2)	|
							  ((unsigned char)DESCR_FLAG_BIT7)  |   
							  0x00;
         	usbCommitByte(frameDescriptor);	 //write Frame descriptor to FIFO	
			
			byteBuf = 0;
			bitsInBuf= 0; 

			AMX0P = AMX_VRECEP;	 //ADC0 MUX POSITIVE CHANNEL SELECTION 

		}

		//read out all channels (setADC)	
		AD0INT=0;		     //ADC0 CONVERISION COMPLETE INTERRUPT FLAG    
        AD0BUSY = 1;
		readAndStartNext(AMX_VLMC1);  // Read Vrecep value and commit it to fifo, and start next vlmc1 conversion
		readAndStartNext(AMX_VLMC2); // Read svx value and commit it to fifo, and start next vlmc2 conversion
		readAndSelectNext(AMX_VRECEP); // Read svy value and commit it to fifo, and set the channel to vrecep
		readOnChipADC();			// Read the on-chip ADC and commit it ti fifo



	 	if( (posY==MAX_Y-1) && (posX==MAX_X-1) )  {// Frame is completely read
         	usbCommitPacket(); //This provokes a short packet, or a zero packet, which marks the end of frame.

			MDC2DresetToOrigin();
			//MDC2DclockV();
			//MDC2DclockH();
	  	} else {
        	MDC2DgoToNextPixel(); 
      	}
		upperLEDtoggle();
		

	} //end main loop. go back and read next pixel
}






//-----------------------------------------------------------------------------
// Read pixel Subroutines
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// ReadAndStartNext
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	char next Port : The next port to be read
//
// Reads a channel and starts the next one to be read.
//-----------------------------------------------------------------------------
#ifndef TESTIMAGE

void readAndStartNext(char nextPort) {
//Reads the just finished conversion and starts the next one.
//Then writes the retrieved data to the USB FIFO.
         unsigned char AmxL, AmxH;
		 		 
		 while(AD0INT!=1); //' Wait until conversion is finished

         AmxL=ADC0L; //Save the converted values
		 AmxH=ADC0H;
		            
         AMX0P = nextPort; //Start next due conversion 
		 AD0INT=0;
         AD0BUSY = 1;
		
		 usbCommitByte(byteBuf | (AmxH >> bitsInBuf)); //Send the converted value
		 byteBuf= (AmxH<<(8-bitsInBuf)) | (AmxL>>bitsInBuf);  //ADC has to be in Left-justified mode!
		 bitsInBuf += 2;
		 if(bitsInBuf==8) {  
		    bitsInBuf=0;
		    usbCommitByte(byteBuf);
			byteBuf=0;
		 }
}



//-----------------------------------------------------------------------------
// ReadAndSelectNext
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	char next Port : The next port to be read
//
// Reads a channel and selects the next one to be read.
//-----------------------------------------------------------------------------
void readAndSelectNext(char nextPort)
//Reads the just finished conversion and starts the next one.
//Then writes the retrieved data to the USB FIFO.
{		 		 
		 while(AD0INT!=1); //' Wait until conversion is finished
		            
         AMX0P = nextPort; //Select next channel

		 usbCommitByte(byteBuf | (ADC0H >> bitsInBuf)); //Send the converted value
		 byteBuf= (ADC0H<<(8-bitsInBuf)) | (ADC0L>>bitsInBuf);  //ADC has to be in Left-justified mode!
		 bitsInBuf += 2;
		 if(bitsInBuf==8)
		 {  
		    bitsInBuf=0;
		    usbCommitByte(byteBuf);
			byteBuf=0;
		 }
}


#endif




#ifdef TESTIMAGE
void readAndStartNext(char nextPort) //DEBUG!
{		
         unsigned char amxH = 0xFF;
		 unsigned char amxL=0xFF;

		if(posY==0) amxH=0xFF;
		else {
		 if(posX==0||posX==10) amxH=0xFF;
		 if(posX==1||posX==11) amxH=0x7F;
		 if(posX==2||posX==12) amxH=0x3F;
		 if(posX==3||posX==13) amxH=0x1F;
		 if(posX==4||posX==14) amxH=0x0F;
		 if(posX==5||posX==15) amxH=0xFF;
		 if(posX==6||posX==16) amxH=0x7F;
		 if(posX==7||posX==17) amxH=0xFF;
		 if(posX==8||posX==18) amxH=0x7F;
		 if(posX==9||posX==19) amxH=0xFF;
		}
		

		 usbCommitByte(byteBuf | (amxH >> bitsInBuf)); //Send the converted value
		 byteBuf= (amxH<<(8-bitsInBuf)) | (amxL>>bitsInBuf);  //ADC has to be in Left-justified mode!
		 bitsInBuf += 2;
		 if(bitsInBuf==8)
		 {  
		    bitsInBuf=0;
		    usbCommitByte(byteBuf);
			byteBuf=0;
		 }


}

void readAndSelectNext(char nextPort) {readAndStartNext(nextPort);}
#endif



//-----------------------------------------------------------------------------
// readOnChipADC()
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	None
//
// Reads the 8bits of theon-chip ADC and sends the value. Since the value is in 
//8bit format but the uC ADC has 10 bit format, for compliance with host routines 
// the data is converted to 10 bit format.
//-----------------------------------------------------------------------------
void readOnChipADC(){
   int dat;
   char datH;
   char datL;



   EA=0;		//disable global interrupt
       //'Wait for completion  uC Interruptflag
	   
   SPI0DAT=0xa;
   dat=SPI0DAT;
   while(ADCReady){ //XXX
	  	ADCclockFirmware=0;
		_nop_();
   		ADCclockFirmware=1;
		_nop_();
	}
   SPIF=0;
   EA=1;
   
  //dat*=0x3FF;
   //dat/=0xFF;
   datH=dat>>2;
   datL=dat<<8;
	
   usbCommitByte(byteBuf | (datH >> bitsInBuf)); //Send the converted value
   byteBuf= (datH<<(8-bitsInBuf)) | (datL>>bitsInBuf);  //ADC has to be in Left-justified mode!
   bitsInBuf += 2;
   if(bitsInBuf==8) {  
		bitsInBuf=0;
		usbCommitByte(byteBuf);
		byteBuf=0;
	}
	
}




//-----------------------------------------------------------------------------
// USB communication Subroutines
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// usbCommitByte
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	unsigned char dat : the byte of data to be written in FIFO
//
// Write a byte to the endpoint1 FIFO.
//-----------------------------------------------------------------------------
void usbCommitByte(unsigned char dat) {
   i++;
   EA=0;
   POLL_WRITE_BYTE(FIFO_EP1, dat);
   EA=1;
   if(i==MAX_PACKET_SIZE) {//If the FIFO is full, mark it to be sent to the host.
      usbCommitPacket();
      //while(!hostInRequest);
   }
}

//-----------------------------------------------------------------------------
// usbCommitPacket
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	None
//
// Mark the FIFO to be sent, regardless of how much data is in it.
// This provokes either a short or a zero packet.
//-----------------------------------------------------------------------------
void usbCommitPacket() {
      unsigned char reg;
	  EA=0;
	  POLL_WRITE_BYTE(INDEX, 1);
      POLL_WRITE_BYTE(EINCSR1, rbInINPRDY);
	  EA=1;
	  do{
        POLL_READ_BYTE(EINCSR1, reg);
		}
      while(reg & rbInINPRDY); //wait until a new packet can be written.
      i=0;
}






//-----------------------------------------------------------------------------
// External DAC (AD5391) communication Subroutines
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// setBiasV
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	unsigned char msb : the 8 most significant bits of a 12 bit 
//										representation of the bias. 
//					unsigned char lsb : the 4 least significant bits followed by
//										4 irrelevant numbers
//				:	address			  :	adress of the DAC channel. 
//
// Sets a specified channel of the AD5391 to the voltage encoded as binary.
//
//-----------------------------------------------------------------------------
void setBiasV( unsigned char msb, unsigned char lsb, unsigned char address)
// Set a bias voltage in the DAC
{
   unsigned char dat1 = 0x00; //00 00 0000;
   unsigned char dat2 = 0xC0; //Reg1=1 Reg0=1 : Write output data
   unsigned char dat3 = 0x00;

   dat1 |= (address & 0x0F);
   dat2 |= ((msb & 0x0F) << 2) | ((lsb & 0xC0)>>6) ;
   dat3 |= (lsb << 2) | 0x03; // DEBUG; the last 2 bits are actually don't care
   
   sendSPI(dat1, dat2, dat3);

	upperLEDtoggle();
}




//-----------------------------------------------------------------------------
// setBiasV_decimal
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	unsigned long int set_mV : the desired output voltege in mV
//				:	address			    	 : adress of the DAC channel. 
//
// Sets a specified channel of the AD5391 to the given voltage 
//-----------------------------------------------------------------------------
#ifdef LOAD_DAC_AT_INIT
void setBiasV_decimal(unsigned long int set_mV, unsigned char address) {
	unsigned char msb= (((4095UL*set_mV)/5000UL)>>4)&0xFF;
	unsigned char lsb= (((4095UL*set_mV)/5000UL)<<4)&0xFF;

   	unsigned char dat1 = 0x00; //00 00 0000;
   	unsigned char dat2 = 0xC0; //Reg1=1 Reg0=1 : Write output data
   	unsigned char dat3 = 0x00; //to be replaced by data bits

   	dat1 |= (address & 0x0F);
   	dat2 |= (msb>>2);
   	dat3 |= (((msb & 0x03) << 6) | (lsb >>2)); //the last 2 bits are actually don't care but are set to 1 1
   
   	sendSPI(dat1, dat2, dat3); 
}
#endif


 

//-----------------------------------------------------------------------------
// sendSPI
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	unsigned char dat1, unsigned char dat2, unsigned char dat3: 
//					Each representing 8 bit of the 24bit code required by the DAC.
//					Refer to manual for explanation!!!
//
// Sends the 24 bits given by 3 8bit chars to the external DAC using standalone mode
// NOTE: not the standard SPI ports of the uC are used but some other ports are adres-
//		 ed. Thus the protocol is implemented in the function.
//-----------------------------------------------------------------------------
void sendSPI(unsigned char dat1, unsigned char dat2, unsigned char dat3) {
//Send a 24bit value to the DAC. dat1 is the MSB, dat3 the LSB.
  
   EA = 0;		//disable global interrupt
   SCK=1;							//prepare clock
   NSS = 0;    //' nSync low to signal incoming data

   { 
   unsigned char nextDat;
   for (j=0; j<3;j++) {
   		if (j==0) nextDat= dat1;
		else if (j==1) nextDat= dat2;
		else nextDat= dat3;

   		for (k=8; k>0; k--) {
   			MOSI = nextDat>>k-1 &0x01; //load one bit to output: first the bitbattern is shifted 7times (MSB first) then always one less
			delay();
			SCK = 0;				// make clock falling to send bit
			delay();
			SCK=1;
   		}

	}
	}
   NSS = 1;
	delay();
   EA=1;
}





//-----------------------------------------------------------------------------
// On chip biasgenerator communication Subroutines
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// writeOnChipBiases
//-----------------------------------------------------------------------------
//
// Return Value : 	None
// Parameters   : 	None 
//
//
// Writes the on-chip biasregister 
//
//-----------------------------------------------------------------------------
void writeOnChipBiases(){

		isrj=0;
		isrk=0;
		for(isrj=0; isrj<36; isrj++){
			writeToOnChipBiasRegister(onChipBiases[isrj]);
		}	
		writeToOnChipBiasRegister_4Bits(controlRegister);	
		writeToOnChipBiasRegister(0x22);		

		bitlatch=0 ;// take biasLatchLow to apply settings
		_nop_();_nop_();_nop_(); //wait so the process has time to happen
		bitlatch=1;


POLL_WRITE_BYTE(EINCSR1, rbInSDSTL); //Send a stall on EP1(?)
               POLL_WRITE_BYTE(EINCSR1, rbInFLUSH); //Flush buffer of EP1
			   POLL_WRITE_BYTE(EINCSR1, rbInFLUSH); //Do it twice (double buffer)
		doReset=1;

}


void writeToOnChipBiasRegister(unsigned char dataToSet){
 		int j;
        for(j=7;j>=0;j--) { //go through bits of each bias
        	bitin = (dataToSet>>j)&0x01; 
			biasclock=1;
			_nop_();_nop_();_nop_();
        	biasclock=0;
		}
}


void writeToOnChipBiasRegister_4Bits(unsigned char input){
 		int j;
        for(j=3;j>=0;j--) { //go through bits of each bias
        	bitin = (input>>j)&0x01; 
			biasclock=1;
			_nop_();_nop_();_nop_();
        	biasclock=0;
		}
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
   
   CLKSEL |= SYS_4X_DIV_2;             // Select SYSCLK as Clock Multiplier/2

   CLKSEL |= USB_4X_CLOCK;             // Select USB clock

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
Step 1.  Select the input mode (analog or digital) for all Port pins, using the Port Input Mode register (PnMDIN).                                                          //do properly for MDC2D
Step 2.  Select the output mode (open-drain or push-pull) for all Port pins, using the Port Output Mode register (PnMDOUT).
Step 3.  Select any pins to be skipped by the I/O Crossbar using the Port Skip registers (PnSKIP).
Step 4.  Assign Port pins to desired peripherals (XBR0, XBR1).
Step 5.  Enable the Crossbar (XBARE = ‘1’).
*/

// Configure the XBRn Registers
   XBR0 = 0x02;			 //'  SPI I/O enabled in Crossar
   XBR1 = 0x00;          //            


// Select Pin I/0

// NOTE: Some peripheral I/O pins can function as either inputs or 
// outputs, depending on the configuration of the peripheral. By default,
// the configuration utility will configure these I/O pins as push-pull 
// outputs.

    P0MDIN = 0xFF;  // Input configuration for P0. Not using analog input.                      //ok
    P1MDIN = 0xFF;  // Input configuration for P1. Not using analog input                     //ok
	P2MDIN = 0x1F;    //' 00011111   0 = analog. P2.5, P2.6, P2.7 are analog.               	//ok
    P3MDIN = 0xFF;  // Input configuration for P3. Not using analog input.                      //ok


    //Push pull is enabled (1)in all digital ports. SPI ports and ALL INPUT ports are DISABLED (0)
    P1MDOUT	= 0xFA;	 //'  11111010                                                             //ok
    P0MDOUT = 0xC0; //'   11000000 LED are push pull                                           //ok
    P2MDOUT = 0x06; // 00000110 Output configuration for P2. All digital outputs push/pull.                                   //ok
    P3MDOUT = 0x00; // Output configuration for P3                                             //ok


    P2SKIP = 0xE0;    //' 11100000   1 = skip. skip analog signals from motion chip to uC         //ok
    P0SKIP = 0x00;    // dont skip in port0			                                            //ok
    P1SKIP = 0x00;    //  dont skip in port1	                                               //ok
 
    SPI0CFG |= 0x50; //' X 101 XXXX : MasterEnable, ClockPhase, ClockPolarity 
    SPI0CN  =  0x01; //' 0000 00 X 1 : Flags (4); disable NSS ; SPI enabled
    SPI0CKR =  0x0f; //(DAC could go 50 MHz, but initialization fails stragely. Is notSync the problem? Works from 0x0E)


	XBR1|=0x40; 	// 0100 0000 enable xbar, setting XBARE


    hclock = 1;
    vclock = 1;
    
    upperLEDtoggle();
    
    

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


   POLL_WRITE_BYTE(POWER,  0x08);      // Force Asynchronous USB Reset
   POLL_WRITE_BYTE(IN1IE,  0x07);      // Enable Endpoint 0-2 in interrupts
   POLL_WRITE_BYTE(OUT1IE, 0x07);      // Enable Endpoint 0-2 out interrupts
   POLL_WRITE_BYTE(CMIE,   0x07);      // Enable Reset,Resume,Suspend interrupts

   USB0XCN = 0xE0;                     // Enable transceiver; select full speed
   POLL_WRITE_BYTE(CLKREC, 0x80);      // Enable clock recovery, single-step mode
                                       // disabled

   EIE1 |= 0x02;                       // Enable USB0 Interrupts
   EA = 1;                             // Global Interrupt enable
                                       // Enable USB0 by clearing the USB 
                                       // Inhibit bit
   POLL_WRITE_BYTE(POWER,  0x01);      // and enable suspend detection
   
   upperLEDtoggle();
   
}




//-----------------------------------------------------------------------------
// initADC
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : None
// 
// - Initialize external DAC
//-----------------------------------------------------------------------------
void initADC(void)
{
   REF0CN = 0x03;//' XXXX 0011: REFSEL internal, TempSens off, BiasGen on, InternalRef on
   ADC0CF = 0x3C; //'       00111 1 XX: AD0SC=7, left-justified mode 

   ADC0CN = 0x40;  //' 0100 0 000: AD0EN,Low Power Track mode,Conversion complete Flag,ADC Busy, Window Compare flag, Conversion mode (3b)
   AD0EN = 1;
   AMX0N = 0x1F; //' Negative Input is GND
   AMX0P = 0x1F; //Positive channel VDD (VRef)
     
   for(i=0;i<5000;i++) //Wait so that the DAC has time to settle
   {
     Delay();
   }
   
   upperLEDtoggle();
}



//-----------------------------------------------------------------------------
// initDAC
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : None
// 
// - Initialize external DAC
//-----------------------------------------------------------------------------
void initDAC()
{
     //write to special function register
	sendSPI(0x0C,0x3D,0x00);    // 0000 1100 0011 1101 XXXX 00XX :PwerDwn0; intRef2.5V, BoostMode on, Int ref enable, Monitor disabled, monitor Temp, 4x dont care, 2xNo toggle, 2x dont care
	#ifdef LOAD_DAC_AT_INIT
	int biases[15]={2800, 	//VregRefBiasAmp
					2800,	//VregRefBiasMain
					3000,	//Vprbias
					200,	//Vlmcfb
					3000,	//Vprbuff
					3000,	//Vprlmcbias
					3000,	//Vlmcbuff
					000,	//Screfpix
					1500,	//Follbias					
					3000,	//Vprscfbias
					3000,	//VADCbias
					500,	//Vrefminbias
					1500,	//Screfmin
					0000,	//VrefnegDAC
					4500	//VrefposDAC
					};
	i =0;
	while(i<15)
	{
		setBiasV_decimal(biases[i], (unsigned char)i);
		i++;
	}
	#endif
	upperLEDtoggle();
}




//-----------------------------------------------------------------------------
// MDC2D_init
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : None
// 
// - Initialize the motion detection chip
//          . Initialize on chip biasgenerator
//          . Initialize on chip ADC
//          . Set scanner to position 0/0
//-----------------------------------------------------------------------------
void MDC2D_init()
{
   /* load Biasgenerator. The register first has 4bits to store 4 bias control
    * parameter. One bias in 8bit format follows. Then 12 biases are stored in
    * 24bit each. The biases has to be loaded in reversed order. Thus the MSB of
    * bias 12 is loaded first. During Initialisation all biasBits are loaded 0, 
    * the control bits 1.
    * The onchip biasgenerator is powered down.
    * The scanner is tested. If hSync and vsync cannot be recieved the program stops
    * If the scanner works, position 0/0 is selected
    */

	{
	i=0;
	for(i=0;i<12*3;i++){ //load bias bits 0
		writeToOnChipBiasRegister(0x00);
	}

	writeToOnChipBiasRegister_4Bits(0xD); //channel select register
	writeToOnChipBiasRegister(0x22); //mirror current




	bitlatch=0; //apply the biases
	delay();
	bitlatch=1;


	}
    
	#ifdef LOAD_DAC_AT_INIT
    //Test scanner
	{
    bit gotVsync=0;
    bit gotHsync=0;
    for (i=0;i<2*MAX_X-1;i++) {
        MDC2DclockH(); 
        MDC2DclockV();
        gotVsync |= !vsync;
        gotHsync |= !hsync;
    }
    
    if(!gotVsync && !gotVsync) {
        while(1){} //enter infinite loop so that the upper LED never lights up to signal malfunction during init
        
    }  
    }
	#endif	

    //Reset scanner 
    MDC2DresetToOrigin(); // go to (posX,posY) = (0,0) 
	ADCreset=1;
	ADCreset=0;
}






    
    





//-----------------------------------------------------------------------------
// Delay
//-----------------------------------------------------------------------------
//
// Used for a small pause
//
//-----------------------------------------------------------------------------

//200us delay in full speed
void delay(void)
{
   int x;
   for(x = 0;x < 500;x)
      x++;
}





//-----------------------------------------------------------------------------
// End Of File
//-----------------------------------------------------------------------------

//#############################################################################
