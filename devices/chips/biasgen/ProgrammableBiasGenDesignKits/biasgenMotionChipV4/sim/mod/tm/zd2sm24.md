.SUBCKT ZD2SM24 A C S  PROG=0
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : ZENER
* process   : C35[A-B][3-4][A-C][1-3]
* revision : 2.0; 
* extracted : C35[A-B][3-4][A-C][1-3] B11004.L2; 2002-11; hhl (5481)
* doc#      : ENG-182
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
* TERMINALS: A=anode=p+diff, C=cathode=n-diff and n-well, S=p-substrate.
* VARIABLES: M (mulitiplier), PROG (0=zapped, 1=non-zapped).
* NOTE: The Zener diode model is only valid for the predefined layout. 
* Forward bias causes parasitic substrate current and is NOT modelled.
*
RZAP A C '1.86600e+01 + PROG * 1.000e+12'
RCOM C CI 3.99800e+01
EBVT CI BI TP 0 1.000e+00
IBVT 0 TP 1.000e-3
RBVT TP 0 1.000e+3 TC=-2.40000e-03
VBVT BI B 2.256
DFOR A CI ZD2SM24F 1
DREV CX A ZD2SM24R 1
DREV2 CI CX ZD2SM24R2 1
DBVT B A ZD2SM24B 1
XSUB S CI NWD AREA=8.70000e-11 PERI=3.24000e-05
.ENDS ZD2SM24
*
.MODEL ZD2SM24F D LEVEL=1
+IS     =1.17300e-13 N      =1.10100e+00 
+EG     =1.12000e+00 XTI    =2.20200e-01 TT     =8.00000e-08 
+M      =5.19705e-01 VJ     =1.02000e+00 FC     =5.00000e-01 
*
.MODEL ZD2SM24R D LEVEL=1
+IS     =1.30800e-09 N      =6.89200e+00 
+EG     =0.00000e+00 XTI    =1.50000e+02 
*
.MODEL ZD2SM24R2 D LEVEL=1
+IS     =2.36600e-06 N      =1.63600e+01 
+EG     =1.11000e+00 XTI    =3.00000e+00 
*
.MODEL ZD2SM24B D LEVEL=1
+IS     =4.61100e-10 N      =2.75100e+00 
+EG     =1.11000e+00 XTI    =0.00000e+00 
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
