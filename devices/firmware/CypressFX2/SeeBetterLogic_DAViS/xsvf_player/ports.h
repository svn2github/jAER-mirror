/*******************************************************/
/* file: ports.h                                       */
/* abstract:  This file contains extern declarations   */
/*            for providing stimulus to the JTAG ports.*/
/*******************************************************/

#ifndef ports_dot_h
#define ports_dot_h

#define TCK 0x01
#define TMS 0x02
#define TDI 0x04
#define TDO 0x08

/* set the port "p" (TCK, TMS, or TDI) to val (0 or 1) */
extern void setPort(unsigned char p, unsigned char val);

/* read the TDO bit and store it in val */
extern unsigned char readTDOBit();

/* read the next byte of data from the xsvf file */
extern void readByte(unsigned char *ucdata);

extern void waitTime(long microsec);

extern void resetDataArray(unsigned char *newDataArray);

#endif
