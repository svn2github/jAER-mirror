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

//#define NOCHIP  //Debugging without motion chip
//#define DEBUG   //General debugging
//#define TESTIMAGE

#define MAX_X 31
#define MAX_Y 31
#define BORDER_X 31
#define BORDER_Y 31
#define MAX_PACKET_SIZE EP1_PACKET_SIZE //' Can this be bigger if we move to EP3??
//#define MOTION18_CLOCK_DELAY 0   //' Value??
#define FRAME_START_MARKER 0xac


sbit upperLed = P1^4;                      // LED='1' means ON
sbit lowerLed = P1^5;                      // blink to indicate data transmission

sbit notSync = P0^3;  //for SPI
sbit notReset = P0^6; //DAC Reset

sbit clkH = P1^7;
sbit clkV = P1^6;

sbit hSync = P1^0;
sbit vSync = P1^2;
sbit or_h  = P1^1;


bit vxIsRequested, vyIsRequested, svxIsRequested, svyIsRequested, sph0IsRequested; //Working copies for the present frame
bit putVx, putVy, putSvx, putSvy, putSph0; //Set by the host
//bit onBorder; //Motion chip is on border
bit hostInRequest, doReset, doStream;

#ifdef TESTIMAGE
bit toggle;
#endif

unsigned char posX=0; //the actual position of the motionChip registers
unsigned char posY=0;
unsigned int i = 0;
unsigned char c = 0;
unsigned char byteBuf, bitsInBuf; //shiftSize with Enum? (0,2,4,6)


void Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void Timer_Init(void);			// Init timer to use for spike event times
void initDAC(void);
void initADC(void);
void setBiasV( unsigned char msb, unsigned char lsb, unsigned char address);
void sendSPI24(unsigned char dat1, unsigned char dat2, unsigned char dat3);
void readVoltage(char amxPort, char nextPort);
void usbCommitByte(unsigned char dat);
void motion18resetToOrigin(void);
void motion18clockH(void);//(unsigned char delay);
void motion18clockV(void);//(unsigned char delay);
void motion18goToNextPixel(void);
void motion18resetX(void);
void usbCommitPacket(void);
void countDelay(unsigned char c);

#ifdef DEBUG
void readDAC(void); //Debug only
void setMonitorChannel(unsigned char chan);
unsigned int j = 0;           
#endif

//-----------------------------------------------------------------------------
// Main Routine
//-----------------------------------------------------------------------------
void main(void)
{

   unsigned char frameDescriptor;     //' The frame-descriptor holds information about data in the frame.   
   unsigned char chanOrder[3];
   unsigned char chanOrderLength;


#ifdef DEBUG
   //unsigned char debug1, debug2;
   unsigned char debug3, db;
   unsigned int debug4;
#endif
   
   vxIsRequested = 1;
   vyIsRequested = 1;
   svxIsRequested = 1;
   svyIsRequested = 1;
   sph0IsRequested = 1;
   putVx=1;
   putVy=1;
   putSvx=1;
   putSvy=1;
   putSph0=1; 
   doReset=0;
   doStream=0;

   hostInRequest = 0; //' We start without IN transfer initiated by the host.
   byteBuf=0;
   bitsInBuf=0;
  
   PCA0MD &= ~0x40;                    // Disable Watchdog timer

   Sysclk_Init();                      // Initialize oscillator
   Port_Init();                        // Initialize crossbar and GPIO
   Usb0_Init();                        // Initialize USB0
   Timer_Init();                       // Initialize timer2
   initADC();
  
   for(i=0;i<5000;i++)
   {
     Delay();
   }

   initDAC(); 
                            //' Initialize the external DAC
#ifdef DEBUG
   debug4 = 4096*2.75/5; // To get 2 Volts   //DEBUG
   //debug4 = 0x0800;
   //debug4=0x0FFF;
   debug3 = (unsigned char) (debug4>>8);  //DEBUG
   for(db = 0; db<1;db++)
   {
     setBiasV( (unsigned char) (debug4>>8), (unsigned char) debug4, db);//DAC_ADDR_HDBIAS);  //DEBUG
   } 
   //setMonitorChannel(0);
   //Delay();     //DEBUG
//   readDAC(); //DEBUG
#endif

   motion18resetToOrigin(); // go to (posX,posY) = (0,0)
   i=0;
   while (1)
    {
#ifdef DEBUG
	   POLL_WRITE_BYTE(INDEX, 1); //DEBUG
	   POLL_READ_BYTE(EINCSR2, debug3); //DEBUG
  	   POLL_READ_BYTE(EINCSR1, debug4); //DEBUG
#endif

	   upperLed = 1;
//	   lowerLed = !lowerLed;  
       while(!doStream);
	   if(doReset)
	   {
	      motion18resetToOrigin();
          doReset=0;
	   }
	   if(!posX && !posY) // If we are at (0,0) //TODO: What if only globals are required
	   { 
	     EA=0; // Disable interrupts
	     vxIsRequested =putVx;
		 vyIsRequested =putVy;
		 svxIsRequested =putSvx;
		 svyIsRequested =putSvy;
		 sph0IsRequested= putSph0;   //Working copies for the present frame
         EA=1;
		 usbCommitByte(FRAME_START_MARKER);
         frameDescriptor = ((unsigned char)vxIsRequested * DESCR_FLAG_VX)|((unsigned char)vyIsRequested * DESCR_FLAG_VY)|((unsigned char)svxIsRequested * DESCR_FLAG_SVX)|((unsigned char)svyIsRequested * DESCR_FLAG_SVY)|((unsigned char)sph0IsRequested * DESCR_FLAG_SPH0);
         usbCommitByte(frameDescriptor);		 
		
		 chanOrderLength=0;	
		 if(sph0IsRequested)
		    chanOrder[chanOrderLength++] = AMX_SPH0;
		 if(svxIsRequested) 
		    chanOrder[chanOrderLength++] = AMX_SVX;
		 if(svyIsRequested)
 		    chanOrder[chanOrderLength++] = AMX_SVY;

         byteBuf=0;
		 bitsInBuf=0;

         if(vxIsRequested)
	     {
           readVoltage(AMX_VX, AMX_VY);
         }

         if(vyIsRequested)
  	     {
           readVoltage(AMX_VY, AMX_SPH0);
         }
	   }
      
	  for(c=0;c<chanOrderLength; c++)
      {
	      readVoltage(chanOrder[c], chanOrder[(c+1) % chanOrderLength]);
	  }

 /*     if(!onBorder)
	  {
        if(svxIsRequested)
	     {
           readVoltage(AMX_SVX);
         }

        if(svyIsRequested) 
  	     {
           readVoltage(AMX_SVY);
         }
       }

       if(sph0IsRequested)
	     {
           readVoltage(AMX_SPH0);
         }
*/	   
	    
       if( ((posX==MAX_X) & (posY==MAX_Y)) || !(svxIsRequested||svyIsRequested||sph0IsRequested)) // Frame is completely read, or only globals are required
	   {
          usbCommitPacket();
	   }

       motion18goToNextPixel();
	   /*if(posX==1)
	   {
	   	   countDelay(50);
	   }*/

	}
}

void motion18clockH()//(unsigned char delay)
{
	clkH = 0;
	//while(delay--);
	clkH=1;
}

void motion18clockV()//(unsigned char delay)
{
	clkV = 0;
	//while(delay--);
	clkV = 1;
}

void motion18goToNextPixel()
{
  if((posX == MAX_X) && (posY == MAX_Y))
  {
    motion18resetToOrigin();
  }
  else if(posX == MAX_X)
  {
    motion18resetX();
	motion18clockV();//(MOTION18_CLOCK_DELAY);
	posY++;
  }
  else
  {
	motion18clockH();//(MOTION18_CLOCK_DELAY);
    posX++;
  }
/*
  if(!posX || !posY || posX==BORDER_X||posY==BORDER_X)
    onBorder=1;
  else
    onBorder=0;
*/  

}

void motion18resetX()
{
   #ifndef NOCHIP
   while(or_h)
  {
     motion18clockH();//(MOTION18_CLOCK_DELAY);   
  }
     while(!or_h)
  {
     motion18clockH();//(MOTION18_CLOCK_DELAY);   
  }
  #endif
  posX=0;

}

void motion18resetToOrigin(void)
{
  motion18resetX();
  
  #ifndef NOCHIP
  while(vSync)
  {
     motion18clockV();//(MOTION18_CLOCK_DELAY);   
  }
  while(!vSync)
  {
     motion18clockV();//(MOTION18_CLOCK_DELAY);   
  }

  #endif
  posX=0;
  posY=0;
//  onBorder=1;
}

#ifndef TESTIMAGE
void readVoltage(char amxPort, char nextPort)
{
         unsigned char AmxL, AmxH;
		 lowerLed=0;
/*         if(onBorder && ( (amxPort == AMX_SVX) || (amxPort == AMX_SVY) )) //In case we are on the border
		 { 		 
		     AMX0P = AMX_SPH0;	//Start ADC on
		     AD0INT=0;
             AD0BUSY = 1;      //' Start conversion process
		   return;
		 }
*/		 
         if((AMX0P != amxPort) || !c) //If the conversion has not already been started, start it
		 {                    // (This should only happen for the globals.)
		   AMX0P = amxPort;		 
		   AD0INT=0;
           AD0BUSY = 1;      //' Start conversion process
		 }
		 while(AD0INT!=1); //' Wait until conversion is finished
		 lowerLed=1;

         AmxL=ADC0L; //Save the converted values
		 AmxH=ADC0H;
		            
         AMX0P = nextPort; //Start next conversion which will be worked on 	 
		 AD0INT=0;
         AD0BUSY = 1;

		 usbCommitByte(byteBuf | (AmxH >> bitsInBuf)); //Send the converted value
		 byteBuf= (AmxH<<(8-bitsInBuf)) | (AmxL>>bitsInBuf);  //ADC has to be in Left-justified mode!
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
void readVoltage(char amxPort, char nextPort) //DEBUG!
{
         unsigned char amxH;
		 unsigned char amxL;
//		 usbCommitByte(byteBuf | ((posX) >> bitsInBuf));
//		 byteBuf= (posX<<(8-bitsInBuf)) | (0x0>>bitsInBuf);  //ADC has to be in Left-justified mode!

//		 usbCommitByte(byteBuf | ((amxPort) >> bitsInBuf));
//		 byteBuf= (amxPort<<(8-bitsInBuf)) | (0x0>>bitsInBuf);  //ADC has to be in Left-justified mode!
         toggle = !toggle;
		 if(toggle)
		 {
//         amxH = 0x7F;
//		   amxL = 0xC0;
		   amxH = 0x40;
		   amxL = 0x00;

		 }
		 else
		 {
//		   amxH = 0x80;
//		   amxL = 0x00;
		   amxH = 0xC0;
		   amxL = 0x00;
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
#endif

void usbCommitByte(unsigned char dat)
{
   i++;
   EA=0;
   POLL_WRITE_BYTE(FIFO_EP1, dat);
   EA=1;
   if(i==MAX_PACKET_SIZE)
   {
      usbCommitPacket();
      //while(!hostInRequest);
   }
}

void usbCommitPacket()
{
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

	  #ifdef DEBUG
	  j++;
	  #endif
	  //if(j==2)//DEBUG
	  //  while(1);
}


void initDAC()
{
   unsigned int cnt = 0x3000;
   notReset = 0;
   while(cnt--);
   notReset=1;
 //  cnt=0x3000;
   while(cnt--);
     //write to control register
 //  sendSPI24(0x0C,0x35,0x00);  // 00 00 1100 00 110101XXXX00 XX: PwrDwnMd,internalRef=2.5V,CurrentBoostOff,internalRef select,Mon On,TermMonOff(good?),4dc,ToggleOff
   sendSPI24(0x0C,0x3E,0x00);    // 00 00 1100 00 111110XXXX00 XX
                               // 0 W 00 A3..A0 Reg1 Reg0 CR11..CR0 XX
   // gains und offsets setzen?
}

void setBiasV( unsigned char msb, unsigned char lsb, unsigned char address)
{
   unsigned char dat1 = 0x00; //00 00 0000;
   unsigned char dat2 = 0xC0; //Reg1=1 Reg0=1 : Write output data
   unsigned char dat3 = 0x00;

   dat1 |= (address & 0x0F);
   dat2 |= ((msb & 0x0F) << 2) | ((lsb & 0xC0)>>6) ;
   dat3 |= (lsb << 2) | 0x03; // DEBUG; the last 2 bits are actually don't care
   
   sendSPI24(dat1, dat2, dat3); 

}

#ifdef DEBUG
void setMonitorChannel(unsigned char chan)// A3..0: 1010  Reg1..0: 00 Db11..Db06: chan
{
   sendSPI24(0x0a, chan & 0x0F, 0x00); //0000 1010 00 00 cccc xxxxxx xx
}
#endif

void sendSPI24(unsigned char dat1, unsigned char dat2, unsigned char dat3)
//Send a 24bit value to the DAC. dat1 is the MSB, dat3 the LSB.
{  
   EA=0;
   notSync=0;    //' Trigger DAC. Timing problems? Disable interrupts?
   SPI0DAT = dat1;
   while(!SPIF); //'Wait for completion
   SPIF=0;
  
   SPI0DAT = dat2;
   while(!SPIF); //'Wait for completion
   SPIF=0;
  
   SPI0DAT = dat3;
   while(!SPIF); //'Wait for completion
   SPIF = 0;

   notSync = 1;
   EA=1;
}

#ifdef DEBUG
void readDAC(void)
//Send a 24bit value to the DAC. dat1 is the MSB, dat3 the LSB.
{  
//   unsigned char dat1 = 0x4C; //01 00 1100: read config register
//   unsigned char dat1 = 0x46; //01 00 0x6: read HDBIAS register
   unsigned char dat1 = 0x40; //01 00 0x6: read HDBIAS register

   unsigned char in2=0x00;
   unsigned char in3=0x00;
   unsigned char out2=0x00;
   unsigned char out3=0x00;
   //unsigned int result=0x0000;
   EA=0;
   notSync=0;  
   SPI0DAT = dat1;
   while(!SPIF); //'Wait for completion
   SPIF=0;
  
//   SPI0DAT = 0x00;  // Config reg
//   SPI0DAT = 0x80;  // Offset reg  
//   SPI0DAT = 0x40;  // Gain reg  
   SPI0DAT = 0xC0;  // Data reg
   while(!SPIF); //'Wait for completion
   SPIF=0;
  
   SPI0DAT = 0x00;
   while(!SPIF); //'Wait for completion
   SPIF = 0;

   notSync = 1;

   Delay(); //Timing? 50ns min -> actually only 2 sysclocks
   dat1=0;

   notSync=0;    //' Trigger DAC. Timing problems? Disable interrupts?
   SPI0DAT = 0x00; //NOP
   while(!SPIF); //'Wait for completion
   dat1 = SPI0DAT;
   SPIF=0;
  
   SPI0DAT = 0x00; //NOP
   while(!SPIF); //'Wait for completion
   in2 = SPI0DAT;
   SPIF=0;
  
   SPI0DAT = 0x00; //NOP
   while(!SPIF); //'Wait for completion
   in3 = SPI0DAT;
   SPIF = 0;
   
   notSync = 1;

   out3 = (in3 >> 2) | ((in2 & 0x03)<<6);
   out2 = (in2 & 0x3F)>>2;
   //result = (in3 >> 2); 
   //result &= (((unsigned int)(in2 & 0x3F))<<8);

   EA=1;
}
#endif
void initADC(void)
{
   REF0CN = 0x03;//' XXXX 0011: REFSEL internal, TempSens off, BiasGen on, InternalRef on
//   ADC0CF = 0x3C; //'       00111 1 XX: AD0SC=7, left-justified mode
   ADC0CF = 0x5C; //'       01011 1 XX: AD0SC=11, left-justified mode


   ADC0CN = 0x40;  //' 0100 0 000: AD0EN,Low Power Track mode,Conversion complete Flag,ADC Busy, Window Compare flag, Conversion mode (3b)
   AD0EN = 1;
   AMX0N = AMX_VM; //' V- is negative differential input

}

/*
// pwm interrupt vectored when there is a match interrupt for PCA: only then do we change PCA compare register
void PWM_Update_ISR(void) interrupt 11
{
	EIE1 &= (~0x10); // disable PCA interrupt
	switch(pwmNumber)
	{
		case 0:
			PCA0CPL1=pwml1;
			PCA0CPH1=pwmh1;
			PCA0CPM1 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x02); // clear CCF1 interrupt pending flag for PCA1
			break;
		case 1:
			PCA0CPL2=pwml2;
			PCA0CPH2=pwmh2;
			PCA0CPM2 &= (~0x01); // disable interrupt
			PCA0CN &= (~0x04); // clear CCF2 interrupt pending flag for PCA2
	}
	EIE1 |= 0x10; // reenable PCA interrupt
}
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
                                       // its maximum frequency and enable
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
//'   CLKSEL  = SYS_INT_OSC;              // Select system clock
   CLKSEL |= SYS_4X_DIV_2;             // Select SYSCLK as Clock Multiplier/2

   CLKSEL |= USB_4X_CLOCK;             // Select USB clock
#endif  /* _USB_LOW_SPEED_ */
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
//	XBR0 = 0x00;	// 0000 0000 Crossbar Register 1. no peripherals are routed to output.
//	XBR1 = 0xc3;	// 1000 0011 Crossbar Register 2. no weak pullups, cex0, cex1, cex2 routed to port pins.1100 0011	0xc3

   XBR0 = 0x02;			 //'  SPI I/O enabled in Crossar
//   XBR0 = 0x00;
   XBR1 = 0x00;                    


// Select Pin I/0

// NOTE: Some peripheral I/O pins can function as either inputs or 
// outputs, depending on the configuration of the peripheral. By default,
// the configuration utility will configure these I/O pins as push-pull 
// outputs.

    P2MDIN = 0x88;    //' 10001000   0 = analog. P2.0, P2.1, P2.2, P2.4, P2.5, P2.6 sind analog.

    P0MDIN = 0xFF;  // Input configuration for P0. Not using analog input.
    P1MDIN = 0xFF;  // Input configuration for P1
    P3MDIN = 0xFF;  // Input configuration for P3

//    P0MDOUT = 0xbd; // Output configuration for P0, 1011 1101 bit 0 is ack output, bit 1 is req input, bit 2 is Servo0 output, bit 7 is Servo1 output, bits 3,4,5 are LED outputs
//    P0MDOUT = 0x01; // Output configuration for P0, bit 0 is ack output, bit 1 is req input, 0000 0001, 
					// leds are bits 3,4,5 but are open drain, set bit low to pull down and turn on LED

    P1MDOUT	= 0xF0;	 //'  11110000: LED Pins P1.4, P1.5, P1.6 and P1.7 set to push-pull (LEDs and motion chip clock)
    P0MDOUT = 0x0D; //'   00001101  . P0.0, P0.2 and P0.3 are push-pull
	                                 //' are set to push-pull (V and H clock)
    P2MDOUT = 0x00; // Output configuration for P2  
    P3MDOUT = 0x00; // Output configuration for P3 


    P2SKIP = 0x77;    //' 01110111   1 = skip. Analoge eingaenge sollten übersprungen werden.
    P0SKIP = 0x00;  				
    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register
 
    SPI0CFG |= 0x50; //' X 101 XXXX : MasterEnable, ClockPhase, ClockPolarity 
    SPI0CN  =  0x01; //' 0000 00 X 1 : Flags (4); disable NSS ; SPI enabled
    SPI0CKR =  0x0F; //(DAC could go 50 MHz, but initialization fails stragely. Is notSync the problem? Works from 0x0E)


	XBR1|=0x40; 	// 0100 0000 enable xbar, setting XBARE

    upperLed = 0;
    lowerLed = 1;
    notReset = 1; //for DAC
    notSync  = 1; //for DAC

    clkH = 1;
    clkV = 1;

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
//   BYTE Count;

// Set initial values of In_Packet and Out_Packet to zero
// Initialized here so that WDT doesn't kick in first
//   for (Count = 0; Count < 64; Count++)
//   {
//      Out_Packet[Count] = 0;
//      In_Packet[Count] = 0;
//   }

//   for (Count = 0; Count < 128; Count++)
//   {
//      In_Packet[Count] = 0;
//   }


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

//'    CKCON = 0x04; // t0 clked by sysclk=24MHz 0x04;   // Clock Control Register, timer 0 uses prescaled sysclk/12. sysclk is 24MHz.
//'  TMOD = 0x12;    // Timer Mode Register, timer0 8 bit with reload, timer1 16 bit
//'   	TCON = 0x50;    // Timer Control Register , timer0 and 1 enabled
//'    TH0 = 0xFF-1; 	    // Timer 0 High Byte, reload value. 
						//This is FF-n so timer0 takes n+1 cycles = to roll over, time is (n+1)/12MHz (12MHz = Sysclk)  
//'    TL0 = 0x00;     // Timer 0 Low Byte
 	
//'	CR=1;			// run PCA counter/timer
	// PCA uses timer 0 overflow which is 1us clock. all pca modules share same timer which runs at 1MHz.
	

//'	PCA0MD|=0x84;	// use timer0 overflow to clock PCA counter. leave wdt bit undisturbed. turn off PCA in idle.
//	PCA0MD |= 0x80;	// PCA runs on sysclk/12 (24/12=2 MHz), doesn't run when in idle.
//	PCA0MD =0x88; // PCA uses sysclk = 12  MHz
//	PCA0MD=0x82; // PCA uses sysclk/4=3MHz

	// pca pwm output frequency depends on pca clock source because pca counter rolls over
	// every 64k cycles. we want pwm update frequency to be about 100 Hz which means rollower
	// should happen about every 10ms, therefore (1/f)*64k=10ms means f=6.5MHz
	// but we use sysclk/4=3MHz


	// PCA0CPM0=0x10; 

	// PCA1 and PCA2 are used for servo motor output

	// using new PCA clocking above, each count takes 1/6 us, giving about 91Hz servo update rate

	// pca is 16 bit = 65k counts = =64k*0.5us=32kus=32ms. 16 bit count varies pulse width. 
	// PCA value defines low time, therefore pulse width
	// is 65k-PCA value, if PCA0CP1 value=63k, for example, pulse width will be (64-63)=1k us=1ms.

	// servo motors respond to high pulse widths from 0.9 ms to 2.1 ms. CPL values encode time that PCA PWM output is low.
	// therefore we need to load a value that is 64k-counthigh. This computation is done on the host so that the interrupt service routine
	// just loads the low and high byte values into the capture compare registers.	

//'	PCA0CPM1=0xC2; // PWM16+ECOM+PWM: 16 bit mode, PCA compare enabled, PWM output to CEX1 
//'	PCA0CPM2=0xC2; // PWM16+ECOM+PWM: 16 bit mode, PCA compare enabled, PWM output to CEX2 

//	PCA0CPM1 &= ~0x40; // disable servo
//	PCA0CPM2 &= ~0x40; // disable servo
	
}

//-----------------------------------------------------------------------------
// Delay
//-----------------------------------------------------------------------------
//
// Used for a small pause, approximately 200 us in Full Speed,
//
//-----------------------------------------------------------------------------

void Delay(void)
{
   int x;
   for(x = 0;x < 500;x)
      x++;
}

void countDelay(unsigned char d)
{
   while (d--);
}

//-----------------------------------------------------------------------------
// End Of File
//-----------------------------------------------------------------------------