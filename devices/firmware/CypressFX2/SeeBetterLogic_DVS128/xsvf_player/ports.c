/*******************************************************/
/* file: ports.c                                       */
/* abstract:  This file contains the routines to       */
/*            output values on the JTAG ports, to read */
/*            the TDO bit, and to read a byte of data  */
/*            from the prom                            */
/* Revisions:                                          */
/* 12/01/2008:  Same code as before (original v5.01).  */
/*              Updated comments to clarify instructions.*/
/*              Add print in setPort for xapp058_example.exe.*/
/*******************************************************/
#include "ports.h"
#include "portsFX2.h"

/* setPort:  Implement to set the named JTAG signal (p) to the new value (v).*/
/* if in debugging mode, then just set the variables */
void setPort(unsigned char p, short val)
{
	if (val == 0) {
		IOC &= ~p;
	}
	else {
		IOC |= p;
	}
}


/* toggle tck LH.  No need to modify this code.  It is output via setPort. */
void pulseClock()
{
    setPort(TCK, 0);  /* set the TCK port to low  */
    setPort(TCK, 1);  /* set the TCK port to high */
}

static int dataReadIndex;
static unsigned char *dataArray;

/* readByte:  Implement to source the next byte from your XSVF file location */
/* read in a byte of data from the prom */
void readByte(unsigned char *ucdata)
{
	*ucdata = dataArray[dataReadIndex++];
}

void resetDataArray(unsigned char *newDataArray)
{
	dataReadIndex = 0;
	dataArray = newDataArray;
}

/* readTDOBit:  Implement to return the current value of the JTAG TDO signal.*/
/* read the TDO bit from port */
unsigned char readTDOBit()
{
	return ((IOC & TDO) >> TDOshift);
}

/* waitTime:  Implement as follows: */
/* REQUIRED:  This function must consume/wait at least the specified number  */
/*            of microsec, interpreting microsec as a number of microseconds.*/
/* REQUIRED FOR SPARTAN/VIRTEX FPGAs and indirect flash programming:         */
/*            This function must pulse TCK for at least microsec times,      */
/*            interpreting microsec as an integer value.                     */
/* RECOMMENDED IMPLEMENTATION:  Pulse TCK at least microsec times AND        */
/*                              continue pulsing TCK until the microsec wait */
/*                              requirement is also satisfied.               */
void waitTime(long microsec)
{
	long i;

    /* This implementation follows the Xilinx guidelines above and implements
	   the REQUIRED and the RECOMMENDED portion, at least for values below
	   1 million (1 second). Above that, we only respect the REQUIRED portion,
	   because the slow-down would be unacceptable. FX2 takes about 10 actual
	   microsecodns to execute the pulseClock() function! */

	if (microsec > 1000000) {
		microsec /= 10;
	}

    for (i = 0; i < microsec; ++i)
    {
        pulseClock();
    }
}
