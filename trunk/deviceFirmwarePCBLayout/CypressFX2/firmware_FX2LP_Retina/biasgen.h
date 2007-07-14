// header for biasgen, defines bits and macros for controlling biasgen
// the function spiwritebyte is in the assembly file spiwritebyte.a51

void spiwritebyte (BYTE d);//Assembly routine
BYTE spireadbyte (void);//Assembly routine
void biasInit(void); // initializes port for SPI
//void setLatchTransparent(); // latches the new biasgen ipot shift register values
//void setLatchOpaque();	// set latch opaque to load new ipot shift register bits
void latchNewBiases();	// set latch transparent and then opaque again
void setPowerDownBit(BYTE); // set powerDown bit to lsb of argument

sbit biasClock=IOA^2;
sbit biasBit=IOA^3;
sbit biasLatch=IOA^4;
sbit powerDown=IOA^5; // altogether using 00xx xx00=0x3c

#define latchNewBiases() biasLatch=0; _nop_();  _nop_();  _nop_(); biasLatch=1;
#define setPowerDownBit(b) powerDown=b&1;
#define biasInit(); biasClock=1; biasBit=0; biasLatch=1; powerDown=0;

