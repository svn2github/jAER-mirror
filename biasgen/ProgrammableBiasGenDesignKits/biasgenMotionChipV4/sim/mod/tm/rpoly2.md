.SUBCKT RPOLY2 N1 N2 W=1e-6 L=1e-6
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : RESISTOR
* process   : C35[B3C0][B3C1-3][B4C0-3]
* revision  : 2.0;
* extracted : C35 MAP; 2002-11; hhl(5481)
* doc#      : Eng-182
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
* VARIABLES: M (mulitiplier)  W,L = device width and length [m]
*R1 N1 N2 Rval TC1 <TC2> 
R1 N1 N2 '5.00e+01*(L-(0.0))/(W-(2.50e-07))' 7.00e-04  
.ENDS RPOLY2
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
