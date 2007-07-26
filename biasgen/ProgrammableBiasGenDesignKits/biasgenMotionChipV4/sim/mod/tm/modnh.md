.SUBCKT MODNH D G S B W=1e-6 L=1e-6 AD=0 AS=0 PD=0 PS=0 NRD=0 NRS=0
* VARIABLES: W,L,AD,AS,PD,PS,NRD,NRS = standard MOSFET parameters
*
M1 D1 G S B MODNHINSUB W=W L=L AD=AD AS=AS PD=PD PS=PS NRD=NRD NRS=NRS
RD D1 D '1.328e+03*4.000e-06/(W)' 6.200e-03  
.ENDS MODNH
.MODEL MODNHINSUB NMOS LEVEL=49 
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : MOS BSIM3v3
* process   : C35
* revision : ; 
* extracted : C35 B11004.L2; 2002-11; hhl(5481)
* doc#      : REV_2.0
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
*
*        *** Flags ***
+MOBMOD =1.000e+00 CAPMOD =2.000e+00 
+NOIMOD =1.000e+00 
+VERSION=3.11      
*        *** Threshold voltage related model parameters ***
+K1     =6.2697e-01 
+K2     =-4.966e-03 K3     =-2.240e+00 K3B    =6.954e-01 
+NCH    =2.236e+17 VTH0   =4.460e-01 
+VOFF   =-5.090e-02 DVT0   =4.985e+01 DVT1   =1.296e+00 
+DVT2   =1.311e-02 KETA   =-4.553e-02 
+PSCBE1 =1.000e+10 PSCBE2 =1.024e-05 
+DVT0W  =0.000e+00 DVT1W  =0.000e+00 DVT2W  =0.000e+00 
*        *** Mobility related model parameters ***
+UA     =1.000e-30 UB     =1.949e-18 UC     =1.217e-10 
+U0     =3.427e+02 
*        *** Subthreshold related parameters ***
+DSUB   =5.000e-01 ETA0   =3.075e-02 ETAB   =-5.261e-02 
+NFACTOR=2.034e-01 
*        *** Saturation related parameters ***
+EM     =4.100e+07 PCLM   =2.940e-01 
+PDIBLC1=3.090e-02 PDIBLC2=6.375e-04 DROUT  =5.000e-01 
+A0     =1.893e-01 A1     =0.000e+00 A2     =1.000e+00 
+PVAG   =0.000e+00 VSAT   =2.402e+05 AGS    =1.245e-01 
+B0     =6.790e-08 B1     =0.000e+00 DELTA  =1.729e-02 
+PDIBLCB=2.067e-01 
*        *** Geometry modulation related parameters ***
+W0     =1.145e-07 DLC    =6.000e-07 
+DWC    =2.605e-08 DWB    =0.000e+00 DWG    =0.000e+00 
+LL     =0.000e+00 LW     =0.000e+00 LWL    =0.000e+00 
+LLN    =1.000e+00 LWN    =1.000e+00 WL     =0.000e+00 
+WW     =0.000e+00 WWL    =0.000e+00 WLN    =1.000e+00 
+WWN    =1.000e+00 
*        *** Temperature effect parameters ***
+TNOM   =2.700e+01 AT     =3.300e+04 UTE    =-1.800e+00 
+KT1    =-3.302e-01 KT2    =2.200e-02 KT1L   =0.000e+00 
+UA1    =0.000e+00 UB1    =0.000e+00 UC1    =0.000e+00 
+PRT    =0.000e+00 
*        *** Overlap capacitance related and dynamic model parameters   ***
+CGDO   =1.200e-10 CGSO   =1.200e-10 CGBO   =1.100e-10 
+CGDL   =0.000e+00 CGSL   =0.000e+00 CKAPPA =6.000e-01 
+CF     =0.000e+00 ELM    =5.000e+00 
+XPART  =1.000e+00 CLC    =1.000e-15 CLE    =6.000e-01 
*        *** Parasitic resistance and capacitance related model parameters ***
+RDSW   =1.092e+03 
+CDSC   =7.944e-03 CDSCB  =0.000e+00 CDSCD  =8.448e-05 
+PRWB   =0.000e+00 PRWG   =0.000e+00 CIT    =1.000e-03 
*        *** Process and parameters extraction related model parameters ***
+TOX    =7.700e-09 NGATE  =0.000e+00 
+NLX    =1.132e-07 
+XL     =0.000e+00 XW     =0.000e+00 
*        *** Substrate current related model parameters ***
+ALPHA0 =0.000e+00 BETA0  =3.000e+01 
*        *** Noise effect related model parameters ***
+AF     =1.400e+00 KF     =2.810e-27 EF     =1.000e+00 
+NOIA   =1.000e+20 NOIB   =5.000e+04 NOIC   =-1.400e-12 
*        *** Common extrinsic model parameters ***
+ACM    =2        
+RD     =0.000e+00 RS     =0.000e+00 RSH    =8.200e+01 
+RDC    =0.000e+00 RSC    =0.000e+00 
+LINT   =6.000e-07  WINT   =2.605e-08 
+LDIF   =0.000e+00 HDIF   =6.000e-07 WMLT   =1.000e+00 
+LMLT   =1.000e+00 XJ     =3.000e-07 
+JS     =6.000e-05 JSW    =0.000e+00 IS     =0.000e+00 
+N      =1.000e+00 NDS    =1000. 
+VNDS   =-1.000e+00 CBD    =0.000e+00 CBS    =0.000e+00 CJ     =8.000e-05 CJSW   =5.100e-10 
+FC     =0.000e+00 MJ     =3.900e-01 MJSW   =2.700e-01 TT     =0.000e+00 
+PB     =5.300e-01 PHP    =6.900e-01 
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
