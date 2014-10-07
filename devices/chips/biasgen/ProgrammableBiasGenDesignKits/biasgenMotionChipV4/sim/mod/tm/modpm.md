.MODEL MODPM PMOS LEVEL=49 
* ----------------------------------------------------------------------
************************* SIMULATION PARAMETERS ************************
* ----------------------------------------------------------------------
* format    : HSPICE
* model     : MOS BSIM3v3
* process   : C35
* revision : 2; 
* extracted : C64685 ; 2002-12; ese(487)
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
+K1     =5.4907e-01 
+K2     =4.6395e-02 K3     =8.317e+00 K3B    =-1.479e+00 
+NCH    =8.479e+16 VTH0   =-1.011e+00 
+VOFF   =-1.148e-01 DVT0   =5.399e-01 DVT1   =4.112e-01 
+DVT2   =-9.479e-02 KETA   =3.010e-02 
+PSCBE1 =5.000e+09 PSCBE2 =1.000e-10 
+DVT0W  =8.099e-01 DVT1W  =1.480e+05 DVT2W  =4.404e-02 
*        *** Mobility related model parameters ***
+UA     =1.800e-12 UB     =2.218e-18 UC     =-7.278e-11 
+U0     =1.373e+02 
*        *** Subthreshold related parameters ***
+DSUB   =5.000e-01 ETA0   =9.736e-02 ETAB   =-2.948e-02 
+NFACTOR=7.046e-01 
*        *** Saturation related parameters ***
+EM     =4.100e+07 PCLM   =4.395e+00 
+PDIBLC1=2.037e-02 PDIBLC2=1.000e-20 DROUT  =5.000e-01 
+A0     =1.386e+00 A1     =0.000e+00 A2     =1.000e+00 
+PVAG   =0.000e+00 VSAT   =1.436e+05 AGS    =1.364e-01 
+B0     =1.991e-08 B1     =0.000e+00 DELTA  =1.000e-02 
+PDIBLCB=1.000e+00 
*        *** Geometry modulation related parameters ***
+W0     =1.000e-10 DLC    =2.5000e-08 
+DWC    =6.203e-08 DWB    =0.000e+00 DWG    =0.000e+00 
+LL     =0.000e+00 LW     =0.000e+00 LWL    =0.000e+00 
+LLN    =1.000e+00 LWN    =1.000e+00 WL     =0.000e+00 
+WW     =-9.750e-16 WWL    =-1.787e-21 WLN    =1.000e+00 
+WWN    =1.040e+00 
*        *** Temperature effect parameters ***
+TNOM   =27.0 AT     =3.300e+04 UTE    =-1.300e+00 
+KT1    =-6.003e-01 KT2    =2.200e-02 KT1L   =0.000e+00 
+UA1    =0.000e+00 UB1    =0.000e+00 UC1    =0.000e+00 
+PRT    =0.000e+00 
*        *** Overlap capacitance related and dynamic model parameters   ***
+CGDO   =9.100e-11 CGSO   =9.100e-11 CGBO   =1.100e-10 
+CGDL   =0.600e-10 CGSL   =0.600e-10 CKAPPA =6.000e-01 
+CF     =0.000e+00 ELM    =5.000e+00 
+XPART  =1.000e+00 CLC    =1.000e-15 CLE    =6.000e-01 
*        *** Parasitic resistance and capacitance related model parameters ***
+RDSW   =1.623e+03 
+CDSC   =1.214e-03 CDSCB  =2.945e-04 CDSCD  =0.000e+00 
+PRWB   =-4.521e-01 PRWG   =0.000e+00 CIT    =5.259e-05 
*        *** Process and parameters extraction related model parameters ***
+TOX    =1.450e-08 NGATE  =0.000e+00 
+NLX    =2.231e-07 
+XL     =0.000e+00 XW     =0.000e+00 
*        *** Substrate current related model parameters ***
+ALPHA0 =0.000e+00 BETA0  =3.000e+01 
*        *** Noise effect related model parameters ***
+AF     =1.5e+00 KF     =9.4e-27 EF     =1.000e+00 
+NOIA   =1.09e+18 NOIB   =6.01e+03 NOIC   =1.19e-12 
*        *** Common extrinsic model parameters ***
+ACM    =2        
+RD     =0.000e+00 RS     =0.000e+00 RSH    =1.300e+02 
+RDC    =0.000e+00 RSC    =0.000e+00 
+LINT   =-8.504e-08  WINT   =6.203e-08 
+LDIF   =0.000e+00 HDIF   =6.000e-07 WMLT   =1.000e+00 
+LMLT   =1.000e+00 XJ     =3.000e-07 
+JS     =9.000e-05 JSW    =0.000e+00 IS     =0.000e+00 
+N      =1.000e+00 NDS    =1000. 
+VNDS   =-1.000e+00 CBD    =0.000e+00 CBS    =0.000e+00 CJ     =1.360e-03 CJSW   =3.200e-10 
+FC     =0.000e+00 MJ     =5.600e-01 MJSW   =4.300e-01 TT     =0.000e+00 
+PB     =1.020e+00 PHP    =1.020e+00 
* ----------------------------------------------------------------------
* Owner: austriamicrosystems
* HIT-Kit: Digital
