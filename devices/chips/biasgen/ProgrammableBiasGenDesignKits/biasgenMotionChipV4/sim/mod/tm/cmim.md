
.SUBCKT CMIM N1 N2 AREA=0 PERI=0
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : CAPACITOR
* process   : C35[A-B][3-4][B-C][0-3]
* revision  : 2.0; 
* extracted : B10748.L1; 2002-11; hhl(5481)
* doc#      : Eng-182
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
* VARIABLES: M (mulitiplier), AREA [m^2], PERI [m].
*
C1 N1 N2 C='(1.250e-03*AREA+0.114e-09*PERI)' CTYPE=1
.ENDS CMIM
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital