/*******************************************************/
/* file: ports.h                                       */
/* abstract:  This file contains extern declarations   */
/*            for providing stimulus to the JTAG ports.*/
/*******************************************************/

#ifndef ports_dot_h
#define ports_dot_h

/* these constants are used to send the appropriate ports to setPort */
/* they should be enumerated types, but some of the microcontroller  */
/* compilers don't like enumerated types */
#define TCK 0x20
#define TMS 0x10
#define TDI 0x80
#define TDO 0x40

#define TCKshift 5
#define TMSshift 4
#define TDIshift 7
#define TDOshift 6

/* set the port "p" (TCK, TMS, or TDI) to val (0 or 1) */
extern void setPort(unsigned char p, short val);

/* read the TDO bit and store it in val */
extern unsigned char readTDOBit();

/* make clock go down->up->down*/
extern void pulseClock();

/* read the next byte of data from the xsvf file */
extern void readByte(unsigned char *ucdata);

extern void waitTime(int microsec);

extern void resetDataArray(unsigned char *newDataArray);

#endif
