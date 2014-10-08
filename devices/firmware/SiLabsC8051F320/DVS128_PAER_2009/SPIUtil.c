/*
These functions makes calls to spiwritebyte and spiread to transfer
data to or from the on-chip bias generator.
This is a C function that initializes SPI port pins. The actual SPI routine is assembly.

Configuration for biasgen/ipot signal, port bit number, and Cypress FX2 pin numbers
Signal			port		pin128		pin56
biasClock		PA0			82			40
biasBit			PA1			83			41
biasLatch		PA2			84			42
powerDown		PA3			85			43

clock and bit polarities as follows
powerDown: 	low for normal operation, high to power off the masterbias
latch:  	high to make latch opaque to load new values into shift register, low to make latch transparent to apply new bias values. should be idle low to pass shift register outputs.
biasBit:	high to enable a bit of the current splitter (more current)
biasClock:	low to toggle biasBit, high to latch the value. should be idle high to powerup the second stage of the master/slave sivilloti shift register.

shift register values are loaded from msb to lsb, the same as the output from a normal SPI interface, which outputs 
from msb down to lsb. biases are 3 bytes (24 bits) on tmpdiff128 and testchipARCs.


--------------------------------------

The write routine takes a byte that was passed to it and shifts
it out MSB first. Data is changed when the CLK is HIGH, the
device latches the data on the falling edge of CLK. The routine
uses Port A pinsA 0-3, but you can change these to be any
pins by changing the bitmasks. This routine clocks data at a
250-kHz bit rate, or about 35-kHz byte rate.

*/
#include "fx2.h"
#include "fx2regs.h"

/////////////////////////////////////// Prototypes
void spiwritebyte (BYTE d);//Assembly routine
BYTE spireadbyte (void);//Assembly routine
void spiInit(void); // initializes port for SPI
void setLatchTransparent(); // latches the new biasgen ipot shift register values
void setLatchOpaque();	// set latch opaque to load new ipot shift register bits
//void setPoweredOff();		// set powerDown high
//void setPoweredOn();		// set powerDown low
void setPowerDownBit(BYTE); // set powerDown bit to lsb of argument

sbit powerDown=IOA^3;
sbit biasLatch=IOA^2;
sbit biasBit=IOA^1;
sbit biasClock=IOA^0;

// powerdown bit is bit 3
void setPowerDownBit(BYTE b){
	powerDown=b&1;
	//if(b&1) IOA|=8; else IOA&=0xf7;
}

void spiInit(){
	PORTACFG &= 0xF0; //Turn off special functions for lowest nibble of port A
	OEA |= 0x0F;  // all 4 bits are outputs
	biasClock=1;
	biasBit=0;
	biasLatch=0; // latch transparent
	powerDown=0; // not powered down
}
