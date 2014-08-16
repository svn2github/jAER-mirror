/**************************************************************
*
* Lattice Semiconductor Corp. Copyright 2008
* 
*
***************************************************************/


/**************************************************************
* 
* Revision History of hardware.c
* 
* 
* 09/11/07 NN type cast all the mismatch variables
***************************************************************/


#include "opcode.h"

/*************************************************************
*                                                            *
* EXTERNAL VARIABLE                                          *
*                                                            *
*************************************************************/

extern short int g_siIspPins;

/*************************************************************
*                                                            *
* EXTERNAL FUNCTION                                          *
*                                                            *
*************************************************************/

extern void ispVMStateMachine( char a_cNextState );

/*************************************************************
*                                                            *
* READPORT                                                   *
*                                                            *
* INPUT:                                                     *
*     None.                                                  *
*                                                            *
* RETURN:                                                    *
*     Returns the bit read back from the device.             *
*                                                            *
* DESCRIPTION:                                               *
*     This function is used to read the TDO pin from the     *
*     input port.                                            *
*                                                            *
*     NOTE: This function should be modified in an embedded  *
*     system!                                                *
*                                                            *
*************************************************************/

unsigned char readPort()
{
	unsigned char ucRet = 0;
	/* This is a sample code for Windows/DOS
	if ( _inp( 0x379 ) & g_ucPinTDO ) {
		ucRet = 0x01;
    }
	else {
       ucRet = 0x00;
    }
	*/
	return ( ucRet );
} 

/*************************************************************
*                                                            *
* WRITEPORT                                                  *
*                                                            *
* INPUT:                                                     *
*     a_ucPins: a byte to indicate which pin will be         *
*     depending on the value.                                *
*                                                            *
*     a_ucValue: the value to determine of the pin above     *
*     will be written out or not.                            *
*                                                            *
* RETURN:                                                    *
*     None.                                                  *
*                                                            *
* DESCRIPTION:                                               *
*     To apply the specified value to the pins indicated.    *
*     This routine will likely be modified for specific      *
*     systems. As an example, this code is for the PC, as    *
*     described below.                                       *
*                                                            *
*     This routine uses the IBM-PC standard Parallel port,   *
*     along with the schematic shown in Lattice              *
*     documentation, to apply the signals to the programming *
*     loop.                                                  *
*                                                            *
*     NOTE: This function should be modified in an embedded  *
*     system!                                                *
*                                                            *
*************************************************************/

void writePort( unsigned char a_ucPins, unsigned char a_ucValue )
{
	if ( a_ucValue ) {
		g_siIspPins = (short int) ((short int)a_ucPins | g_siIspPins);
	}
	else {
		g_siIspPins = (short int) ((short int)~a_ucPins & g_siIspPins);
	}
	/* This is a sample code for Windows/DOS without Windows Driver.
	_outp( 0x378, g_siIspPins );
	*/
}

/*************************************************************
*                                                            *
* ISPVMDELAY                                                 *
*                                                            *
* INPUT:                                                     *
*     a_uiDelay: delay in milliseconds                       *
*                                                            *
* RETURN:                                                    *
*     None.                                                  *
*                                                            *
* DESCRIPTION:                                               *
* The user must implement a delay to observe a_uiDelay,	     *
* where a_uiDelay is the number of milliseconds that must    *
* pass before data is read from in_port.  Since platforms and*
* processor speeds vary greatly, this task is left to the    *
* user. This subroutine is called upon to provide a delay    *
* from 1 millisecond to a few hundreds milliseconds each time*
* That is the reason behind using unsigned long integer in   *
* this subroutine. It is OK to provide longer delay than     *
* required. It is not acceptable if the delay is shorter than*
* required.                                                  *
*                                                            *
* Note: user must re - implement to target specific hardware.*
*                                                            *
* Example: Use the for loop to create the microsecond delay. *
*          Loop 1K times to produce the milliseconds delay.  *
*                                                            *
*          Let the CPU clock (system clock) be F Mhz.        *
*                                                            *
*          Let the for loop represented by the 2 lines of    *
*          machine code:                                     *
*                    LOOP:  DEC RA;                          *
*                           JNZ LOOP;                        *
*          Let the for loop number for one microsecond be L. *
*          Lets assume 4 system clocks for each line of      *
*          machine code.                                     *
*          Then 1 us = 1/F (microseconds per clock)          *
*                       x (2 lines) x (4 clocks per line) x L*
*                     = 8L/F                                 *
*          Or L = F/8;                                       *
*                                                            *
*          Convert the unit in microseconds to               *
*          milliseconds.                                     *
*          L = F/8 x 1000;                                   *
*          Lets assume the CPU clock is set to 48MHZ. The C  *
*          code then is:                                     *
*                                                            *
*          unsigned int F = 48;   //MHZ.                     * 
*          unsigned int L = F/8;  //microseconds.            *          
*          unsigned int index, m;                            *
*                                                            *
*                                                            *
*          if (L < 1) L = 1;   //minimum is i microsecond.   *              
*          for (index=0; index < a_uiDelay * L; index++)     *
*              {                                             *
*   //loop 1K times to produce milliseconds delay            *
*                for (m=0; m<1000; m++); //milliseconds      *
*              }                                             *
*          return 0;                                         *
*                                                            *
*                                                            *
*************************************************************/

/* the unit of a_uiDelay is milliseconds */
void ispVMDelay( unsigned int a_uiDelay )
{	
}

/*************************************************************
*                                                            *
* ENABLEHARDWARE                                             *
*                                                            *
* INPUT:                                                     *
*     None.                                                  *
*                                                            *
* RETURN:                                                    *
*     None.                                                  *
*                                                            *
* DESCRIPTION:                                               *
*     This function is called to enable the hardware.        *
*                                                            *
*     NOTE: This function should be modified in an embedded  *
*     system!                                                *
*                                                            *
*************************************************************/

void EnableHardware()
{
	ispVMStateMachine(RESET);
}

/*************************************************************
*                                                            *
* DISABLEHARDWARE                                            *
*                                                            *
* INPUT:                                                     *
*     None.                                                  *
*                                                            *
* RETURN:                                                    *
*     None.                                                  *
*                                                            *
* DESCRIPTION:                                               *
*     This function is called to disable the hardware.       *
*                                                            *
*     NOTE: This function should be modified in an embedded  *
*     system!                                                *
*                                                            *
*************************************************************/

void DisableHardware()
{
	ispVMStateMachine(RESET);
}


