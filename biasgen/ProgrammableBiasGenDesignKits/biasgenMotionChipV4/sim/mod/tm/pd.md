.SUBCKT PD A C AREA=1e-12 PJ=4e-6
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : DIODE
* process   : C35
* revision : 2; 
* extracted : C64685 ; 2002-12; ese(487)
* doc#      : ENG-182 REV_2
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
D1 A C PDINSUB AREA=AREA PJ=PJ
.ENDS PD
*
.MODEL PDINSUB D LEVEL=1
+IS     =9.000e-05 JSW    =0.000e+00 N      =1.000e+00 
+CJ     =1.360e-03 M      =5.600e-01 VJ     =1.020e+00 TT     =0.000e+00 
+CJSW   =3.200e-10 MJSW   =4.300e-01 FC     =0.500e+00 
+EG     =1.110e+00 XTI    =3.000e+00 AF     =1.000e+00 KF     =0.000e+00
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
