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
	long cyclesToDO = microsec / 10;
	long i;

    /* This implementation follows the Xilinx guidelines above and implements
	   the REQUIRED portion. It does not toggle TCK microsec times though, since
	   that would slow down things too much, given that on the FX2, measured with
	   a scope, the number of cycles has to be about a tenth of the input microsec
	   value for it to correspond in time. */
    for (i = 0; i < cyclesToDO; ++i)
    {
        pulseClock();
    }
}
