.MODEL MODN NMOS LEVEL=49 
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : MOS BSIM3v3
* process   : C35
* revision : 2; 
* extracted : B10866 ; 2002-12; ese(487)
* doc#      : ENG-182 REV_2
* ----------------------------------------------------------------------
*                        TYPICAL MEAN CONDITION
* ----------------------------------------------------------------------
*
*        *** Flags ***
+MOBMOD =1.000e+00 CAPMOD =2.000e+00 
+NOIMOD =3.000e+00 
+VERSION=3.2   
*        *** Threshold voltage related model parameters ***
+K1     =5.0296e-01 
+K2     =3.3985e-02 K3     =-1.136e+00 K3B    =-4.399e-01 
+NCH    =2.611e+17 VTH0   =4.979e-01 
+VOFF   =-8.925e-02 DVT0   =5.000e+01 DVT1   =1.039e+00 
+DVT2   =-8.375e-03 KETA   =2.032e-02 
+PSCBE1 =3.518e+08 PSCBE2 =7.491e-05 
+DVT0W  =1.089e-01 DVT1W  =6.671e+04 DVT2W  =-1.352e-02 
*        *** Mobility related model parameters ***
+UA     =4.705e-12 UB     =2.137e-18 UC     =1.000e-20 
+U0     =4.758e+02 
*        *** Subthreshold related parameters ***
+DSUB   =5.000e-01 ETA0   =1.415e-02 ETAB   =-1.221e-01 
+NFACTOR=4.136e-01 
*        *** Saturation related parameters ***
+EM     =4.100e+07 PCLM   =6.948e-01 
+PDIBLC1=3.571e-01 PDIBLC2=2.065e-03 DROUT  =5.000e-01 
+A0     =2.541e+00 A1     =0.000e+00 A2     =1.000e+00 
+PVAG   =0.000e+00 VSAT   =1.338e+05 AGS    =2.408e-01 
+B0     =4.301e-09 B1     =0.000e+00 DELTA  =1.442e-02 
+PDIBLCB=3.222e-01 
*        *** Geometry modulation related parameters ***
+W0     =2.673e-07 DLC    =3.0000e-08 
+DWC    =9.403e-08 DWB    =0.000e+00 DWG    =0.000e+00 
+LL     =0.000e+00 LW     =0.000e+00 LWL    =0.000e+00 
+LLN    =1.000e+00 LWN    =1.000e+00 WL     =0.000e+00 
+WW     =-1.297e-14 WWL    =-9.411e-21 WLN    =1.000e+00 
+WWN    =1.000e+00 
*        *** Temperature effect parameters ***
+TNOM   =27.0 AT     =3.300e+04 UTE    =-1.800e+00 
+KT1    =-3.302e-01 KT2    =2.200e-02 KT1L   =0.000e+00 
+UA1    =0.000e+00 UB1    =0.000e+00 UC1    =0.000e+00 
+PRT    =0.000e+00 
*        *** Overlap capacitance related and dynamic model parameters   ***
+CGDO   =1.300e-10 CGSO   =1.200e-10 CGBO   =1.100e-10 
+CGDL   =1.310e-10 CGSL   =1.310e-10 CKAPPA =6.000e-01 
+CF     =0.000e+00 ELM    =5.000e+00 
+XPART  =1.000e+00 CLC    =1.000e-15 CLE    =6.000e-01 
*        *** Parasitic resistance and capacitance related model parameters ***
+RDSW   =3.449e+02 
+CDSC   =0.000e+00 CDSCB  =1.500e-03 CDSCD  =1.000e-03 
+PRWB   =-2.416e-01 PRWG   =0.000e+00 CIT    =4.441e-04 
*        *** Process and parameters extraction related model parameters ***
+TOX    =7.575e-09 NGATE  =0.000e+00 
+NLX    =1.888e-07 
+XL     =0.000e+00 XW     =0.000e+00 
*        *** Substrate current related model parameters ***
+ALPHA0 =0.000e+00 BETA0  =3.000e+01 
*        *** Noise effect related model parameters ***
+AF     =1.3600e+00 KF     =5.1e-27 EF     =1.000e+00 
+NOIA   =1.73e+19 NOIB   =7.000e+04 NOIC   =-5.64e-13 
*        *** Common extrinsic model parameters ***
+ACM    =2        
+RD     =0.000e+00 RS     =0.000e+00 RSH    =7.000e+01 
+RDC    =0.000e+00 RSC    =0.000e+00 
+LINT   =-5.005e-08  WINT   =9.403e-08 
+LDIF   =0.000e+00 HDIF   =8.000e-07 WMLT   =1.000e+00 
+LMLT   =1.000e+00 XJ     =3.000e-07 
+JS     =1.000e-05 JSW    =0.000e+00 IS     =0.000e+00 
+N      =1.000e+00 NDS    =1000. 
+VNDS   =-1.000e+00 CBD    =0.000e+00 CBS    =0.000e+00 CJ     =9.400e-04 CJSW   =2.500e-10 
+FC     =0.000e+00 MJ     =3.400e-01 MJSW   =2.300e-01 TT     =0.000e+00 
+PB     =6.900e-01 PHP    =6.900e-01 
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
