/*****************************************************************************
* file:         micro.c
* abstract:     This file contains the function, xsvfExecute(),
*               call for interpreting the XSVF commands.
* Usage:        Call xsvfExecute() to process XSVF data.
*               The XSVF data is retrieved by readByte() in ports.c
*               Remove the main function if you already have one.
* Options:      XSVF_SUPPORT_COMPRESSION
*                   This define supports the XC9500/XL compression scheme.
*                   This define adds support for XSDRINC and XSETSDRMASKS.
*               XSVF_SUPPORT_ERRORCODES
*                   This define causes the xsvfExecute function to return
*                   an error code for specific errors.  See error codes below.
*                   If this is not defined, the return value defaults to the
*                   legacy values for backward compatibility:
*                   1 = success;  0 = failure.
* Debugging:    DEBUG_MODE (Legacy name)
*               Define DEBUG_MODE to compile with debugging features.
*               Both micro.c and ports.c must be compiled with the DEBUG_MODE
*               defined to enable the standalone main implementation in
*               micro.c that reads XSVF from a file.
* History:      v2.00   - Original XSVF implementation.
*               v4.04   - Added delay at end of XSIR for XC18v00 support.
*                         Added new commands for CoolRunner support:
*                         XSTATE, XENDIR, XENDDR
*               v4.05   - Cleanup micro.c but leave ports.c intact.
*               v4.06   - Fix xsvfGotoTapState for retry transition.
*               v4.07   - Update example waitTime implementations for
*                         compatibility with Virtex-II.
*               v4.10   - Add new XSIR2 command that supports a 2-byte
*                         IR-length parameter for IR shifts > 255 bits.
*               v4.11   - No change.  Update version to match SVF2XSVF xlator.
*               v4.14   - Added XCOMMENT.
*               v5.00   - Improve XSTATE support.
*                         Added XWAIT.
*               v5.01   - make sure that TCK is low during RUNTEST wait for
*                         XC18V00/XCF00 support.  Only change is in PORTS.C
*                         waitTime() function for implementations that do NOT
*                         pulse TCK during the waitTime.
*****************************************************************************/

/*============================================================================
* #pragmas
============================================================================*/
#ifdef  _MSC_VER
    #pragma warning( disable : 4100 )
#endif  /* _MSC_VER */

/*============================================================================
* #include files
============================================================================*/
#ifdef  DEBUG_MODE
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <time.h>
#endif  /* DEBUG_MODE */

#include "micro.h"
#include "lenval.h"
#include "ports.h"


/*============================================================================
* XSVF #define
============================================================================*/

#define XSVF_VERSION    "5.01"


/*****************************************************************************
* Define:       XSVF_SUPPORT_ERRORCODES
* Description:  Define this to support the new XSVF error codes.
*               (The original XSVF player just returned 1 for success and
*               0 for an unspecified failure.)
*****************************************************************************/
#ifndef XSVF_SUPPORT_ERRORCODES
    #define XSVF_SUPPORT_ERRORCODES     1
#endif

#ifdef  XSVF_SUPPORT_ERRORCODES
    #define XSVF_ERRORCODE(errorCode)   errorCode
#else   /* Use legacy error code */
    #define XSVF_ERRORCODE(errorCode)   ((errorCode==XSVF_ERROR_NONE)?1:0)
#endif  /* XSVF_SUPPORT_ERRORCODES */

/*============================================================================
* XSVF Type Declarations
============================================================================*/

/*****************************************************************************
* Struct:       SXsvfInfo
* Description:  This structure contains all of the data used during the
*               execution of the XSVF.  Some data is persistent, predefined
*               information (e.g. lRunTestTime).  The bulk of this struct's
*               size is due to the lenVal structs (defined in lenval.h)
*               which contain buffers for the active shift data.  The MAX_LEN
*               #define in lenval.h defines the size of these buffers.
*               These buffers must be large enough to store the longest
*               shift data in your XSVF file.  For example:
*                   MAX_LEN >= ( longest_shift_data_in_bits / 8 )
*               Because the lenVal struct dominates the space usage of this
*               struct, the rough size of this struct is:
*                   sizeof( SXsvfInfo ) ~= MAX_LEN * 7 (number of lenVals)
*               xsvfInitialize() contains initialization code for the data
*               in this struct.
*               xsvfCleanup() contains cleanup code for the data in this
*               struct.
*****************************************************************************/
typedef struct tagSXsvfInfo
{
    /* XSVF status information */									       
    int             iErrorCode;         /* An error code. 0 = no error. */

    /* TAP state/sequencing information */
    unsigned char   ucTapState;         /* Current TAP state */
    unsigned char   ucEndIR;            /* ENDIR TAP state (See SVF) */
    unsigned char   ucEndDR;            /* ENDDR TAP state (See SVF) */		       

    lenVal          lvTdi;              /* Current TDI shift data */
    lenVal          lvTdoExpected;      /* Expected TDO shift data */
    lenVal          lvTdoCaptured;      /* Captured TDO shift data */
    lenVal          lvTdoMask;          /* TDO mask: 0=dontcare; 1=compare */
} SXsvfInfo;

SXsvfInfo xdata svfInfo;

/*============================================================================
* XSVF Command Parameter Values
============================================================================*/

#define XSTATE_RESET     0          /* 4.00 parameter for XSTATE */
#define XSTATE_RUNTEST   1          /* 4.00 parameter for XSTATE */

#define XENDXR_RUNTEST   0          /* 4.04 parameter for XENDIR/DR */
#define XENDXR_PAUSE     1          /* 4.04 parameter for XENDIR/DR */

/* TAP states */
#define XTAPSTATE_RESET     0x00
#define XTAPSTATE_RUNTEST   0x01    /* a.k.a. IDLE */
#define XTAPSTATE_SELECTDR  0x02
#define XTAPSTATE_CAPTUREDR 0x03
#define XTAPSTATE_SHIFTDR   0x04
#define XTAPSTATE_EXIT1DR   0x05
#define XTAPSTATE_PAUSEDR   0x06
#define XTAPSTATE_EXIT2DR   0x07
#define XTAPSTATE_UPDATEDR  0x08
#define XTAPSTATE_IRSTATES  0x09    /* All IR states begin here */
#define XTAPSTATE_SELECTIR  0x09
#define XTAPSTATE_CAPTUREIR 0x0A
#define XTAPSTATE_SHIFTIR   0x0B
#define XTAPSTATE_EXIT1IR   0x0C
#define XTAPSTATE_PAUSEIR   0x0D
#define XTAPSTATE_EXIT2IR   0x0E
#define XTAPSTATE_UPDATEIR  0x0F



/*============================================================================
* Utility Functions
============================================================================*/

/*****************************************************************************
* Function:     xsvfPrintLenVal
* Description:  Print the lenval value in hex.
* Parameters:   plv     - ptr to lenval.
* Returns:      void.
*****************************************************************************/


/*****************************************************************************
* Function:     xsvfInfoInit
* Description:  Initialize the xsvfInfo data.
* Parameters:   pXsvfInfo   - ptr to the XSVF info structure.
* Returns:      int         - 0 = success; otherwise error.
*****************************************************************************/
int xsvfInfoInit(  )
{										  						
    svfInfo.iErrorCode       = XSVF_ERROR_NONE;	     
    svfInfo.ucTapState       = XTAPSTATE_RESET;
    svfInfo.ucEndIR          = XTAPSTATE_RUNTEST;
    svfInfo.ucEndDR          = XTAPSTATE_RUNTEST;	

    return( 0 );
}


/*****************************************************************************
* Function:     xsvfGetAsNumBytes
* Description:  Calculate the number of bytes the given number of bits
*               consumes.
* Parameters:   lNumBits    - the number of bits.
* Returns:      short       - the number of bytes to store the number of bits.
*****************************************************************************/
short xsvfGetAsNumBytes( long lNumBits )
{
    return( (short)( ( lNumBits + 7L ) / 8L ) );
}

/*****************************************************************************
* Function:     xsvfTmsTransition
* Description:  Apply TMS and transition TAP controller by applying one TCK
*               cycle.
* Parameters:   sTms    - new TMS value.
* Returns:      void.
*****************************************************************************/
void xsvfTmsTransition( short sTms )
{
    setPort( TMS, sTms );
    setPort( TCK, 0 );
    setPort( TCK, 1 );
}

/*****************************************************************************
* Function:     xsvfGotoTapState
* Description:  From the current TAP state, go to the named TAP state.
*               A target state of RESET ALWAYS causes TMS reset sequence.
*               All SVF standard stable state paths are supported.
*               All state transitions are supported except for the following
*               which cause an XSVF_ERROR_ILLEGALSTATE:
*                   - Target==DREXIT2;  Start!=DRPAUSE
*                   - Target==IREXIT2;  Start!=IRPAUSE
* Parameters:   pucTapState     - Current TAP state; returns final TAP state.
*               ucTargetState   - New target TAP state.
* Returns:      int             - 0 = success; otherwise error.
*****************************************************************************/
int xsvfGotoTapState( unsigned char*   pucTapState,
                      unsigned char    ucTargetState )
{
    int i;
    int iErrorCode;

    iErrorCode  = XSVF_ERROR_NONE;
    if ( ucTargetState == XTAPSTATE_RESET )
    {
        /* If RESET, always perform TMS reset sequence to reset/sync TAPs */
        xsvfTmsTransition( 1 );
        for ( i = 0; i < 5; ++i )
        {
            setPort( TCK, 0 );
            setPort( TCK, 1 );
        }
        *pucTapState    = XTAPSTATE_RESET;				    
    }
    else if ( ( ucTargetState != *pucTapState ) &&		    
              ( ( ( ucTargetState == XTAPSTATE_EXIT2DR ) && ( *pucTapState != XTAPSTATE_PAUSEDR ) ) ||
                ( ( ucTargetState == XTAPSTATE_EXIT2IR ) && ( *pucTapState != XTAPSTATE_PAUSEIR ) ) ) )
    {
        /* Trap illegal TAP state path specification */
        iErrorCode      = XSVF_ERROR_ILLEGALSTATE;
    }
    else
    {
        if ( ucTargetState == *pucTapState )
        {
            /* Already in target state.  Do nothing except when in DRPAUSE
               or in IRPAUSE to comply with SVF standard */
            if ( ucTargetState == XTAPSTATE_PAUSEDR )
            {
                xsvfTmsTransition( 1 );
                *pucTapState    = XTAPSTATE_EXIT2DR;				
            }
            else if ( ucTargetState == XTAPSTATE_PAUSEIR )
            {													     
                xsvfTmsTransition( 1 );
                *pucTapState    = XTAPSTATE_EXIT2IR;				
            }
        }

        /* Perform TAP state transitions to get to the target state                 XSVFDBG_PRINTF1( 3, "   TAP State = %s\n",
                                 xsvf_pzTapState[ *pucTapState ] );*/
        while ( ucTargetState != *pucTapState )
        {
            switch ( *pucTapState )
            {
            case XTAPSTATE_RESET:
                xsvfTmsTransition( 0 );
                *pucTapState    = XTAPSTATE_RUNTEST;
                break;
            case XTAPSTATE_RUNTEST:
                xsvfTmsTransition( 1 );
                *pucTapState    = XTAPSTATE_SELECTDR;
                break;
            case XTAPSTATE_SELECTDR:
                if ( ucTargetState >= XTAPSTATE_IRSTATES )
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_SELECTIR;
                }
                else
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_CAPTUREDR;
                }
                break;
            case XTAPSTATE_CAPTUREDR:
                if ( ucTargetState == XTAPSTATE_SHIFTDR )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_SHIFTDR;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_EXIT1DR;
                }
                break;
            case XTAPSTATE_SHIFTDR:
                xsvfTmsTransition( 1 );
                *pucTapState    = XTAPSTATE_EXIT1DR;
                break;
            case XTAPSTATE_EXIT1DR:
                if ( ucTargetState == XTAPSTATE_PAUSEDR )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_PAUSEDR;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_UPDATEDR;
                }
                break;
            case XTAPSTATE_PAUSEDR:
                xsvfTmsTransition( 1 );
                *pucTapState    = XTAPSTATE_EXIT2DR;
                break;
            case XTAPSTATE_EXIT2DR:
                if ( ucTargetState == XTAPSTATE_SHIFTDR )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_SHIFTDR;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_UPDATEDR;
                }
                break;
            case XTAPSTATE_UPDATEDR:
                if ( ucTargetState == XTAPSTATE_RUNTEST )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_RUNTEST;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_SELECTDR;
                }
                break;
            case XTAPSTATE_SELECTIR:
                xsvfTmsTransition( 0 );
                *pucTapState    = XTAPSTATE_CAPTUREIR;
                break;
            case XTAPSTATE_CAPTUREIR:
                if ( ucTargetState == XTAPSTATE_SHIFTIR )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_SHIFTIR;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_EXIT1IR;
                }
                break;
            case XTAPSTATE_SHIFTIR:
                xsvfTmsTransition( 1 );
                *pucTapState    = XTAPSTATE_EXIT1IR;
                break;
            case XTAPSTATE_EXIT1IR:
                if ( ucTargetState == XTAPSTATE_PAUSEIR )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_PAUSEIR;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_UPDATEIR;
                }
                break;
            case XTAPSTATE_PAUSEIR:
                xsvfTmsTransition( 1 );
                *pucTapState    = XTAPSTATE_EXIT2IR;
                break;
            case XTAPSTATE_EXIT2IR:
                if ( ucTargetState == XTAPSTATE_SHIFTIR )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_SHIFTIR;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_UPDATEIR;
                }
                break;
            case XTAPSTATE_UPDATEIR:
                if ( ucTargetState == XTAPSTATE_RUNTEST )
                {
                    xsvfTmsTransition( 0 );
                    *pucTapState    = XTAPSTATE_RUNTEST;
                }
                else
                {
                    xsvfTmsTransition( 1 );
                    *pucTapState    = XTAPSTATE_SELECTDR;
                }
                break;
            default:
                iErrorCode      = XSVF_ERROR_ILLEGALSTATE;
                *pucTapState    = ucTargetState;    /* Exit while loop */
                break;
            }
        }
    }

    return( iErrorCode );
}																 

/*****************************************************************************
* Function:     xsvfShiftOnly
* Description:  Assumes that starting TAP state is SHIFT-DR or SHIFT-IR.
*               Shift the given TDI data into the JTAG scan chain.
*               Optionally, save the TDO data shifted out of the scan chain.
*               Last shift cycle is special:  capture last TDO, set last TDI,
*               but does not pulse TCK.  Caller must pulse TCK and optionally
*               set TMS=1 to exit shift state.
* Parameters:   lNumBits        - number of bits to shift.
*               plvTdi          - ptr to lenval for TDI data.
*               plvTdoCaptured  - ptr to lenval for storing captured TDO data.
*               iExitShift      - 1=exit at end of shift; 0=stay in Shift-DR.
* Returns:      void.
*****************************************************************************/
void xsvfShiftOnly( long    lNumBits,
                    lenVal* plvTdi,
                    lenVal* plvTdoCaptured,
                    int     iExitShift )
{
    unsigned char*  pucTdi;
    unsigned char*  pucTdo;
    unsigned char   ucTdiByte;
    unsigned char   ucTdoByte;
    unsigned char   ucTdoBit;
    int             i;

    /* assert( ( ( lNumBits + 7 ) / 8 ) == plvTdi->len ); */

    /* Initialize TDO storage len == TDI len */
    pucTdo  = 0;
    if ( plvTdoCaptured )
    {
        plvTdoCaptured->len = plvTdi->len;
        pucTdo              = plvTdoCaptured->val + plvTdi->len;
    }

    /* Shift LSB first.  val[N-1] == LSB.  val[0] == MSB. */
    pucTdi  = plvTdi->val + plvTdi->len;
    while ( lNumBits )
    {
        /* Process on a byte-basis */
        ucTdiByte   = (*(--pucTdi));
        ucTdoByte   = 0;
        for ( i = 0; ( lNumBits && ( i < 8 ) ); ++i )
        {
            --lNumBits;
            if ( iExitShift && !lNumBits )
            {
                /* Exit Shift-DR state */
                setPort( TMS, 1 );
            }

            /* Set the new TDI value */
            setPort( TDI, (short)(ucTdiByte & 1) );
            ucTdiByte   >>= 1;

            /* Set TCK low */
            setPort( TCK, 0 );

            if ( pucTdo )
            {
                /* Save the TDO value */
                ucTdoBit    = readTDOBit();
                ucTdoByte   |= ( ucTdoBit << i );
            }

            /* Set TCK high */
            setPort( TCK, 1 );
        }

        /* Save the TDO byte value */
        if ( pucTdo )
        {
            (*(--pucTdo))   = ucTdoByte;
        }
    }
}

/*****************************************************************************
* Function:     xsvfShift
* Description:  Goes to the given starting TAP state.
*               Calls xsvfShiftOnly to shift in the given TDI data and
*               optionally capture the TDO data.
*               Compares the TDO captured data against the TDO expected
*               data.
*               If a data mismatch occurs, then executes the exception
*               handling loop upto ucMaxRepeat times.
* Parameters:   pucTapState     - Ptr to current TAP state.
*               ucStartState    - Starting shift state: Shift-DR or Shift-IR.
*               lNumBits        - number of bits to shift.
*               plvTdi          - ptr to lenval for TDI data.
*               plvTdoCaptured  - ptr to lenval for storing TDO data.
*               plvTdoExpected  - ptr to expected TDO data.
*               plvTdoMask      - ptr to TDO mask.
*               ucEndState      - state in which to end the shift.
*               lRunTestTime    - amount of time to wait after the shift.
*               ucMaxRepeat     - Maximum number of retries on TDO mismatch.
* Returns:      int             - 0 = success; otherwise TDO mismatch.
* Notes:        XC9500XL-only Optimization:
*               Skip the waitTime() if plvTdoMask->val[0:plvTdoMask->len-1]
*               is NOT all zeros and sMatch==1.
*****************************************************************************/
int xsvfShift( unsigned char*   pucTapState,
               unsigned char    ucStartState,
               long             lNumBits,
               lenVal*          plvTdi,
               lenVal*          plvTdoCaptured,
               lenVal*          plvTdoExpected,
               lenVal*          plvTdoMask,
               unsigned char    ucEndState)
{
    int             iErrorCode;
    int             iMismatch;
    int             iExitShift;

    iErrorCode  = XSVF_ERROR_NONE;
    iMismatch   = 0;

    iExitShift  = ( ucStartState != ucEndState );




            /* Goto Shift-DR or Shift-IR */
            xsvfGotoTapState( pucTapState, ucStartState );

            /* Shift TDI and capture TDO */
            xsvfShiftOnly( lNumBits, plvTdi, plvTdoCaptured, iExitShift );

            if ( plvTdoExpected )
            {
                /* Compare TDO data to expected TDO data */
                iMismatch   = !EqualLenVal( plvTdoExpected,
                                            plvTdoCaptured,
                                            plvTdoMask );
            }

            if ( iExitShift )
            {
                /* Update TAP state:  Shift->Exit */
                ++(*pucTapState);									   

                if ( iMismatch)
                {																	    
                    /* Do exception handling retry - ShiftDR only */
                   
                    /* Shift 1 extra bit */
                    xsvfGotoTapState( pucTapState, XTAPSTATE_SHIFTDR );
                    /* Increment RUNTEST time by an additional 25% */
                  
                }
                else
                {
                    /* Do normal exit from Shift-XR */
                    xsvfGotoTapState( pucTapState, ucEndState );
                }																         
     		}
        
    

    if ( iMismatch )
    {
       
            iErrorCode  = XSVF_ERROR_TDOMISMATCH;
        
    }

    return( iErrorCode );
}



/*============================================================================
* XSVF Command Functions (type = TXsvfDoCmdFuncPtr)
* These functions update pXsvfInfo->iErrorCode only on an error.
* Otherwise, the error code is left alone.
* The function returns the error code from the function.
============================================================================*/


/*****************************************************************************
* Function:     xsvfDoXSIR
* Description:  XSIR <(byte)shiftlen> <lenVal.TDI[shiftlen]>
*               Get the instruction and shift the instruction into the TAP.
*               If prespecified XRUNTEST!=0, goto RUNTEST and wait after
*               the shift for XRUNTEST usec.
* Parameters:   pXsvfInfo   - XSVF information pointer.
* Returns:      int         - 0 = success;  non-zero = error.
*****************************************************************************/
int xsvfDoXSIR( unsigned short usShiftBits )
{
    unsigned short           usShiftBytes;
    int             iErrorCode;

    /* Get the shift length and store */

    usShiftBytes   = xsvfGetAsNumBytes( usShiftBits );

    if ( usShiftBytes > MAX_LEN )
    {
        iErrorCode  = XSVF_ERROR_DATAOVERFLOW;
    }
    else
    {
        /* Get and store instruction to shift in */
        readVal( &(svfInfo.lvTdi), usShiftBytes );

        /* Shift the data */
        iErrorCode  = xsvfShift( &(svfInfo.ucTapState), XTAPSTATE_SHIFTIR,
                                 usShiftBits, &(svfInfo.lvTdi),
                                 /*plvTdoCaptured*/0, /*plvTdoExpected*/0,
                                 /*plvTdoMask*/0, svfInfo.ucEndIR );
    }

    if ( iErrorCode != XSVF_ERROR_NONE )
    {
        svfInfo.iErrorCode   = iErrorCode;
    }
    return( iErrorCode );
}


/*****************************************************************************
* Function:     xsvfDoXSDR
* Description:  XSDR <lenVal.TDI[XSDRSIZE]>
*               Shift the given TDI data into the JTAG scan chain.
*               Compare the captured TDO with the expected TDO from the
*               previous XSDRTDO command using the previously specified
*               XTDOMASK.
* Parameters:   pXsvfInfo   - XSVF information pointer.
* Returns:      int         - 0 = success;  non-zero = error.
*****************************************************************************/
int xsvfDoXSDR( unsigned short usShiftBits,  unsigned char tdo)
{
    unsigned short   usShiftBytes;
    int iErrorCode;

	usShiftBytes= xsvfGetAsNumBytes( usShiftBits );
    readVal( &(svfInfo.lvTdi), usShiftBytes );

	if (tdo)
	{
		readVal(&(svfInfo.lvTdoExpected), usShiftBytes );
		readVal(&(svfInfo.lvTdoMask), usShiftBytes );
	
    	/* use TDOExpected from last XSDRTDO instruction */
    	iErrorCode  = xsvfShift( &(svfInfo.ucTapState), XTAPSTATE_SHIFTDR,
                             usShiftBits, &(svfInfo.lvTdi),
                             &(svfInfo.lvTdoCaptured),
                             &(svfInfo.lvTdoExpected),
                             &(svfInfo.lvTdoMask),
							 svfInfo.ucEndDR );
	}
	else {
    	iErrorCode  = xsvfShift( &(svfInfo.ucTapState), XTAPSTATE_SHIFTDR,
                             usShiftBits, &(svfInfo.lvTdi),
                             0,
                             0,
                             0,
							 svfInfo.ucEndDR );
	}

    if ( iErrorCode != XSVF_ERROR_NONE )
    {
        svfInfo.iErrorCode   = iErrorCode;
    }
    return( iErrorCode );
}

/*****************************************************************************
* Function:     xsvfDoXRUNTEST
* Description:  XRUNTEST <uint32>
*               Prespecify the XRUNTEST wait time for shift operations.
* Parameters:   pXsvfInfo   - XSVF information pointer.
* Returns:      int         - 0 = success;  non-zero = error.
*****************************************************************************/
int xsvfDoXRUNTEST( long cnt )
{									  
    xsvfGotoTapState( &(svfInfo.ucTapState), XTAPSTATE_RUNTEST );		      
   	
	waitTime( cnt);			    
    return( XSVF_ERROR_NONE );
}																		 



/*****************************************************************************
* Function:     xsvfDoXSTATE
* Description:  XSTATE <byte>
*               <byte> == XTAPSTATE;
*               Get the state parameter and transition the TAP to that state.
* Parameters:   pXsvfInfo   - XSVF information pointer.
* Returns:      int         - 0 = success;  non-zero = error.
*****************************************************************************/
int xsvfDoXSTATE( unsigned char ucNextState)
{
   

    svfInfo.iErrorCode  = xsvfGotoTapState( &(svfInfo.ucTapState), ucNextState );
 
    return( svfInfo.iErrorCode );
}

/*****************************************************************************
* Function:     xsvfDoXENDXR
* Description:  XENDIR/XENDDR <byte>
*               <byte>:  0 = RUNTEST;  1 = PAUSE.
*               Get the prespecified XENDIR or XENDDR.
*               Both XENDIR and XENDDR use the same implementation.
* Parameters:   pXsvfInfo   - XSVF information pointer.
* Returns:      int         - 0 = success;  non-zero = error.
*****************************************************************************/
int xsvfDoXENDXR(unsigned char ucCommand, unsigned char   ucEndState )
{
    int             iErrorCode;  

    iErrorCode  = XSVF_ERROR_NONE;

    if ( ( ucEndState != XENDXR_RUNTEST ) && ( ucEndState != XENDXR_PAUSE ) )
    {
        iErrorCode  = XSVF_ERROR_ILLEGALSTATE;
    }
    else
    {

    if ( ucCommand == XENDIR )
    {
            if ( ucEndState == XENDXR_RUNTEST )
            {
                svfInfo.ucEndIR  = XTAPSTATE_RUNTEST;
            }
            else
            {
                svfInfo.ucEndIR  = XTAPSTATE_PAUSEIR;
            }
          
        }
    else    /* XENDDR */
    {
            if ( ucEndState == XENDXR_RUNTEST )
            {
                svfInfo.ucEndDR  = XTAPSTATE_RUNTEST;
            }
    else
    {
                svfInfo.ucEndDR  = XTAPSTATE_PAUSEDR;
            }
        }
    }

    if ( iErrorCode != XSVF_ERROR_NONE )
    {
        svfInfo.iErrorCode   = iErrorCode;
    }
    return( iErrorCode );
}

/*============================================================================
* Execution Control Functions
============================================================================*/

/*****************************************************************************
* Function:     xsvfInitialize
* Description:  Initialize the xsvf player.
*               Call this before running the player to initialize the data
*               in the SXsvfInfo struct.
*               xsvfCleanup is called to clean up the data in SXsvfInfo
*               after the XSVF is played.
* Parameters:   pXsvfInfo   - ptr to the XSVF information.
* Returns:      int - 0 = success; otherwise error.
*****************************************************************************/
int xsvfInitialize(  )
{
    /* Initialize values */
    svfInfo.iErrorCode   = xsvfInfoInit(  );

    if ( !svfInfo.iErrorCode )
    {
        /* Initialize the TAPs */
        svfInfo.iErrorCode   = xsvfGotoTapState( &(svfInfo.ucTapState),
                                                    XTAPSTATE_RESET );
    }

    return( svfInfo.iErrorCode );
}
