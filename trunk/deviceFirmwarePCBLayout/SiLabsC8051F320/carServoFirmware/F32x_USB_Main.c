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
// this firmware is for controller speed and steering servos on RC car by radio and from computer output
// simultaneously. the computer controls the servo unless the radio output changes away from its zero value, in 
// which case the radio controls the servo and the computer is locked out

// tobi jan 2007

//-----------------------------------------------------------------------------
// Includes
//-----------------------------------------------------------------------------

#include "c8051f320.h"
#include "F32x_USB_Register.h"
#include "F32x_USB_Main.h"
#include "F32x_USB_Descriptor.h"

//-----------------------------------------------------------------------------
// Globals
//-----------------------------------------------------------------------------
sbit	Led	=	P0^7;	//	LED='1' means ON

// servos and radio inputs are confusing because of board flipped mislabling
// servo 0 (labeled SO on board) is actually PCA channel 3 input CEX3 
// servo 1 (labeled S1) is PCA channel 2
// and radio input 0 (labeled S2 on board) is PCA channel 1
// and radio input 1 (labeled S3 on board) is PCA channel 0
// note this numbering goes with flipped labeling on PCB
//.S0-3 refer to PCB labeling

sbit	S0 	= 	P1^3; // steering servo output is S0
sbit	S1 	= 	P1^2; // speed servo output is S1

sbit 	S2	=	P1^1; // radio steering input is S2
sbit	S3	=	P1^0; // radio speed input is S3

sbit p20=P2^0;
sbit p21=P2^1; // debugging

#define LedOn() Led=0;
#define LedOff()  Led=1;
#define LedToggle() Led=!Led; // this may not work because it reads port and then writes opposite

// define command codes - same as in java SiLabs_C8051F320_ServoCarController.java
#define MSG_PULSE_WIDTH 1 // msg sent IN to host for radio steering and speed

// cmds sent OUT from host
#define CMD_SET_SERVO 7 
#define CMD_DISABLE_SERVO 8
#define CMD_SET_ALL_SERVOS 9
#define CMD_DISABLE_ALL_SERVOS 10
#define CMD_SET_DEADZONE_SPEED 11
#define CMD_SET_DEADZONE_STEERING 12
#define CMD_SET_LOCKOUT_TIME 13
#define CMD_NO_RADIO_TIMEOUT_COUNT 14

// PWM servo output variables. these are used to hold the new values for the PCA compare registers so that 
// they can be updated on the interrupt generated when the value can be updated safely without introducing glitches.
unsigned char pwmNumber, pwml0, pwmh0, pwml1, pwmh1;

// this union lets you access the msb and lsb of a short value (16 bit) as a short or as the bytes.
// the bytes are stored in big endian format (as the C51 compiler does arithmetic with larger-than-byte types)
union CharArrayOrShort {
	unsigned short shortValue;
	unsigned char bytes[2];
	unsigned char msb,lsb;
	} ;

union UnsignedLong {
	unsigned long longValue;
	unsigned bytes[4];
	};


union CharArrayOrShort s2PulseDuration, s2pcaEndCount, s2pcaStartCount;
union CharArrayOrShort s3PulseDuration, s3pcaEndCount, s3pcaStartCount;
union CharArrayOrShort speedDeadzone, steeringDeadzone;

bit overrideS0=0, overrideS1=0;

// pca clk freq is 4MHz, period is 1/4Mhz=250ns. E.g. 4000 counts is 1ms
#define SERVO_PWM_READ_ZERO_VALUE 6000 // this pwm capture value for radio pulse output corresponds to 1.5ms (at pca clk of 4MMz)
#define SERVO_PWM_SET_ZERO_VALUE 0xFFFF-SERVO_PWM_READ_ZERO_VALUE // sets zero output
#define SERVO_NONZERO_THRESHOLD 400 // if radio servo output differs from zero value by this much we override computer
#define CYCLE_TIME_US 9 // measured main loop cycle time in us


// timeout in main loop cycles before no radio servo input allows computer to take control
#define NO_RADIO_TIMEOUT 1000000/CYCLE_TIME_US // 1 second timeout

idata BYTE Out_Packet[64];             // Last packet received from host
idata BYTE In_Packet[64];              // Next packet to sent to host

// Holds the status for each endpoint
extern BYTE Ep_Status[];

void	Port_Init(void);			//	Initialize Ports Pins and Enable Crossbar
void	Timer_Init(void);			// Init timer to use for spike event times
void Main_Fifo_Write(BYTE addr, unsigned int uNumBytes, BYTE * pData);
bit isNonZeroServoPulseLength(unsigned short pulseLength, unsigned short threshold);
unsigned short computePulseDuration(unsigned short startCount, unsigned short endCount);

// this value is the lockout time after no more radio input that the pwm outputs are held at the latest value
unsigned long int overrideTimeoutCounter;
union UnsignedLong noRadioTimeoutValue;

// radio input is at 50 Hz.
// if radio xtr is off then radio output is noisy digital signal at about 1Hz and irregular timing of ~0.5ms pulses
// this means that the car can jerk around and go wild if the radio gets out of range. The reason is that
// this firmware transmits the last radio input on the servo output continuously, even if the radio input is
// intermittent. To fix this we only transmit the radio input as servo output for a number of main loop cycles such 
// that we only send out for 50ms after the last radio input. since the radio input is 50Hz=20ms we will only send for about
// 3 missing radio cycles.
// 50ms is 50000us ~ 6000 main loop cycles (6k*9us=54ms).
// cycles left to send after last radio input
#define CYCLES_TO_SEND_AFTER_MISSING_RADIO 1000
unsigned int cyclesLeftToSend=CYCLES_TO_SEND_AFTER_MISSING_RADIO;


//-----------------------------------------------------------------------------
// Main Routine
//-----------------------------------------------------------------------------
void main(void)
{
	char cmd;

   PCA0MD &= ~0x40;                    // Disable Watchdog timer

   Sysclk_Init();                      // Initialize oscillator
   Port_Init();                        // Initialize crossbar and GPIO
   Usb0_Init();                        // Initialize USB0
   Timer_Init();                       // Initialize timer2
	LedOn(); 

	// init servo values to zero value (1.5 ms)
	pwmh0=(SERVO_PWM_SET_ZERO_VALUE>>8)&0xFF;
	pwml0=(SERVO_PWM_SET_ZERO_VALUE&0xff);
	pwmh1=(SERVO_PWM_SET_ZERO_VALUE>>8)&0xFF;
	pwml1=(SERVO_PWM_SET_ZERO_VALUE&0xff);
	PCA0CPM3 |= 0x49; // enable compare function and match and interrupt for match for pca
	PCA0CPM2 |= 0x49; // enable compare function and enable match and interrupt for match for pca

	// initialize speed and steering dead zones
	speedDeadzone.shortValue=SERVO_NONZERO_THRESHOLD;
	steeringDeadzone.shortValue=SERVO_NONZERO_THRESHOLD;

	// initialize the timeout where computer control is locked out by radio input
	noRadioTimeoutValue.longValue=NO_RADIO_TIMEOUT;
	overrideTimeoutCounter=NO_RADIO_TIMEOUT;

	
/*	S0=0;
	S1=0;
	Servo2=0;
	Servo3=0;
*/
   while (1)
   {

		p21=!p21; // debug to measure cycle time, 
		// Tobi measured after reset at frequency of  54 kHz. 
		// Only does cycle every two trips (toggles) so period is 18/2 us = 9 us

		// radio input resets override counter and all computer input is blocked until override counter counts down to zero
		// this function doesn't seem to work at all now - car responds to computer input immediately after radio
		// should take about 1 second.
		if(--overrideTimeoutCounter==0){
			overrideS0=0;
			overrideS1=0;
			PCA0CPM2 |= 0x01; // enable interrupt for pca2 = S1 so new value can be written
			PCA0CPM3 |= 0x01; // enable interrupt for pca3 = S0 so stored computer value can be written
			p20=!p20; // toggles every time timeout expires. This happens with radio input at 50Hz 
		}

	    // It is possible that the contents of the following packets can change
	    // while being updated.  This doesn't cause a problem in the sample
	    // application because the bytes are all independent.  If data is NOT
	    // independent, packet update routines should be moved to an interrupt
	    // service routine, or interrupts should be disabled during data updates.

		EA=0; // disable ints
		cmd=Out_Packet[0];
		switch(cmd){
			case CMD_SET_SERVO:
				Out_Packet[0]=0; // command is processed
				LedToggle();
				pwmNumber=Out_Packet[1]; // host sends 3, we get 0, host sends 2, we get 1
				switch(pwmNumber)
				{
				// big endian 16 bit value to load into PWM controller
					case 0:
					{ // servo0
						pwmh0=Out_Packet[2]; // store the PCA compare value for later interrupt to load
						pwml0=Out_Packet[3];
						PCA0CPM3 |= 0x49; // enable compare function and match and interrupt for match for pca
					
					}
					break;
					case 1:
					{ // servo1
						pwmh1=Out_Packet[2];
						pwml1=Out_Packet[3];
						PCA0CPM2 |= 0x49; // enable compare function and enable match and interrupt for match for pca
					}
					break;
				}			

				break;
			case CMD_DISABLE_SERVO:
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				pwmNumber=Out_Packet[1];
				switch(pwmNumber)
				{
				// big endian 16 bit value to load into PWM controller
					case 0:
					{ // servo0
						PCA0CPM3 &= ~0x40; // disable compare function, thus turn off pwm output
					}
					break;
					case 1:
					{ // servo1
						PCA0CPM2 &= ~0x40; // disable compare function
					}
					break;
				}			
			}
			break;
			case CMD_SET_ALL_SERVOS: // cmd: CMD, PWMValue0 (2 bytes bigendian), PWMValue1 (2 bytes bigendian)
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				pwmh0=Out_Packet[1]; // store the PCA compare value for later interrupt to load
				pwml0=Out_Packet[2];
				PCA0CPM3 |= 0x49; // enable compare function and match and interrupt for match for pca
				pwmh1=Out_Packet[3];
				pwml1=Out_Packet[4];
				PCA0CPM2 |= 0x49; // enable compare function and enable match and interrupt for match for pca
			}	
			break;
			case CMD_DISABLE_ALL_SERVOS: 	//cmd: CMD
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				PCA0CPM3 &= ~0x40; // disable compare function
				PCA0CPM2 &= ~0x40; // disable compare function
			}
			break;			
/* the following don't work for some reason
			case CMD_SET_DEADZONE_SPEED: // cmd: CMD, deadzone (2 bytes big endian)
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				speedDeadzone.bytes[0]=Out_Packet[1]; 
				speedDeadzone.bytes[1]=Out_Packet[2]; 
			}	
			break;
			case CMD_SET_DEADZONE_STEERING: // cmd: CMD, deadzone (2 bytes big endian)
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
				steeringDeadzone.bytes[0]=Out_Packet[1]; 
				steeringDeadzone.bytes[1]=Out_Packet[2]; 
			}	
			break;
			case CMD_SET_LOCKOUT_TIME: // cmd: CMD, lockout time (4 bytes big endian)
			{
				Out_Packet[0]=0; // command is processed
				noRadioTimeoutValue.bytes[0]=Out_Packet[1];
				noRadioTimeoutValue.bytes[1]=Out_Packet[2];
				noRadioTimeoutValue.bytes[2]=Out_Packet[3];
				noRadioTimeoutValue.bytes[3]=Out_Packet[4];
				LedToggle();
			}	
			break;
*/
			case CMD_NO_RADIO_TIMEOUT_COUNT: // cmd: CMD,  defines cycles until servos turned off after no radio servo input (2 bytes big endian)
			{
				Out_Packet[0]=0; // command is processed
				LedToggle();
//				speedDeadzone.bytes[0]=Out_Packet[1]; 
//				speedDeadzone.bytes[1]=Out_Packet[2]; 
			}	
			break;

		} // switch
		EA=1; // enable interrupts

		// we reset this counter to starting value on each radio input interrupt
		if(cyclesLeftToSend!=0) { // if cycle counter has not timed out
			cyclesLeftToSend--;  // decrement counter that is set by radio input.
		}else{ // counter has timed out, turn off servo outputs - no radio input. 
				// servos get turned on again by eacd CMD_SET_SERVO for a while, unless there is no radio input
			PCA0CPM3 &= ~0x40; // disable compare function, turn off servo output
			PCA0CPM2 &= ~0x40; // disable compare function
	}

		//LedOn();
	} // while(1)
}


// pwm interrupt vectored when there is a match or capture interrupt for PCA: only then do we change PCA compare register
void PWM_Update_ISR(void) interrupt 11
{
   BYTE ControlReg;
   bit sendMsg;
   union CharArrayOrShort diff;

	sendMsg=0;
	EIE1 &= (~0x10); // disable PCA interrupt
	// interrupt source comes from PCA0CN bit
	if(CCF3){ // PCA channel 3 = S0 = steering servo output
			CCF3=0; // clear CCF1 interrupt pending flag for PCA1

			// come here when interrupt is because of a match for pca 3
			// the 16 bit compare value defines the number of PCA clocks for the LOW time of the PWM signal.
			// what we care about is the HIGH time for servo control.
			// When the PCA counter matches the module contents, 
			// the output on CEXn is asserted high; when the counter overflows, 
			// CEXn is asserted low. 
			// To output a varying duty cycle, new value writes 
			// should be synchronized with PCA CCFn match interrupts. 
			// 16-Bit PWM Mode is enabled by setting the ECOMn, PWMn, and PWM16n bits in the 
			// PCA0CPMn register. For a varying duty cycle, match interrupts should be enabled 
			// (ECCFn = 1 AND MATn = 1) to help synchronize the capture/compare register writes.
			
			if(overrideS0){
				diff.shortValue=0xFFFF-s2PulseDuration.shortValue;
				PCA0CPL3=diff.lsb;
				PCA0CPH3=diff.msb;				
			}else{
				PCA0CPL3=pwml0;
				PCA0CPH3=pwmh0;
			}
			PCA0CPM3 &= (~0x01); // disable interrupt because we have written the new value, 
								// no need for interrupt until we have a new value because PCA will just put out sq wave
	}
	if(CCF2){ // PCA chan 2 = S1 = speed servo output
			CCF2=0; // clear CCF2 interrupt pending flag for PCA2
			if(overrideS1){
				diff.shortValue=0xFFFF-s3PulseDuration.shortValue;
				PCA0CPL2=diff.lsb;
				PCA0CPH2=diff.msb;
			}else{
				PCA0CPL2=pwml1;
				PCA0CPH2=pwmh1;
			}
			PCA0CPM2 &= (~0x01); // disable interrupt, only enable when we have a new value
	}
	if(CCF1){ // S2 = radio steering input
			cyclesLeftToSend=CYCLES_TO_SEND_AFTER_MISSING_RADIO; //. turn on servo output for a while
			CCF1=0;
			// pca chan 1 = cex1 = p2.1 = "S2 on board" = radio receiver servo output that is input for "S0" servo input override
			// we come here when a capture happens on cex1, i.e., when the radio receiver pwn servo output
			// changes. here we check whether the transistion was to go high (start of pulse) or low (end of pulse)

			// We capture the time interval for the high part of the pulse because we need this time
			// to derive the low time for the servo PCA outputs (pca 0,1) in the case we override the computer
			// servo values.

			// at start of pulse
//				p20=1; // debug
			if(S2==1){
				// start of pulse
				// for some reason reading the PCA0 capture registers doesn't record the correct value!!
				// we use the PCA counter instead for a software measure
				s2pcaStartCount.lsb=PCA0L; // read LSB first PCA0CPL1; 
				s2pcaStartCount.msb=PCA0H; // PCA0CPH1; // store them in short in big endian order as keil c51 does arithmetic
			}else{
				// end of pulse
				s2pcaEndCount.lsb=PCA0L; // read LSB first to latch in snapshot // PCA0CPL1; // big endian keil order for shorts
				s2pcaEndCount.msb=PCA0H; // PCA0CPH1;
				s2PulseDuration.shortValue=computePulseDuration(s2pcaStartCount.shortValue, s2pcaEndCount.shortValue);
				if(isNonZeroServoPulseLength(s2PulseDuration.shortValue,steeringDeadzone.shortValue)){
					overrideS0=1;
					sendMsg=1;
					overrideTimeoutCounter=noRadioTimeoutValue.longValue; // since we got a radio input, lock out computer control
				}else{
					if(overrideS0) sendMsg=1;
					overrideS0=0; 
				}		
				
					PCA0CPM3 |= 0x01; // enable interrupt for pca3 = S0 so new value can be written
					PCA0CPM3 |= 0x49; // enable compare function and enable match and interrupt for match for pca

				if(sendMsg){
					In_Packet[0]=MSG_PULSE_WIDTH;
					In_Packet[1]=2; // this corresponds by our convention to "S2" board input
					In_Packet[2]=s2PulseDuration.msb; // write them to host in big endian format MSB first
					In_Packet[3]=s2PulseDuration.lsb; // then LSB

					POLL_WRITE_BYTE(INDEX, 1);           // Set index to endpoint 1 registers
					POLL_READ_BYTE(EINCSR1, ControlReg); // Read contol register for EP 1
					if(! (ControlReg & rbInINPRDY) ){
						Main_Fifo_Write(FIFO_EP1, 4, (BYTE *)In_Packet);
						POLL_WRITE_BYTE(EINCSR1, rbInINPRDY); // commit the packet
					}
				}

			}
//			p20=0;
	}
	if(CCF0){ // S3 radio speed input
			cyclesLeftToSend=CYCLES_TO_SEND_AFTER_MISSING_RADIO; //. turn on servo output for a while
			CCF0=0;
			// pca0 channel 0, cex0, S3 on pcb, corresponds to S1 servo output
			if(S3==1){
				// start of pulse
				s3pcaStartCount.lsb=PCA0L; // read, stores into snapshot // PCA0CPL0; 
				s3pcaStartCount.msb=PCA0H; // PCA0CPH0; // store them in short in big endian order as keil c51 does arithmetic
			}else{
				s3pcaEndCount.lsb=PCA0L; // PCA0CPL0; // big endian keil order for shorts
				s3pcaEndCount.msb=PCA0H; // PCA0CPH0;
				s3PulseDuration.shortValue=computePulseDuration(s3pcaStartCount.shortValue, s3pcaEndCount.shortValue);
				if(isNonZeroServoPulseLength(s3PulseDuration.shortValue,speedDeadzone.shortValue)){
					overrideS1=1;
					sendMsg=1;
					overrideTimeoutCounter=noRadioTimeoutValue.longValue; // since we got a radio input, lock out computer control
				}else{
					if(overrideS1) sendMsg=1;
					overrideS1=0;
				}		
				
					PCA0CPM2 |= 0x01; // enable interrupt for pca2 = S1 so new value can be written
					PCA0CPM2 |= 0x49; // enable compare function and enable match and interrupt for match for pca
				if(sendMsg){
					In_Packet[0]=MSG_PULSE_WIDTH;
					In_Packet[1]=3; // this corresponds by our convention to "S0" servo output
					In_Packet[2]=s3PulseDuration.msb; // write them to host in big endian format MSB first
					In_Packet[3]=s3PulseDuration.lsb; // then LSB

					POLL_WRITE_BYTE(INDEX, 1);           // Set index to endpoint 1 registers
					POLL_READ_BYTE(EINCSR1, ControlReg); // Read contol register for EP 1
					if(! (ControlReg & rbInINPRDY) ){
						Main_Fifo_Write(FIFO_EP1, 4, (BYTE *)In_Packet);
						POLL_WRITE_BYTE(EINCSR1, rbInINPRDY); // commit the packet
					}
				}
			}
	}
	// values sent range from 5400 to 12097 with "servo zero" 1.5ms resulting in 9000 being sent
	EIE1 |= 0x10; // reenable PCA interrupt
}

/** @return true if the pulse width is outside "servo zero" value */
bit isNonZeroServoPulseLength(unsigned short pulseLength, unsigned short threshold){
	if(pulseLength>SERVO_PWM_READ_ZERO_VALUE+threshold) 
		return 1;
	if(pulseLength<SERVO_PWM_READ_ZERO_VALUE-threshold) 
		return 1;
	return 0;
}

/** computes the pulse width even if the counter wraps around */
unsigned short computePulseDuration(unsigned short startCount, unsigned short endCount){
	if(endCount>=startCount) return endCount-startCount;
	// if counter wraps, we take distance to end of count from start count and add end count
	return (0xFFFF-startCount)+endCount;
}

//-----------------------------------------------------------------------------
// Fifo_Write
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   :
//                1) BYTE addr : target address
//                2) unsigned int uNumBytes : number of bytes to unload
//                3) BYTE * pData : location of source data
//
// Write to the selected endpoint FIFO
//
//-----------------------------------------------------------------------------

void Main_Fifo_Write(BYTE addr, unsigned int uNumBytes, BYTE * pData)
{
   int i;

   // If >0 bytes requested,
   if (uNumBytes)
   {
      while(USB0ADR & 0x80);              // Wait for BUSY->'0'
                                          // (register available)
      USB0ADR = (addr);                   // Set address (mask out bits7-6)

      // Write <NumBytes> to the selected FIFO
      for(i=0;i<uNumBytes;i++)
      {
         USB0DAT = pData[i];
         while(USB0ADR & 0x80);           // Wait for BUSY->'0' (data ready)
      }
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
#ifdef _USB_LOW_SPEED_

   OSCICN |= 0x03;                     // Configure internal oscillator for
                                       // its maximum frequency (12 MHz) and enable
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
   CLKSEL  = SYS_INT_OSC;              // Select system clock = 12 MHz
   CLKSEL |= USB_4X_CLOCK;             // Select USB clock (48 MHz)
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

	XBR0 = 0x00;	// Crossbar Register 1
	XBR1 = 0xc4;	// Crossbar Register 2 = 1100 0100 = WEAKPUD (weak pullups disabled) + XBARE (crossbar enable) + CEX0-3

// Select Pin I/0

// NOTE: Some peripheral I/O pins can function as either inputs or 
// outputs, depending on the configuration of the peripheral. By default,
// the configuration utility will configure these I/O pins as push-pull 
// outputs.
                      // Port configuration (1 = Push Pull Output)
    P0MDOUT = 0x00; // Output configuration for P0 
    P1MDOUT = 0x0c; // Output configuration for P1 // bits 3,2 are outputs ("S0, S1"), others inputs, bits 1,0 are radio receiver servo inputs 
    P2MDOUT = 0x0f; // Output configuration for P2 // make ls nibble output for debugging
    P3MDOUT = 0x00; // Output configuration for P3 

    P0MDIN = 0xFF;  // Input configuration for P0
    P1MDIN = 0xFF;  // Input configuration for P1
    P2MDIN = 0xFF;  // Input configuration for P2
    P3MDIN = 0xFF;  // Input configuration for P3

    P0SKIP = 0xFF;  //  Port 0 Crossbar Skip Register
    P1SKIP = 0x00;  //  Port 1 Crossbar Skip Register // CEX go to port 1
    P2SKIP = 0x00;  //  Port 2 Crossbar Skip Register

// View port pinout

		// The current Crossbar configuration results in the 
		// following port pinout assignment:
		// Port 0
		// P0.0 = Skipped         (Open-Drain Output/Input)(Digital)
		// P0.1 = Skipped         (Open-Drain Output/Input)(Digital)
		// P0.2 = Skipped         (Open-Drain Output/Input)(Digital)
		// P0.3 = Skipped         (Open-Drain Output/Input)(Digital)
		// P0.4 = Skipped         (Open-Drain Output/Input)(Digital)
		// P0.5 = Skipped         (Open-Drain Output/Input)(Digital)
		// P0.6 = Skipped         (Open-Drain Output/Input)(Digital)
		// P0.7 = Skipped         (Open-Drain Output/Input)(Digital)

        // Port 1
		// P1.0 = PCA CEX0        (Push-Pull Output)(Digital)
		// P1.1 = PCA CEX1        (Push-Pull Output)(Digital)
		// P1.2 = PCA CEX2        (Push-Pull Output)(Digital)
		// P1.3 = PCA CEX3        (Push-Pull Output)(Digital)
		// P1.4 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P1.5 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P1.6 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P1.7 = GP I/O          (Open-Drain Output/Input)(Digital)

        // Port 2
		// P2.0 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P2.1 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P2.2 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P2.3 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P2.4 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P2.5 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P2.6 = GP I/O          (Open-Drain Output/Input)(Digital)
		// P2.7 = GP I/O          (Open-Drain Output/Input)(Digital)

        // Port 3
		// P3.0 = GP I/O          (Open-Drain Output/Input)(Digital)


	XBR1|=0x40; 	// 0100 0000 enable xbar, setting XBARE


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
   BYTE Count;

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

    CKCON = 0x04; // t0 clked by sysclk=12 MHz 0x04;   // Clock Control Register, timer 0 uses prescaled sysclk/12. sysclk is 24MHz.
	TMOD = 0x12;    // Timer Mode Register, timer0 8 bit with reload, timer1 16 bit
   	TCON = 0x50;    // Timer Control Register , timer0 and 1 running
    TH0 = 0xFF-2; 	    // Timer 0 High Byte, reload value. 
						//This is FF-n so timer0 takes n+1 cycles = to roll over, time is (n+1)/12MHz 
						// (12MHz = Sysclk) =1/4 us 
    TL0 = 0x00;     // Timer 0 Low Byte
 	
	CR=1;			// run PCA counter/timer
	

	PCA0MD|=0x84;	// use timer0 overflow to clock PCA counter, 
					// PCA counter clocks at 4 MHz. leave wdt bit undisturbed. turn off PCA in idle.

	// pca pwm output frequency depends on pca clock source because pca counter rolls over
	// every 64k cycles. we want pwm update frequency f to be about 100 Hz which means rollower
	// should happen about every 10ms, therefore (1/f)*64k=10ms means f=6.5MHz

	// PCA3 and PCA2 are used for servo motor output

	// using new PCA clocking above, each count takes 1/4 us, giving about 16.38 ms servo period=61 Hz servo update rate,
	// pca is 16 bit = 65k counts = 16 bit count varies pulse width. 
	// PCA value defines low time, therefore pulse width
	// is 65k-PCA value, e.g., if PCA0CP1 value=63k, for example, pulse width will be (64-63)=1k counts=1k/4e6Hz=250 us

	// servo motors respond to high pulse widths from 0.9 ms to 2.1 ms. CPL values encode time that PCA PWM output is low.
	// therefore we need to load a value that is 64k-counthigh. This computation is done on the host so that the interrupt service routine
	// just loads the low and high byte values into the capture compare registers.	

	// servos 0,1 output from pca 3,2
	PCA0CPM3=0xC2; // PWM16+ECOM+PWM: 16 bit mode, PCA compare enabled, PWM output to CEX3 
	PCA0CPM2=0xC2; // PWM16+ECOM+PWM: 16 bit mode, PCA compare enabled, PWM output to CEX2 

	// pca 1,0 are used for S2, S3 inputs from radio
	PCA0CPM1=0x31; // capture pos/neg, capture int enabled 
	PCA0CPM0=0x31; // capture pos/neg, capture int enabled 

//	EIP1 |= 0x10; // set PCA interrupt to high priority
	EIE1 |= 0x10; // enable PCA interrupt
	
}

//-----------------------------------------------------------------------------
// Delay
//-----------------------------------------------------------------------------
//
// Used for a small pause, approximately 80 us in Full Speed,
// and 1 ms when clock is configured for Low Speed
//
//-----------------------------------------------------------------------------

void Delay(void)
{
   int x;
   for(x = 0;x < 500;x)
      x++;
}

//-----------------------------------------------------------------------------
// End Of File
//-----------------------------------------------------------------------------