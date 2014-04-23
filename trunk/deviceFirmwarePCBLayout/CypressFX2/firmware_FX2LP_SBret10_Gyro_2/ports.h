/*******************************************************/
/* file: ports.h                                       */
/* abstract:  This file contains extern declarations   */
/*            for providing stimulus to the JTAG ports.*/
/*******************************************************/

#ifndef ports_dot_h
#define ports_dot_h

//#include "lpregs.h"
//#include "portsfx2.h"
#define TCK (unsigned char) 0x20 // 1110_1111
#define pTDO  0x40 // 
#define TDI (unsigned char) 0x80 // 1011_1111
#define TMS (unsigned char) 0x10 // 0111_1111

#define TCKshift 5
#define TDOshift 6
#define TDIshift 7
#define TMSshift 4

/* set the port "p" (TCK, TMS, or TDI) to val (0 or 1) */
//extern void setPort(unsigned char p, short val);

//extern void resetReadCounter( unsigned char *dataArray);

/* read the TDO bit and store it in val */
//extern unsigned char readTDOBit();

/* make clock go down->up */
//extern void pulseClock();

/* read the next byte of data from the xsvf file */
//extern void readByte(unsigned char *ucdata);

//extern void waitTime(int microsec);

#endif
