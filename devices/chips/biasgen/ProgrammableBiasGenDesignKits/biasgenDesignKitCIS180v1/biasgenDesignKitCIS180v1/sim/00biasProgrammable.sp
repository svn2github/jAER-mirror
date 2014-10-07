* SPICE export by:  SEDIT 12.61
* Export time:      Thu Feb 07 13:36:07 2008
* Design:           biasgen
* Cell:             biasProgrammable
* View:             view_1
* Export as:        top-level cell
* Export mode:      hierarchical
* Exclude .model:   yes
* Exclude .end:     yes
* Expand paths:     yes
* Wrap lines:       80 characters)
* Root path:        C:\Documents and Settings\tobi\My Documents\avlsi-svn\tretina\tcvs320\schematics\biasgen
* Exclude global pins:   no
* Control property name: SPICE

********* Simulation Settings - General section *********
.option Accurate
.option search="C:\Documents and Settings\tobi\My Documents\avlsi-svn\tretina\tcvs320\schematics\biasgen"
.option search="C:\Documents and Settings\tobi\My Documents\avlsi-svn\tretina\tcvs320\G-05-CMOS_SENSOR18-1.8V_3.3V-SPICE\G-05-CMOS-SENSOR18-1.8V3.3V-SPICEV021\018CIS\model_files\HSPICE"
.probe
.option probev
.option probei

*************** Subcircuits *****************
.subckt biasBuffers biasDisabled biasEnabled_NC_0 biasLowCurrentEnabled biasNormalCurrentEnabled 
+bufferNBias bufferPBias cascodeBiasEnabled generatedBias nBiasEnabled normalBiasEnabled 
+pBiasEnabled powerDown shiftSrcN shiftSrcP splitterOutput AVdd18 Gnd  
MP18R3_8 Gnd pBias N_5 AVdd18 P_18_CIS_MM L=8u W=8u M=1
MN18R_22 shiftSrcP biasNormalCurrentEnabled N_7 AVdd18 P_18_CIS_MM L=.5u W=8u M=1
MN18R_26 pBias nDisable AVdd18 AVdd18 P_18_CIS_MM L=22.9u W=.5u M=1
MP3_1 nDisable biasDisabled N_11 AVdd18 P_18_CIS_MM L=0.18u W=0.46u M=1
MP3_2 disable nDisable AVdd18 AVdd18 P_18_CIS_MM L=0.18u W=.46u M=1
MP3_3 N_11 powerDown AVdd18 AVdd18 P_18_CIS_MM L=0.18u W=0.46u M=1
MP3_4 N_6 bufferPBias AVdd18 AVdd18 P_18_CIS_MM L=.8u W=8u M=1
MN18R_10 shiftSrcP biasNormalCurrentEnabled N_3 AVdd18 P_18_CIS_MM L=.5u W=8u M=1
MN18R_11 N_1 nBias splitterOutput Gnd N_18_CIS_MM L=8u W=8u M=1
MN18R_12 N_2 nBias nCopy Gnd N_18_CIS_MM L=8u W=8u M=1
MN18R_13 N_4 N_1 N_1 Gnd N_18_CIS_MM L=8u W=8u M=1
MN18R_14 N_4 normalBiasEnabled N_1 Gnd N_18_CIS_MM L=.5u W=8u M=1
MN18R_15 N_10 normalBiasEnabled N_2 Gnd N_18_CIS_MM L=.5u W=8u M=1
MN18R_16 N_10 N_2 N_2 Gnd N_18_CIS_MM L=8u W=8u M=1
MN18R_17 Gnd biasNormalCurrentEnabled N_10 Gnd N_18_CIS_MM L=.5u W=8u M=1
MN18R_1 Gnd N_6 shiftSrcN Gnd N_18_CIS_MM L=2.4u W=0.6u M=1
MN18R_18 shiftSrcN biasLowCurrentEnabled N_10 Gnd N_18_CIS_MM L=.5u W=8u M=1
MN18R_2 shiftSrcN N_6 N_6 Gnd N_18_CIS_MM L=.18u W=4.04u M=1
MN18R_3 AVdd18 N_8 shiftSrcP AVdd18 P_18_CIS_MM L=2.4u W=0.6u M=1
MN3_1 Gnd powerDown nDisable Gnd N_18_CIS_MM L=0.18u W=0.46u M=1
MN18R_4 shiftSrcP N_8 N_8 AVdd18 P_18_CIS_MM L=.18u W=3.98u M=1
MN3_2 Gnd biasDisabled nDisable Gnd N_18_CIS_MM L=0.18u W=0.46u M=1
MN18R_5 Gnd biasNormalCurrentEnabled N_4 Gnd N_18_CIS_MM L=.5u W=8u M=1
MN3_3 nBias bufferNBias Gnd Gnd N_18_CIS_MM L=.8u W=8u M=1
MP18L_1 generatedBias pBiasEnabled nBias AVdd18 P_LV_18_CIS_MM L=.24u W=8u M=1
MN18R_6 shiftSrcN biasLowCurrentEnabled N_4 Gnd N_18_CIS_MM L=.5u W=8u M=1
MN3_4 Gnd nDisable disable Gnd N_18_CIS_MM L=0.18u W=.46u M=1
MP18L_2 pBias nBiasEnabled generatedBias AVdd18 P_LV_18_CIS_MM L=.24u W=8u M=1
MN18R_7 Gnd disable nBias Gnd N_18_CIS_MM L=22.9u W=.5u M=1
MN3_5 AVdd18 splitterOutput nBias Gnd N_18_CIS_MM L=.8u W=8u M=1
MN18R_8 AVdd18 biasLowCurrentEnabled N_7 AVdd18 P_18_CIS_MM L=.5u W=8u M=1
MN18R_9 AVdd18 biasLowCurrentEnabled N_3 AVdd18 P_18_CIS_MM L=.5u W=8u M=1
MN3_9 Gnd bufferNBias N_8 Gnd N_18_CIS_MM L=.8u W=8u M=1
MP18R3_1 pBias bufferPBias AVdd18 AVdd18 P_18_CIS_MM L=0.8u W=8u M=1
MP18R3_2 Gnd nCopy pBias AVdd18 P_18_CIS_MM L=0.8u W=8u M=1
MP18R3_3 N_9 cascodeBiasEnabled N_3 AVdd18 P_18_CIS_MM L=0.5u W=8u M=1
MP18R3_4 N_9 N_9 N_3 AVdd18 P_18_CIS_MM L=8u W=8u M=1
MN18L_1 pBias pBiasEnabled generatedBias Gnd N_LV_18_CIS_MM L=.24u W=8u M=1 
MP18R3_5 N_5 cascodeBiasEnabled N_7 AVdd18 P_18_CIS_MM L=0.5u W=8u M=1
MN18L_2 generatedBias nBiasEnabled nBias Gnd N_LV_18_CIS_MM L=.24u W=8u M=1 
MP18R3_6 N_5 N_5 N_7 AVdd18 P_18_CIS_MM L=8u W=8u M=1
MP18R3_7 nCopy pBias N_9 AVdd18 P_18_CIS_MM L=8u W=8u M=1
.ends

.subckt biasShiftRegisterC2MOS d phi q DGnd DVdd18 Gnd  
MN18L_12 DGnd N_3 N_4 Gnd N_LV_18_CIS_MM L=0.3u W=1.5u M=1 
MP18L_10 N_3 q DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MP18L_11 q clk N_9 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MP18L_12 N_9 N_3 DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=2u M=1
MP18L_1 N_2 clk N_8 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MP18L_2 nclk phi DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MP18L_3 clk nclk DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MP18L_4 N_5 N_2 DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MP18L_5 N_8 d DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=2u M=1
MP18L_6 N_2 nclk N_10 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MP18L_7 N_10 N_5 DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=2u M=1
MP18L_8 N_11 N_2 DVdd18 DVdd18 P_LV_18_CIS_MM L=0.3u W=2u M=1
MP18L_9 q nclk N_11 DVdd18 P_LV_18_CIS_MM L=0.3u W=1u M=1
MN18L_1 N_1 nclk N_2 Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
MN18L_2 DGnd d N_1 Gnd N_LV_18_CIS_MM L=0.3u W=1.5u M=1 
MN18L_3 DGnd phi nclk Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
MN18L_4 DGnd nclk clk Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
MN18L_5 DGnd N_2 N_5 Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
MN18L_6 N_6 clk N_2 Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
MN18L_7 DGnd N_5 N_6 Gnd N_LV_18_CIS_MM L=0.3u W=1.5u M=1 
MN18L_8 N_7 clk q Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
MN18L_9 DGnd N_2 N_7 Gnd N_LV_18_CIS_MM L=0.3u W=1.5u M=1 
MN18L_10 DGnd q N_3 Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
MN18L_11 N_4 nclk q Gnd N_LV_18_CIS_MM L=0.3u W=0.6u M=1 
.ends

.subckt biasLatch d latch nlatch nq q DGnd DVdd18 Gnd  
MP4_1 nq inv1in DVdd18 DVdd18 P_18_CIS_MM L=.4u W=.8u M=1
MN3_1 DGnd inv1in nq Gnd N_18_CIS_MM L=.4u W=.8u M=1
MP4_2 q nq DVdd18 DVdd18 P_18_CIS_MM L=.4u W=.8u M=1
MN3_2 DGnd nq q Gnd N_18_CIS_MM L=.4u W=.8u M=1
MP4_3 q nlatch inv1in DVdd18 P_18_CIS_MM L=.4u W=.4u M=1
MN3_3 inv1in nlatch d Gnd N_18_CIS_MM L=.4u W=.4u M=1
MP4_4 d latch inv1in DVdd18 P_18_CIS_MM L=.4u W=.4u M=1
MN3_4 q latch inv1in Gnd N_18_CIS_MM L=.4u W=.4u M=1
.ends

.subckt biasSplitterOctave next out prev sel selb AVdd18 BiasGenNBias Gnd  
Mreadout out sel N_1 Gnd N_18_CIS_MM L=.4u W=1.2u M=1
Mpass next BiasGenNBias prev AVdd18 P_18_CIS_MM L=2.4u W=4.8u M=1
MP3_1 N_2 BiasGenNBias prev AVdd18 P_18_CIS_MM L=2.4u W=4.8u M=1
MP3_2 N_1 BiasGenNBias N_2 AVdd18 P_18_CIS_MM L=2.4u W=4.8u M=1
MN3_1 Gnd selb N_1 Gnd N_18_CIS_MM L=.4u W=1.2u M=1
.ends

.subckt biasSplitterOctaveTerminate left AVdd18 BiasGenNBias Gnd  
MP3_1 Gnd BiasGenNBias left AVdd18 P_18_CIS_MM L=2.4u W=4.8u M=1
.ends

.subckt biasBit d latch next nlatch out phi prev q sel AVdd18 BiasGenNBias DGnd 
+DVdd18 Gnd  
XbiasLatch_1 q latch nlatch nsel sel DGnd DVdd18 Gnd biasLatch  
XbiasSplitterOctave_1 next out prev sel nsel AVdd18 BiasGenNBias Gnd biasSplitterOctave 
XbiasShiftRegisterC2MOS_1 d phi q DGnd DVdd18 Gnd biasShiftRegisterC2MOS  
.ends

.subckt biasConfigBit d latch latchb nout out phi q DGnd DVdd18 Gnd  
XbiasLatch_1 q latch latchb nout out DGnd DVdd18 Gnd biasLatch  
XbiasShiftRegisterC2MOS_1 d phi q DGnd DVdd18 Gnd biasShiftRegisterC2MOS  
.ends


********* Simulation Settings - Parameters and SPICE Options *********

MP18R_1 nlatchenb biasLatch DVdd18 DVdd18 P_18_CIS_MM L=.18u W=3.80u M=1
MP18R_2 bufferPBias bufferPBias AVdd18 AVdd18 P_18_CIS_MM L=0.8u W=8u M=1
MP18R_3 latchEnb nlatchenb DVdd18 DVdd18 P_18_CIS_MM L=.18u W=3.80u M=1
XbiasBit_30 N_46 latchenb N_44 nlatchenb bufferNBias biasClock N_47 N_48 bb3 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_31 N_48 latchenb N_47 nlatchenb bufferNBias biasClock N_49 N_50 bb4 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_10 N_1 latchenb N_2 nlatchenb splitterOutput biasClock N_3 N_4 b17 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_32 N_50 latchenb N_49 nlatchenb bufferNBias biasClock N_37 N_45 bb5 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_11 N_5 latchenb N_6 nlatchenb splitterOutput biasClock N_2 N_1 b16 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_12 N_7 latchenb N_8 nlatchenb splitterOutput biasClock N_6 N_5 b15 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_13 N_9 latchenb N_10 nlatchenb splitterOutput biasClock N_8 N_7 b14 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_14 N_11 latchenb N_12 nlatchenb splitterOutput biasClock N_10 N_9 b13 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_15 N_13 latchenb N_14 nlatchenb splitterOutput biasClock N_12 N_11 b12 
+AVdd18 BiasGenNBias DGnd DVdd18 Gnd biasBit  
MmasterCopy N_60 BiasMasterCopyP AVdd18 AVdd18 P_18_CIS_MM L=2.59u W=6.8u M=2
XbiasBit_16 N_15 latchenb N_16 nlatchenb splitterOutput biasClock N_14 N_13 b11 
+AVdd18 BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_17 N_17 latchenb N_18 nlatchenb splitterOutput biasClock N_16 N_15 b10 
+AVdd18 BiasGenNBias DGnd DVdd18 Gnd biasBit  
MmasterCopy1 N_61 BiasMasterCopyP AVdd18 AVdd18 P_18_CIS_MM L=2.59u W=6.8u M=2
XbiasBit_18 N_19 latchenb N_20 nlatchenb splitterOutput biasClock N_18 N_17 b9 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
MmasterCopy2 Im biasDisabled N_60 AVdd18 P_18_CIS_MM L=330n W=6.8u M=1
XbiasBit_19 N_21 latchenb N_22 nlatchenb splitterOutput biasClock N_20 N_19 b8 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
MmasterCopy3 N_37 biasDisabled N_61 AVdd18 P_18_CIS_MM L=330n W=6.8u M=1
MN18R_1 DGnd biasLatch nlatchenb Gnd N_18_CIS_MM L=.18u W=3.80u M=1
MN18R_2 Gnd bufferNBias bufferNBias Gnd N_18_CIS_MM L=0.8u W=8u M=1
MN18R_3 Gnd bufferNBias bufferPBias Gnd N_18_CIS_MM L=0.8u W=8u M=1
MN18R_4 DGnd nlatchenb latchEnb Gnd N_18_CIS_MM L=.18u W=3.80u M=1
XbiasBit_3 N_40 latchenb N_73 nlatchenb bufferNBias biasClock N_41 N_39 bb0 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_5 N_51 latchenb N_52 nlatchenb splitterOutput biasClock Im N_40 b21 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_7 N_53 latchenb N_54 nlatchenb splitterOutput biasClock N_52 N_51 b20 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBuffers_pd_1 biasDisabled biasEnabled biasLowCurrentEnabled biasNormalCurrentEnabled 
+bufferNBias bufferPBias cascodeBiasEnabled generatedBias nBiasEnabled normalBiasEnabled 
+pBiasEnabled biasPowerDown shiftSrcN shiftSrcP splitterOutput AVdd18 Gnd biasBuffers 
XbiasBit_8 N_55 latchenb N_56 nlatchenb splitterOutput biasClock N_54 N_53 b19 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_9 N_4 latchenb N_3 nlatchenb splitterOutput biasClock N_56 N_55 b18 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasSplitterOctaveTerminate_1 N_38 AVdd18 BiasGenNBias Gnd biasSplitterOctaveTerminate 
XbiasSplitterOctaveTerminate_2 N_73 AVdd18 BiasGenNBias Gnd biasSplitterOctaveTerminate 
XbiasBit_20 N_23 latchenb N_24 nlatchenb splitterOutput biasClock N_22 N_21 b7 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_21 N_25 latchenb N_26 nlatchenb splitterOutput biasClock N_24 N_23 b6 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_22 N_27 latchenb N_28 nlatchenb splitterOutput biasClock N_26 N_25 b5 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_23 N_29 latchenb N_30 nlatchenb splitterOutput biasClock N_28 N_27 b4 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_24 N_31 latchenb N_32 nlatchenb splitterOutput biasClock N_30 N_29 b3 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_25 N_33 latchenb N_34 nlatchenb splitterOutput biasClock N_32 N_31 b2 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_26 N_35 latchenb N_36 nlatchenb splitterOutput biasClock N_34 N_33 b1 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_27 d latchenb N_38 nlatchenb splitterOutput biasClock N_36 N_35 b0 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_28 N_39 latchenb N_41 nlatchenb bufferNBias biasClock N_42 N_43 bb1 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasBit_29 N_43 latchenb N_42 nlatchenb bufferNBias biasClock N_44 N_46 bb2 AVdd18 
+BiasGenNBias DGnd DVdd18 Gnd biasBit  
XbiasConfigBit_1 N_45 latchenb nlatchenb biasLowCurrentEnabled biasNormalCurrentEnabled 
+biasClock N_57 DGnd DVdd18 Gnd biasConfigBit  
XbiasConfigBit_2 N_57 latchenb nlatchenb cascodeBiasEnabled normalBiasEnabled biasClock 
+N_58 DGnd DVdd18 Gnd biasConfigBit  
XbiasConfigBit_3 N_58 latchenb nlatchenb pBiasEnabled nBiasEnabled biasClock N_59 
+DGnd DVdd18 Gnd biasConfigBit  
XbiasConfigBit_4 N_59 latchenb nlatchenb biasDisabled biasEnabled biasClock q DGnd 
+DVdd18 Gnd biasConfigBit  

********* Simulation Settings - Analysis section *********
.tran/Powerup 'period/3.1415926535' 'period*nbits*nLoads'

********* Simulation Settings - Additional SPICE commands *********
.include 0biasProgrammable.sp


