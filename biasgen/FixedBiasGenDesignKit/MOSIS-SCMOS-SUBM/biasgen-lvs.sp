* Copy of biasgen schematic written to include individual biases
* SPICE export from S-Edit 12.51 Wed Jul 25 22:16:11 2007
* Design:  biasgen-scmos-subm
* Cell:    biasgen
* View:    view_1
* Export as: Top-level Cell
* Netlist port order: default
* Exclude .model : yes
* Exclude .end: yes
* Expand paths: yes
* Root path: C:\Documents and Settings\tobi\My Documents\~jAER-sourceForge\biasgen\FixedBiasGenDesignKit\biasgen-scmos-subm
* Exclude global pins on subcircuits: no
* Export control property name: SPICE
* Wrap lines: yes (to 80 characters)

********* Simulation Settings - General section *********

*************** Subcircuits *****************
.subckt biassource nbias ncasc out Gnd Vdd  
MN3_10 N_1 ncasc nmid Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
MP4_1  N_1 N_1 pmid pmid pmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
MP4_2  out N_1 N_2 pmid pmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
MP3_4  N_2 pmid Vdd Vdd pmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
MP3_5  pmid pmid Vdd Vdd pmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
MN3_5 nmid nbias Gnd Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
.ends

.subckt masterbias VSrcN VSrcP masterOut powerDown rx BiasGenNBias BiasGenNCasc 
+Gnd Vdd  
MN3_1 BiasGenNCasc powerDown Gnd Gnd nmos L=6 W=6 AD='(6*3)+36' PD='6+6+6' AS='(6*3)+36' 
+PS='6+6+6' M=1
Mnres nMirrorOut BiasGenNBias rx Gnd nmos L=6 W=120 AD='(120*3)+36' PD='120+6+6' 
+AS='(120*3)+36' PS='120+6+6' M=8
MN3_2 pMirrorGate BiasGenNCasc nMirrorOut Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' 
+AS='(24*3)+36' PS='24+6+6' M=1
MN3_3 BiasGenNCasc BiasGenNCasc BiasGenNBias Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' 
+AS='(24*3)+36' PS='24+6+6' M=1
MN3_4 powerDown kickgate powerDown Gnd nmos L=132 W=21.5 AD='(21.5*3)+36' PD='21.5+6+6' 
+AS='(21.5*3)+36' PS='21.5+6+6' M=1
MN3_5 Vdd pMirrorGate Vdd Gnd nmos L=132 W=17.5 AD='(17.5*3)+36' PD='17.5+6+6' AS='(17.5*3)+36' 
+PS='17.5+6+6' M=1
Xbiassource_1 BiasGenNBias BiasGenNCasc masterOut Gnd Vdd biassource  
Mnbias BiasGenNBias BiasGenNBias Gnd Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' 
+AS='(24*3)+36' PS='24+6+6' M=1
MP3_1  pMirrorGate pMirrorGate Vdd Vdd pmos L=65 W=76 AD='(76*3)+36' PD='76+6+6' 
+AS='(76*3)+36' PS='76+6+6' M=1
MP3_2  BiasGenNCasc pMirrorGate Vdd Vdd pmos L=65 W=76 AD='(76*3)+36' PD='76+6+6' 
+AS='(76*3)+36' PS='76+6+6' M=1
MP3_3  BiasGenNCasc kickgate Vdd Vdd pmos L=6 W=6 AD='(6*3)+36' PD='6+6+6' AS='(6*3)+36' 
+PS='6+6+6' M=1
MP3_4  kickgate pMirrorGate Vdd Vdd pmos L=6 W=6 AD='(6*3)+36' PD='6+6+6' AS='(6*3)+36' 
+PS='6+6+6' M=1
.ends


********* Simulation Settings - Parameters and SPICE Options *********

*BIASCOMPILE name=Vbinv type=N_CURRENT I=8e-9 W=24 L=6  M=1
Xmasterbias N_1 N_2 masterOut powerDown rx BiasGenNBias BiasGenNCasc Gnd Vdd masterbias 
*BIASPROCESS kprime=3.65e-005 temperature=25
*BIASCOMPILE name=VreqPD type=N_CURRENT I=32e-9 W=24 L=6  M=1
*BIASCOMPILE name=VAbias type=N_CURRENT I=32e-9 W=24 L=6  M=1
*BIASCOMPILE name=VDischargeBias type=N_CURRENT I=1e-9 W=24 L=6  M=1
*BIASCOMPILE name=VreqPU type=P_CURRENT I=32e-9 W=24 L=6  M=1
*BIASCOMPILE name=VBusyPU type=P_CURRENT I=128e-9 W=24 L=6  M=1
*BIASCOMPILE name=VCompBias type=N_CURRENT I=4e-9 W=24 L=6  M=1
*BIASCOMPILE name=PixelBuffer1bias type=P_CURRENT I=4e-9 W=24 L=6  M=1
*BIASCOMPILE name=VFollBias type=N_CURRENT I=128e-9 W=24 L=6  M=1

********* Simulation Settings - Analysis section *********

********* Simulation Settings - Additional SPICE commands *********


* circuit for individual bias Vbinv
Xbiassource_1000 nb4 BiasGenNCasc Vbinv Gnd Vdd biassource
M1001 Vbinv Vbinv Gnd Gnd nmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias VreqPD
Xbiassource_1002 nb2 BiasGenNCasc VreqPD Gnd Vdd biassource
M1003 VreqPD VreqPD Gnd Gnd nmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias VAbias
Xbiassource_1004 nb2 BiasGenNCasc VAbias Gnd Vdd biassource
M1005 VAbias VAbias Gnd Gnd nmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias VDischargeBias
Xbiassource_1006 nb7 BiasGenNCasc VDischargeBias Gnd Vdd biassource
M1007 VDischargeBias VDischargeBias Gnd Gnd nmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias VreqPU
M1008 Nmid1008 nb2 Gnd Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' PS='24+6+6' M=1
M1009 VreqPU BiasGenNCasc Nmid1008 Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' PS='24+6+6' M=1
M1010 Vdd VreqPU VreqPU Vdd pmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias VBusyPU
M1011 Nmid1011 nb0 Gnd Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' PS='24+6+6' M=1
M1012 VBusyPU BiasGenNCasc Nmid1011 Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' PS='24+6+6' M=1
M1013 Vdd VBusyPU VBusyPU Vdd pmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias VCompBias
Xbiassource_1014 nb5 BiasGenNCasc VCompBias Gnd Vdd biassource
M1015 VCompBias VCompBias Gnd Gnd nmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias PixelBuffer1bias
M1016 Nmid1016 nb5 Gnd Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' PS='24+6+6' M=1
M1017 PixelBuffer1bias BiasGenNCasc Nmid1016 Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' PS='24+6+6' M=1
M1018 Vdd PixelBuffer1bias PixelBuffer1bias Vdd pmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1
* circuit for individual bias VFollBias
Xbiassource_1019 nb0 BiasGenNCasc VFollBias Gnd Vdd biassource
M1020 VFollBias VFollBias Gnd Gnd nmos L=6 W=24 AD='24*3+12' PD='24+12' AS='(24*3)+36' PS='24+12' M=1

.include biasSplitterOctave.sp
.include biasSplitterOctaveTerminate.sp

XbiasSplitterOctave_0 masterOut nb0 N2000 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctave_1 N2000 nb1  N2001 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctave_2 N2001 nb2  N2002 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctave_3 N2002 nb3  N2003 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctave_4 N2003 nb4  N2004 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctave_5 N2004 nb5  N2005 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctave_6 N2005 nb6  N2006 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctave_7 N2006 nb7  N2007 BiasGenNBias Gnd Vdd biasSplitterOctave
XbiasSplitterOctaveTerminate_1 N2007 nbTerm BiasGenNBias Gnd Vdd biasSplitterOctaveTerminate
