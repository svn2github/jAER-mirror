.SUBCKT NWD A C AREA=1e-12 PJ=4e-6
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : DIODE
* process   : C35[A-B][3-4][A-C][1-3]
* revision : 2.0; 
* extracted : C35[A-B][3-4][A-C][1-3] B11004.L2; 2002-11; hhl (5481)
* doc#      : ENG-182
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
* TERMINALS: A=anode=P-region C=cathode=N-region
* VARIABLES: M (mulitiplier), AREA [m^2], PERI [m].
* NOTE: The role of a protection DIODE is to conduct ESD current to VDD 
* (or from VSS). This forward bias is NOT modelled, only leakage current 
* and capacitance during normal operation. Any inductive load etc that 
* will give forward bias, must be limited by other components to within 
* Operating Conditions, otherwise parasitic bipolar action can occur.
*
D1 A C NWDINSUB AREA=AREA PJ=PJ
.ENDS NWD
*
.MODEL NWDINSUB D LEVEL=1
+IS     =6.0000e-05 JSW    =2.7000e-10 N      =1.000e+00 
+CJ     =8.0000e-05 M      =3.9000e-01 VJ     =5.3000e-01 TT     =0.000e+00 
+CJSW   =5.1000e-10 MJSW   =2.7000e-01 FC     =0.500e+00 
+EG     =1.110e+00 XTI    =3.000e+00 AF     =1.000e+00 KF     =0.000e+00
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
