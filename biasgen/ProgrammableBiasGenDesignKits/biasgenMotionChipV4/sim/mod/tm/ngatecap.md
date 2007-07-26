
.SUBCKT NGATECAP N1 N2 AREA=0 PERI=0
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : CAPACITOR
* process   : C35
* revision  : 2; 
* extracted : C35 MAP; ese(5487)
* doc#      : Eng-182 REV_2
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
* VARIABLES: M (mulitiplier), AREA [m^2], PERI [m].
*
C1 N1 N2 C='(4.540e-03*AREA+2.10e-10*PERI)' CTYPE=1
.ENDS NGATECAP
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
