.MODEL MODNM NMOS LEVEL=49 
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : MOS BSIM3v3
* process   : C35
* revision : 2; 
* extracted : B11004 ; 2002-12; ese(487)
* doc#      : ENG-182 REV_2
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
*
*        *** Flags ***
+MOBMOD =1.000e+00 CAPMOD =2.000e+00 
+NOIMOD =3.000e+00 
+VERSION=3.11      
*        *** Threshold voltage related model parameters ***
+K1     =7.4922e-01 
+K2     =1.1026e-01 K3     =-3.776e+00 K3B    =-7.691e-02 
+NCH    =2.265e+17 VTH0   =7.525e-01 
+VOFF   =-8.295e-02 DVT0   =3.000e+01 DVT1   =1.528e+00 
+DVT2   =2.529e-02 KETA   =3.585e-02 
+PSCBE1 =4.309e+08 PSCBE2 =1.000e-10 
+DVT0W  =-5.000e+00 DVT1W  =2.578e+06 DVT2W  =5.105e-02 
*        *** Mobility related model parameters ***
+UA     =4.708e-10 UB     =1.470e-18 UC     =-4.342e-11 
+U0     =5.643e+02 
*        *** Subthreshold related parameters ***
+DSUB   =5.000e-01 ETA0   =3.795e-02 ETAB   =-7.653e-04 
+NFACTOR=8.573e-01 
*        *** Saturation related parameters ***
+EM     =4.100e+07 PCLM   =2.125e-01 
+PDIBLC1=1.000e-04 PDIBLC2=5.458e-04 DROUT  =5.000e-01 
+A0     =2.064e+00 A1     =0.000e+00 A2     =1.000e+00 
+PVAG   =0.000e+00 VSAT   =1.078e+05 AGS    =1.079e-01 
+B0     =-1.493e-07 B1     =0.000e+00 DELTA  =1.000e-02 
+PDIBLCB=5.186e-01 
*        *** Geometry modulation related parameters ***
+W0     =1.617e-07 DLC    =1.0000e-07 
+DWC    =1.623e-07 DWB    =0.000e+00 DWG    =0.000e+00 
+LL     =0.000e+00 LW     =0.000e+00 LWL    =0.000e+00 
+LLN    =1.000e+00 LWN    =1.000e+00 WL     =0.000e+00 
+WW     =-5.117e-14 WWL    =-5.704e-21 WLN    =1.000e+00 
+WWN    =1.000e+00 
*        *** Temperature effect parameters ***
+TNOM   =27.0 AT     =3.300e+04 UTE    =-1.760e+00 
+KT1    =-4.502e-01 KT2    =2.200e-02 KT1L   =0.000e+00 
+UA1    =0.000e+00 UB1    =0.000e+00 UC1    =0.000e+00 
+PRT    =0.000e+00 
*        *** Overlap capacitance related and dynamic model parameters   ***
+CGDO   =1.080e-10 CGSO   =1.080e-10 CGBO   =1.100e-10 
+CGDL   =2.270e-10 CGSL   =2.270e-10 CKAPPA =6.000e-01 
+CF     =0.000e+00 ELM    =5.000e+00 
+XPART  =1.000e+00 CLC    =1.000e-15 CLE    =6.000e-01 
*        *** Parasitic resistance and capacitance related model parameters ***
+RDSW   =1.390e+03 
+CDSC   =0.000e+00 CDSCB  =-1.500e-03 CDSCD  =0.000e+00 
+PRWB   =-6.740e-02 PRWG   =0.000e+00 CIT    =0.000e+00 
*        *** Process and parameters extraction related model parameters ***
+TOX    =1.516e-08 NGATE  =0.000e+00 
+NLX    =2.283e-07 
+XL     =0.000e+00 XW     =0.000e+00 
*        *** Substrate current related model parameters ***
+ALPHA0 =0.000e+00 BETA0  =3.000e+01 
*        *** Noise effect related model parameters ***
+AF     =1.270e+00 KF     =3.50e-27 EF     =1.000e+00 
+NOIA   =6.64e+19 NOIB   =1.090e+05 NOIC   =-1.4e-13 
*        *** Common extrinsic model parameters ***
+ACM    =2        
+RD     =0.000e+00 RS     =0.000e+00 RSH    =7.900e+01 
+RDC    =0.000e+00 RSC    =0.000e+00 
+LINT   =1.225e-07  WINT   =1.623e-07 
+LDIF   =0.000e+00 HDIF   =6.000e-07 WMLT   =1.000e+00 
+LMLT   =1.000e+00 XJ     =3.000e-07 
+JS     =1.000e-05 JSW    =0.000e+00 IS     =0.000e+00 
+N      =1.000e+00 NDS    =1000. 
+VNDS   =-1.000e+00 CBD    =0.000e+00 CBS    =0.000e+00 CJ     =9.400e-04 CJSW   =2.500e-10 
+FC     =0.000e+00 MJ     =3.400e-01 MJSW   =2.300e-01 TT     =0.000e+00 
+PB     =6.900e-01 PHP    =6.900e-01 
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
