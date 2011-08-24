// header for biasgen, defines bits and macros for controlling biasgen
// the function spiwritebyte is in the assembly file spiwritebyte.a51

void spiwritebyte (BYTE d);//Assembly routine
BYTE spireadbyte (void);//Assembly routine

// bias controls on coch ams1c are on port E which is not bit-addressable

// altogether using 00xx xx00=0x3c
#define biasClockMask 	0x20 // PE5
#define biasBitMask 	0x10 // PE4
#define biasLatchMask 	0x02 // PE1
#define powerDownMask 	0x04 // PE2

#define latchNewBiases() IOE&=~biasLatchMask; _nop_();  _nop_();  _nop_(); _nop_();  _nop_();  _nop_(); _nop_();  _nop_();  _nop_(); IOE|=biasLatchMask;
#define setPowerDownBit() IOE|=powerDownMask;
#define releasePowerDownBit() IOE&=~powerDownMask;
#define biasInit() IOE|=biasClockMask; IOE&=~biasBitMask; IOE|=biasLatchMask; IOE&=~powerDownMask;

