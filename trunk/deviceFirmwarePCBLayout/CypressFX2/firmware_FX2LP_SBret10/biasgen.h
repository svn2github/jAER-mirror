// header for biasgen, defines bits and macros for controlling biasgen
// the function spiwritebyte is in the assembly file spiwritebyte.a51

void spiwritebyte (BYTE d);//Assembly routine
BYTE spireadbyte (void);//Assembly routine
//void biasInit(void); // initializes port for SPI
//void setLatchTransparent(); // latches the new biasgen ipot shift register values
//void setLatchOpaque();	// set latch opaque to load new ipot shift register bits
//void latchNewBiases();	// set latch transparent and then opaque again
//void setPowerDownBit(BYTE); // set powerDown bit to lsb of argument

//sbit biasClock=IOE^4;
//sbit biasBit=IOE^3;
//sbit biasLatch=IOE^1;
//sbit powerDown=IOE^2; // altogether using 00xx xx00=0x3c
#define biasClock 	0x20
#define biasBit 	0x10
#define biasLatch 	0x02
#define powerDown 	0x04

#define latchNewBiases() IOE&=~biasLatch; _nop_();  _nop_();  _nop_(); _nop_();  _nop_();  _nop_(); _nop_();  _nop_();  _nop_(); IOE|=biasLatch;
#define setPowerDownBit() IOE|=powerDown;
#define releasePowerDownBit() IOE&=~powerDown;
#define biasInit(); IOE|=biasClock; IOE&=~biasBit; IOE|=biasLatch; 

