/*******************************************************/
/* file: lenval.c                                      */
/* abstract:  This file contains routines for using    */
/*            the lenVal data structure.               */
/*******************************************************/
#include "lenval.h"
#include "ports.h"

/*****************************************************************************
* Function:     value
* Description:  Extract the long value from the lenval array.
* Parameters:   plvValue    - ptr to lenval.
* Returns:      long        - the extracted value.
*****************************************************************************/
long value( lenVal*     plvValue )
{
	long    lValue;         /* result to hold the accumulated result */
	short   sIndex;

    lValue  = 0;
	for ( sIndex = 0; sIndex < plvValue->len ; ++sIndex )
	{
		lValue <<= 8;                       /* shift the accumulated result */
		lValue |= plvValue->val[ sIndex];   /* get the last byte first */
	}

	return( lValue );
}

/*****************************************************************************
* Function:     EqualLenVal
* Description:  Compare two lenval arrays with an optional mask.
* Parameters:   plvTdoExpected  - ptr to lenval #1.
*               plvTdoCaptured  - ptr to lenval #2.
*               plvTdoMask      - optional ptr to mask (=0 if no mask).
* Returns:      short   - 0 = mismatch; 1 = equal.
*****************************************************************************/
short EqualLenVal( lenVal*  plvTdoExpected,
                   lenVal*  plvTdoCaptured,
                   lenVal*  plvTdoMask )
{
    short           sEqual;
	short           sIndex;
    unsigned char   ucByteVal1;
    unsigned char   ucByteVal2;
    unsigned char   ucByteMask;

    sEqual  = 1;
    sIndex  = plvTdoExpected->len;

    while ( sEqual && sIndex-- )
    {
        ucByteVal1  = plvTdoExpected->val[ sIndex ];
        ucByteVal2  = plvTdoCaptured->val[ sIndex ];
        if ( plvTdoMask )
        {
            ucByteMask  = plvTdoMask->val[ sIndex ];
            ucByteVal1  &= ucByteMask;
            ucByteVal2  &= ucByteMask;
        }
        if ( ucByteVal1 != ucByteVal2 )
        {
            sEqual  = 0;
        }
    }

	return( sEqual );
}

/*****************************************************************************
* Function:     readVal
* Description:  read from XSVF numBytes bytes of data into x.
* Parameters:   plv         - ptr to lenval in which to put the bytes read.
*               sNumBytes   - the number of bytes to read.
* Returns:      void.
*****************************************************************************/
void readVal( lenVal*   plv,
              short     sNumBytes )
{
    unsigned char*  pucVal;

    plv->len    = sNumBytes;        /* set the length of the lenVal        */
    for ( pucVal = plv->val; sNumBytes; --sNumBytes, ++pucVal )
    {
        /* read a byte of data into the lenVal */
		readByte( pucVal );
    }
}
