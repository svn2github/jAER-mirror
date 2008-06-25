/*******************************************************/
/* file: ports.c                                       */
/* abstract:  This file contains the routines to       */
/*            output values on the JTAG ports, to read */
/*            the TDO bit, and to read a byte of data  */
/*            from the prom                            */
/*                                                     */
/*******************************************************/
#include "ports.h"
/*#include "prgispx.h"*/

//#include "stdio.h"

sfr IOC  = 0xA0;

/*sbit PC4=IOC^4;
sbit PC5=IOC^5;
sbit PC6=IOC^6;
sbit PC7=IOC^7; 	*/

/* these constants are used to send the appropriate ports to setPort */
/* they should be enumerated types, but some of the microcontroller  */
/* compilers don't like enumerated types */
/*#define TCK  PC5
#define pTDO PC6 
#define TDI  PC7
#define TMS  PC4*/


void setPort(unsigned char p , short val)
{
	 
	if (val==0)
	{
		IOC= IOC & ~p;
	} else 
	{
		IOC= IOC | p;
	}

}


/* toggle tck LH */
void pulseClock()
{
    setPort(TCK,0);  /* set the TCK port to low  */
    setPort(TCK,1);  /* set the TCK port to high */
}

int readIndex=0;
unsigned char *shiftData;

/* read in a byte of data from the prom */
void readByte(unsigned char *ucdata)
{
	*ucdata=shiftData[readIndex++];
}

void resetReadCounter( unsigned char *dataArray)
{
	readIndex=0;
	shiftData=dataArray;
}

/* read the TDO bit from port */
unsigned char readTDOBit()
{
	return  (IOC & pTDO) >> TDOshift; 
}


/* Wait at least the specified number of microsec.                           */
/* Use a timer if possible; otherwise estimate the number of instructions    */
/* necessary to be run based on the microcontroller speed.  For this example */
/* we pulse the TCK port a number of times based on the processor speed.     */
void waitTime(int time)
{											    
    int        i;
	
    for ( i = 0; i < time; ++i )
    {
        pulseClock();
    }
}
