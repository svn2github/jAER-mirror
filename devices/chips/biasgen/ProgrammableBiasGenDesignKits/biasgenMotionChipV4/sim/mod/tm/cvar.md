
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : varactor
* process   : C35[A-B][3-4][B-C][0-3]
* revision  : 1.0;
* extracted : CSX c6412600; 2001-09; kmo
* doc#      : Eng-182 REV_1  
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ---------------------------------------------------
.SUBCKT CVAR G B S  W=1e-6 L=1e-6 ROW=1 COL=1
+AW1='((8.000e-01*ROW+(6.600e+00*ROW)+(8.000e-01*(ROW-1))+(-1.000e-01*2))*(3.000e-01*2+(0.8500e+00*2)+(6.500e-01*COL)+(1.000e+00*(COL-1)))*1e-12)'
+AW2='2*((8.000e-01*ROW+(6.600e+00*ROW)+(8.000e-01*(ROW-1))+(-1.000e-01*2))+(3.000e-01*2+(0.8500e+00*2)+(6.500e-01*COL)+(1.000e+00*(COL-1))))*1e-6'
* TERMINALS: G=gate B=bulk S=P-SUB
*
* Gate inductance and Gate resistance
LG G G0 '-6.092e-08*W+2.390e-10'
RG G0 G1 '9.260e-04/W+5.130e-01'
* Intrinsic PMOS transistor - Cap modelling
M1 D1 G1 S1 B CVARINSUB W=W L=6.5e-7 AD=0 AS=0 PD=0 PS=0 NRD=0 NRS=0
* N-buried Layer - PSUB diode
DSUB1 B1 B DWELL1 AREA=AW1
DSUB2 B2 B DWELL2 AREA=AW2
RSUB1 B1 S '1.964e-01/W+5.110e+02'
RSUB2 B2 S '0.000e+00/W+2.651e+01'
* Avoid floating nodes
* drain and source disconnected 
* high impedance to ground
ROPEN1 D1 S RVARMOD
ROPEN2 S1 S RVARMOD
.ENDS CVAR
* 
.MODEL RVARMOD R RES=1.0e+12 NOISE=0
.MODEL CVARINSUB PMOS LEVEL=49 
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : varactor
* process   : C35[A-B][3-4][B-C][0-3]
* revision : 1.0; 
* extracted : CSX c6412600; 2001-09; kmo
* doc#      : Eng-182 REV_1
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
*Segment Width = 6.6um, 
* Total Width = R*C*Segment Width, L=0.65um,
* R: number of columns, C: number of rows
*
*        *** Flags ***
+MOBMOD =1.000e+00 CAPMOD =3.000e+00 
+NOIMOD =1.000e+00 
+VERSION=3.22 
*        *** Threshold voltage related model parameters ***
+K1     =6.0040e-01 
+K2     =-7.128e-02 K3     =0.000e+00 K3B    =0.000e+00 
+NCH    =9.439e+16 VTH0   =-1.243e+00 
+VOFF   =0.000e+00 DVT0   =0.000e+00 DVT1   =0.000e+00 
+DVT2   =0.000e+00 KETA   =0.000e+00 
+PSCBE1 =0.000e+00 PSCBE2 =1.000e-08 
+DVT0W  =0.000e+00 DVT1W  =0.000e+00 DVT2W  =0.000e+00 
*        *** Mobility related model parameters ***
+UA     =0.000e+00 UB     =8.29e-19 UC     =0.000e+00 
+U0     =1.296e+02 
*        *** Subthreshold related parameters ***
+DSUB   =0.000e+00 ETA0   =0.000e+00 ETAB   =0.000e+00 
+NFACTOR=0.000e+00 
*        *** Saturation related parameters ***
+EM     =4.100e+07 PCLM   =2.979e+00 
+PDIBLC1=3.31e-02 PDIBLC2=1.000e-09 DROUT  =0.000e+00 
+A0     =1.4230e+00 A1     =0.000e+00 A2     =1.000e+00 
+PVAG   =0.000e+00 VSAT   =2.000e+05 AGS    =0.000e+00 
+B0     =0.000e+00 B1     =0.000e+00 DELTA  =0.000e+00 
+PDIBLCB=0.000e+00 
*        *** Geometry modulation related parameters ***
+W0     =0.000e+00 DLC    =0.000e+00 
+DWC    =0.000e+00 DWB    =0.000e+00 DWG    =0.000e+00 
+LL     =0.000e+00 LW     =0.000e+00 LWL    =0.000e+00 
+LLN    =1.000e+00 LWN    =1.000e+00 WL     =0.000e+00 
+WW     =0.000e+00 WWL    =0.000e+00 WLN    =1.000e+00 
+WWN    =1.000e+00 
*        *** Temperature effect parameters ***
+TNOM   =27.0 AT     =0.000e+00 UTE    =0.000e+00 
+KT1    =-5.703e-01 KT2    =2.200e-02 KT1L   =0.000e+00 
+UA1    =0.000e+00 UB1    =0.000e+00 UC1    =0.000e+00 
+PRT    =0.000e+00 
*        *** Overlap capacitance related and dynamic model parameters   ***
+CGDO   =1.000e-10 CGSO   =1.000e-10 CGBO   =0.000e+00 
+CGDL   =0.000e+00 CGSL   =0.000e+00 CKAPPA =6.000e-01 
+CF     =0.000e+00 ELM    =5.000e+00 
+XPART  =1.000e+00 CLC    =0.000e+00 CLE    =0.000e+00 
*        *** Parasitic resistance and capacitance related model parameters ***
+RDSW   =0.000e+00 
+CDSC   =0.000e+00 CDSCB  =0.000e+00 CDSCD  =0.000e+00 
+PRWB   =0.000e+00 PRWG   =0.000e+00 CIT    =0.000e+00 
*        *** Process and parameters extraction related model parameters ***
+TOX    =6.925e-09 NGATE  =0.000e+00 
+NLX    =0.000e+00 
+XL     =-5.000e-08 XW     =0.000e+00 
*        *** Substrate current related model parameters ***
+ALPHA0 =0.000e+00 BETA0  =0.000e+00 
*        *** Noise effect related model parameters ***
+AF     =1.290e+00 KF     =1.090e-27 EF     =1.000e+00 
+NOIA   =1.000e+20 NOIB   =5.000e+04 NOIC   =-1.400e-12 
*        *** Common extrinsic model parameters ***
+ACM    =2        
+RD     =0.000e+00 RS     =0.000e+00 RSH    =1.560e+02 
+RDC    =0.000e+00 RSC    =0.000e+00 
+LINT   =0.000e+00  WINT   =0.000e+00 
+LDIF   =0.000e+00 HDIF   =0.000e+00 WMLT   =1.000e+00 
+LMLT   =1.000e+00 XJ     =3.000e-07 
+JS     =0.000e+00 JSW    =0.000e+00 IS     =0.000e+00 
+N      =1.000e+00 NDS    =1000. 
+VNDS   =-1.000e+00 CBD    =0.000e+00 CBS    =0.000e+00 CJ     =0.000e+00 CJSW   =0.000e+00 
+FC     =0.000e+00 MJ     =0.000e+00 MJSW   =0.000e+00 TT     =0.000e+00 
+PB     =1.020e+00 PHP    =1.020e+00 
* ----------------------------------------------------------------------
.MODEL DWELL1 D LEVEL=1
+ IS   =3.0e-05   ISW  =0.0e+00 N    =1.0000000   
+ CJO  =9.479e-05   MJSW =0.000e+00   M    =3.900e-01   
+ FC   =0.000e+00   TT   =0.000e+00   VJ   =5.300e-01   
+ AF   =1.000e+00   KF   =0.000e+00   EG   =1.11e+00   XTI  =3.000e+00   
.MODEL DWELL2 D LEVEL=1
+ IS   =3.0e-10   ISW  =0.0e+00 N    =1.0000000   
+ CJO  =6.270e-10   MJSW =0.000e+00   M    =2.391e-01   
+ FC   =0.000e+00   TT   =0.000e+00   VJ   =5.300e-01   
+ AF   =1.000e+00   KF   =0.000e+00   EG   =1.11e+00   XTI  =3.000e+00   
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
