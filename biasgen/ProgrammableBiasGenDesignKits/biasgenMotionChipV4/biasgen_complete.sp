* SPICE export from S-Edit 12.51 Thu Jul 26 10:08:05 2007
* Design:  biasgenMDC
* Cell:    biasgen_complete
* View:    view_1
* Export as: Top-level Cell
* Netlist port order: default
* Exclude .model : yes
* Exclude .end: yes
* Expand paths: yes
* Root path: C:\Documents and Settings\tobi\My Documents\~jAER-sourceForge\biasgen\ProgrammableBiasGenDesignKits\biasgenMotionChipV4\biasgenMDC
* Exclude global pins on subcircuits: no
* Export control property name: SPICE
* Wrap lines: yes (to 80 characters)

********* Simulation Settings - General section *********

*************** Subcircuits *****************
.subckt shiftVgenN shiftsourceN BiasBufferPBias Gnd VDD  
MP3_1 N_1 BiasBufferPBias VDD VDD MODP L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MN3_1 Gnd N_1 shiftsourceN Gnd MODN L=8u W=1u M=1 
+AD='1u*2u' PD='1u+2*2u' AS='1u*2u' PS='1u+2*2u' 
+NRD='1.25u/1u' NRS='1.25u/1u' 
MN3_2 shiftsourceN N_1 N_1 Gnd MODN L=0.35u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
.ends

.subckt shiftVgenP shiftsourceP BiasBufferNBias Gnd VDD  
MP3_2 shiftsourceP N_1 VDD VDD MODP L=8u W=1u M=1 
+AD='1u*2u' PD='1u+2*2u' AS='1u*2u' PS='1u+2*2u' 
+NRD='1.25u/1u' NRS='1.25u/1u'
MP3_3 N_1 N_1 shiftsourceP VDD MODP L=0.35u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MN3_3 Gnd BiasBufferNBias N_1 Gnd MODN L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
.ends

.subckt biasBufferN b in out Gnd VDD  
MP3_2 N_2 N_2 VDD VDD MODP L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_3 out N_2 VDD VDD MODP L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MN3_1 N_1 out out Gnd MODN L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_2 N_1 in N_2 Gnd MODN L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_3 Gnd b N_1 Gnd MODN L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
.ends

.subckt biasBufferP b in out Gnd VDD  
MP3_1 N_2 b VDD VDD MODP L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_2 N_1 in N_2 VDD MODP L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_3 out out N_2 VDD MODP L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MN3_1 Gnd N_1 out Gnd MODN L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_2 Gnd N_1 N_1 Gnd MODN L=.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
.ends

.subckt biasBuffers_lowCurrent nBias pBias powerDown shiftsourceN shiftsourceP splitterOutput 
+BiasBufferNBias BiasBufferPBias Gnd VDD  
MN3_1 shiftsourceN nBias splitterOutput Gnd MODN L=8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_2 shiftsourceN nBias N_1 Gnd MODN L=8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_3 nBias splitterOutput VDD Gnd MODN L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_4 Gnd powerdown pdb Gnd MODN L=0.8u W=5.75u M=1 
+AD='5.75u*2u' PD='5.75u+2*2u' AS='5.75u*2u' PS='5.75u+2*2u' 
+NRD='1.25u/5.75u' NRS='1.25u/5.75u' 
MN3_5 Gnd BiasBufferNBias nBias Gnd MODN L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_6 Gnd powerDown nBias Gnd MODN L=0.8u W=7.45u M=1 
+AD='7.45u*2u' PD='7.45u+2*2u' AS='7.45u*2u' PS='7.45u+2*2u' 
+NRD='1.25u/7.45u' NRS='1.25u/7.45u' 
MP3_1 N_1 pBias shiftsourceP VDD MODP L=8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_2 Gnd N_1 pBias VDD MODP L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_3 pBias BiasBufferPBias VDD VDD MODP L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_4 pdb powerdown VDD VDD MODP L=0.8u W=5.75u M=1 
+AD='5.75u*2u' PD='5.75u+2*2u' AS='5.75u*2u' PS='5.75u+2*2u' 
+NRD='1.25u/5.75u' NRS='1.25u/5.75u'
MP3_5 pBias pdb VDD VDD MODP L=0.8u W=7.45u M=1 
+AD='7.45u*2u' PD='7.45u+2*2u' AS='7.45u*2u' PS='7.45u+2*2u' 
+NRD='1.25u/7.45u' NRS='1.25u/7.45u'
.ends

.subckt biasLatch !latch !q d latch q dGnd dVDD  
MP4_1 !q inv1in dVDD dVDD MODP L=.4u W=.8u M=1 
+AD='.8u*2u' PD='.8u+2*2u' AS='.8u*2u' PS='.8u+2*2u' 
+NRD='1.25u/.8u' NRS='1.25u/.8u'
MN3_1 dGnd inv1in !q Gnd MODN L=.4u W=.8u M=1 
+AD='.8u*2u' PD='.8u+2*2u' AS='.8u*2u' PS='.8u+2*2u' 
+NRD='1.25u/.8u' NRS='1.25u/.8u' 
MP4_2 q !q dVDD dVDD MODP L=.4u W=.8u M=1 
+AD='.8u*2u' PD='.8u+2*2u' AS='.8u*2u' PS='.8u+2*2u' 
+NRD='1.25u/.8u' NRS='1.25u/.8u'
MN3_2 dGnd !q q Gnd MODN L=.4u W=.8u M=1 
+AD='.8u*2u' PD='.8u+2*2u' AS='.8u*2u' PS='.8u+2*2u' 
+NRD='1.25u/.8u' NRS='1.25u/.8u' 
MP4_3 q !latch inv1in dVDD MODP L=.4u W=.4u M=1 
+AD='.4u*2u' PD='.4u+2*2u' AS='.4u*2u' PS='.4u+2*2u' 
+NRD='1.25u/.4u' NRS='1.25u/.4u'
MN3_3 inv1in !latch d Gnd MODN L=.4u W=.4u M=1 
+AD='.4u*2u' PD='.4u+2*2u' AS='.4u*2u' PS='.4u+2*2u' 
+NRD='1.25u/.4u' NRS='1.25u/.4u' 
MP4_4 d latch inv1in dVDD MODP L=.4u W=.4u M=1 
+AD='.4u*2u' PD='.4u+2*2u' AS='.4u*2u' PS='.4u+2*2u' 
+NRD='1.25u/.4u' NRS='1.25u/.4u'
MN3_4 q latch inv1in Gnd MODN L=.4u W=.4u M=1 
+AD='.4u*2u' PD='.4u+2*2u' AS='.4u*2u' PS='.4u+2*2u' 
+NRD='1.25u/.4u' NRS='1.25u/.4u' 
.ends

.subckt biasShiftRegister OR clk in nin nout nq out q dGnd dVDD  
MP4_10 OR nq dVDD dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
MN3_1 N_1 clk nin Gnd MODN L=2.2u W=0.8u M=1 
+AD='0.8u*2u' PD='0.8u+2*2u' AS='0.8u*2u' PS='0.8u+2*2u' 
+NRD='1.25u/0.8u' NRS='1.25u/0.8u' 
MP4_1 N_4 clk dVDD dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
MN3_2 in clk N_2 Gnd MODN L=2.2u W=0.8u M=1 
+AD='0.8u*2u' PD='0.8u+2*2u' AS='0.8u*2u' PS='0.8u+2*2u' 
+NRD='1.25u/0.8u' NRS='1.25u/0.8u' 
MP4_2 N_1 N_2 N_4 dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
MN3_3 dGnd N_1 N_2 Gnd MODN L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u' 
MP4_3 N_2 N_1 N_4 dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
MN3_4 dGnd N_2 N_1 Gnd MODN L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u' 
MP4_4 N_2 clk out dVDD MODP L=2.2u W=0.8u M=1 
+AD='0.8u*2u' PD='0.8u+2*2u' AS='0.8u*2u' PS='0.8u+2*2u' 
+NRD='1.25u/0.8u' NRS='1.25u/0.8u'
MN3_5 dGnd clk N_3 Gnd MODN L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u' 
MP4_5 N_1 clk nout dVDD MODP L=2.2u W=0.8u M=1 
+AD='0.8u*2u' PD='0.8u+2*2u' AS='0.8u*2u' PS='0.8u+2*2u' 
+NRD='1.25u/0.8u' NRS='1.25u/0.8u'
MN3_6 N_3 nout out Gnd MODN L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u' 
MP4_6 out nout dVDD dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
MN3_7 N_3 out nout Gnd MODN L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u' 
MP4_7 nout out dVDD dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
MN3_8 dGnd out nq Gnd MODN L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u' 
MP4_8 nq out dVDD dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
MN3_9 dGnd nout q Gnd MODN L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u' 
MP4_9 q nout dVDD dVDD MODP L=0.35u W=1.05u M=1 
+AD='1.05u*2u' PD='1.05u+2*2u' AS='1.05u*2u' PS='1.05u+2*2u' 
+NRD='1.25u/1.05u' NRS='1.25u/1.05u'
.ends

.subckt biasSplitterOctave !sel next out prev sel BiasGenNBias Gnd VDD  
Mreadout out sel N_1 Gnd MODN L=.4u W=1.2u M=1 
+AD='1.2u*2u' PD='1.2u+2*2u' AS='1.2u*2u' PS='1.2u+2*2u' 
+NRD='1.25u/1.2u' NRS='1.25u/1.2u' 
Mpass next BiasGenNBias prev VDD MODP L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u'
MP3_1 N_2 BiasGenNBias prev VDD MODP L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u'
MP3_2 N_1 BiasGenNBias N_2 VDD MODP L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u'
MN3_1 Gnd !sel N_1 Gnd MODN L=.4u W=1.2u M=1 
+AD='1.2u*2u' PD='1.2u+2*2u' AS='1.2u*2u' PS='1.2u+2*2u' 
+NRD='1.25u/1.2u' NRS='1.25u/1.2u' 
.ends

.subckt biasSplitterOctaveTerminate left BiasGenNBias Gnd VDD  
MP3_1 Gnd BiasGenNBias left VDD MODP L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u'
.ends

.subckt masterbias nDrain nGate pDrain pGate powerDown rinternal rx BiasGenNBias 
+BiasGenPBias Gnd VDD pMirrorCopy  
RRPOLYH_1 rinternal rx  RPOLYH R=46k
Mmoscapstopstartup VDD pMirrorCopy VDD Gnd MODN L=12.66u W=3.9u M=1 
+AD='3.9u*2u' PD='3.9u+2*2u' AS='3.9u*2u' PS='3.9u+2*2u' 
+NRD='1.25u/3.9u' NRS='1.25u/3.9u' 
CcapPoly_1 Gnd BiasGenNBias 774fF M=35
Mnbias Gnd BiasGenNBias BiasGenNBias Gnd MODN L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u' 
Mmoscapkickholdoff powerDown kickgate powerDown Gnd MODN L=21.3u W=9.7u M=1 
+AD='9.7u*2u' PD='9.7u+2*2u' AS='9.7u*2u' PS='9.7u+2*2u' 
+NRD='1.25u/9.7u' NRS='1.25u/9.7u' 
Mkickshutoff kickgate pMirrorCopy VDD VDD MODP L=1.2u W=1.2u M=1 
+AD='1.2u*2u' PD='1.2u+2*2u' AS='1.2u*2u' PS='1.2u+2*2u' 
+NRD='1.25u/1.2u' NRS='1.25u/1.2u'
MP3_1 pDrain pGate VDD VDD MODP L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u'
MP3_5 BiasGenPBias BiasGenPBias VDD VDD MODP L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u'
Mnres rx BiasGenNBias pMirrorCopy Gnd MODN L=2.4u W=24u M=9 
+AD='24u*2u' PD='24u+2*2u' AS='24u*2u' PS='24u+2*2u' 
+NRD='1.25u/24u' NRS='1.25u/24u' 
MN3_1 Gnd nGate nDrain Gnd MODN L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u' 
MN3_2 Gnd BiasGenNBias BiasGenPBias Gnd MODN L=2.4u W=4.8u M=1 
+AD='4.8u*2u' PD='4.8u+2*2u' AS='4.8u*2u' PS='4.8u+2*2u' 
+NRD='1.25u/4.8u' NRS='1.25u/4.8u' 
Mpmirrorout BiasGenNBias pMirrorCopy VDD VDD MODP L=18.2u W=15.3u M=1 
+AD='15.3u*2u' PD='15.3u+2*2u' AS='15.3u*2u' PS='15.3u+2*2u' 
+NRD='1.25u/15.3u' NRS='1.25u/15.3u'
Mpmirrorin pMirrorCopy pMirrorCopy VDD VDD MODP L=18.2u W=15.3u M=1 
+AD='15.3u*2u' PD='15.3u+2*2u' AS='15.3u*2u' PS='15.3u+2*2u' 
+NRD='1.25u/15.3u' NRS='1.25u/15.3u'
Mpowerdown Gnd powerDown BiasGenNBias Gnd MODN L=1.2u W=1.2u M=1 
+AD='1.2u*2u' PD='1.2u+2*2u' AS='1.2u*2u' PS='1.2u+2*2u' 
+NRD='1.25u/1.2u' NRS='1.25u/1.2u' 
.nodeset BiasGenNBias=
Mkick BiasGenNBias kickgate VDD VDD MODP L=1.2u W=1.2u M=1 
+AD='1.2u*2u' PD='1.2u+2*2u' AS='1.2u*2u' PS='1.2u+2*2u' 
+NRD='1.25u/1.2u' NRS='1.25u/1.2u'
.ends

.subckt biasBit !d !latch !q d latch next or out phi prev q sel BiasGenNBias Gnd 
+VDD dGnd dVDD  
.nodeset q=
XscanSr_1 or phi d !d !q !srOut q srOut dGnd dVDD biasShiftRegister  
.nodeset !q=
XbiasLatch_1 !latch !sel srOut latch sel dGnd dVDD biasLatch  
XbiasSplitterOctave_1 !sel next out prev sel BiasGenNBias Gnd VDD biasSplitterOctave 
.nodeset d=
.nodeset !d=
.ends

.subckt biasBufferCas nBias pBias powerDown splitterOutput BiasBufferNBias BiasBufferPBias 
+Gnd VDD  
MN3_1 N_2 nBias splitterOutput Gnd MODN L=3u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_2 N_3 nBias N_1 Gnd MODN L=3u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_3 Gnd N_3 N_3 Gnd MODN L=3u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_4 Gnd N_3 N_2 Gnd MODN L=3u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_5 Gnd powerdown pdb Gnd MODN L=0.8u W=5.75u M=1 
+AD='5.75u*2u' PD='5.75u+2*2u' AS='5.75u*2u' PS='5.75u+2*2u' 
+NRD='1.25u/5.75u' NRS='1.25u/5.75u' 
MN3_6 Gnd powerDown nBias Gnd MODN L=0.8u W=7.45u M=1 
+AD='7.45u*2u' PD='7.45u+2*2u' AS='7.45u*2u' PS='7.45u+2*2u' 
+NRD='1.25u/7.45u' NRS='1.25u/7.45u' 
XbiasBufferP_1 BiasBufferPBias splitterOutput nBias Gnd VDD biasBufferP  
XbiasBufferN_1 BiasBufferNBias N_1 pBias Gnd VDD biasBufferN  
MP3_1 N_1 pBias N_4 VDD MODP L=3u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_2 N_4 N_4 VDD VDD MODP L=3u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_3 pdb powerdown VDD VDD MODP L=0.8u W=5.75u M=1 
+AD='5.75u*2u' PD='5.75u+2*2u' AS='5.75u*2u' PS='5.75u+2*2u' 
+NRD='1.25u/5.75u' NRS='1.25u/5.75u'
MP3_4 pBias pdb VDD VDD MODP L=0.8u W=7.45u M=1 
+AD='7.45u*2u' PD='7.45u+2*2u' AS='7.45u*2u' PS='7.45u+2*2u' 
+NRD='1.25u/7.45u' NRS='1.25u/7.45u'
.ends

.subckt biasBuffers_pd nBias pBias powerDown splitterOutput BiasBufferNBias BiasBufferPBias 
+Gnd VDD  
MN3_1 Gnd nBias splitterOutput Gnd MODN L=8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_2 Gnd nBias N_1 Gnd MODN L=8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_3 Gnd powerDown nBias Gnd MODN L=0.8u W=7.45u M=1 
+AD='7.45u*2u' PD='7.45u+2*2u' AS='7.45u*2u' PS='7.45u+2*2u' 
+NRD='1.25u/7.45u' NRS='1.25u/7.45u' 
MN3_4 Gnd powerdown pdb Gnd MODN L=0.8u W=5.75u M=1 
+AD='5.75u*2u' PD='5.75u+2*2u' AS='5.75u*2u' PS='5.75u+2*2u' 
+NRD='1.25u/5.75u' NRS='1.25u/5.75u' 
XbiasBufferP_1 BiasBufferPBias splitterOutput nBias Gnd VDD biasBufferP  
XbiasBufferN_1 BiasBufferNBias N_1 pBias Gnd VDD biasBufferN  
MP3_1 N_1 pBias VDD VDD MODP L=8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
MP3_2 pdb powerdown VDD VDD MODP L=0.8u W=5.75u M=1 
+AD='5.75u*2u' PD='5.75u+2*2u' AS='5.75u*2u' PS='5.75u+2*2u' 
+NRD='1.25u/5.75u' NRS='1.25u/5.75u'
MP3_3 pBias pdb VDD VDD MODP L=0.8u W=7.45u M=1 
+AD='7.45u*2u' PD='7.45u+2*2u' AS='7.45u*2u' PS='7.45u+2*2u' 
+NRD='1.25u/7.45u' NRS='1.25u/7.45u'
.ends

.subckt biasSpBit !d !latch !q !sel d latch next or out phi prev q sel dGnd dVDD 
.nodeset q=
XscanSr_1 or phi d !d !q !srOut q srOut dGnd dVDD biasShiftRegister  
.nodeset !q=
XbiasLatch_1 !latch !sel srOut latch sel dGnd dVDD biasLatch  
.nodeset d=
.nodeset !d=
.ends

.subckt biasBuffersSplitter !d !latchenb !q bit0 bit1 bit2 bit3 d latchenb phi q 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy  
MN3_1 Gnd BiasBufferNBias BiasBufferNBias Gnd MODN L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
MN3_2 Gnd BiasBufferNBias BiasBufferPBias Gnd MODN L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u' 
XbiasSpBit_1 N_9 !latchenb N_26 bit3 N_12 latchenb Im N_5 N_27 phi N_28 N_29 N_30 
+dGnd dVDD biasSpBit  
MmasterCopy Im pMirrorCopy VDD VDD MODP L=18.2u W=15.3u M=1 
+AD='15.3u*2u' PD='15.3u+2*2u' AS='15.3u*2u' PS='15.3u+2*2u' 
+NRD='1.25u/15.3u' NRS='1.25u/15.3u'
XbiasSpBit_2 N_26 !latchenb N_31 bit2 N_29 latchenb N_28 N_5 N_32 phi N_33 N_34 
+N_35 dGnd dVDD biasSpBit  
XbiasSpBit_3 N_31 !latchenb N_36 bit1 N_34 latchenb N_33 N_5 N_37 phi N_38 N_39 
+N_40 dGnd dVDD biasSpBit  
XbiasSpBit_4 N_36 !latchenb !q bit0 N_39 latchenb N_38 N_5 N_41 phi N_42 q N_43 
+dGnd dVDD biasSpBit  
XbiasSplitterOctaveTerminate_1 N_25 BiasGenNBias Gnd VDD biasSplitterOctaveTerminate 
XbiasBit_4 N_8 !latchenb N_9 N_10 latchenb N_11 N_5 BiasBufferNBias phi Im N_12 
+b23 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_5 N_13 !latchenb N_8 N_14 latchenb N_15 N_5 BiasBufferNBias phi N_11 N_10 
+b22 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_6 N_16 !latchenb N_13 N_17 latchenb N_18 N_5 BiasBufferNBias phi N_15 N_14 
+b21 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_7 N_19 !latchenb N_16 N_20 latchenb N_21 N_5 BiasBufferNBias phi N_18 N_17 
+b20 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_8 N_22 !latchenb N_19 N_23 latchenb N_24 N_5 BiasBufferNBias phi N_21 N_20 
+b19 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_10 N_1 !latchenb N_2 N_3 latchenb N_4 N_5 BiasBufferNBias phi N_6 N_7 b17 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_9 N_2 !latchenb N_22 N_7 latchenb N_6 N_5 BiasBufferNBias phi N_24 N_23 
+b18 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_11 !d !latchenb N_1 d latchenb N_25 N_5 BiasBufferNBias phi N_4 N_3 b16 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
MP3_1 BiasBufferPBias BiasBufferPBias VDD VDD MODP L=0.8u W=8u M=1 
+AD='8u*2u' PD='8u+2*2u' AS='8u*2u' PS='8u+2*2u' 
+NRD='1.25u/8u' NRS='1.25u/8u'
.ends

.subckt biasProgrammable !d !latchenb !q d latchenb nBias pBias pd phi q BiasBufferNBias 
+BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy  
XbiasBit_10 N_1 !latchenb N_2 N_3 latchenb N_4 N_5 splitterOutput phi N_6 N_7 b17 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_11 N_8 !latchenb N_1 N_9 latchenb N_10 N_5 splitterOutput phi N_4 N_3 b16 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_12 N_11 !latchenb N_8 N_12 latchenb N_13 N_5 splitterOutput phi N_10 N_9 
+b15 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_13 N_14 !latchenb N_11 N_15 latchenb N_16 N_5 splitterOutput phi N_13 N_12 
+b14 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_14 N_17 !latchenb N_14 N_18 latchenb N_19 N_5 splitterOutput phi N_16 N_15 
+b13 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_15 N_20 !latchenb N_17 N_21 latchenb N_22 N_5 splitterOutput phi N_19 N_18 
+b12 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
MmasterCopy Im pMirrorCopy VDD VDD MODP L=18.2u W=15.3u M=1 
+AD='15.3u*2u' PD='15.3u+2*2u' AS='15.3u*2u' PS='15.3u+2*2u' 
+NRD='1.25u/15.3u' NRS='1.25u/15.3u'
XbiasBit_16 N_23 !latchenb N_20 N_24 latchenb N_25 N_5 splitterOutput phi N_22 N_21 
+b11 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_17 N_26 !latchenb N_23 N_27 latchenb N_28 N_5 splitterOutput phi N_25 N_24 
+b10 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_18 N_29 !latchenb N_26 N_30 latchenb N_31 N_5 splitterOutput phi N_28 N_27 
+b9 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_19 N_32 !latchenb N_29 N_33 latchenb N_34 N_5 splitterOutput phi N_31 N_30 
+b8 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_4 N_56 !latchenb !q N_57 latchenb N_58 N_5 splitterOutput phi Im q b23 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_5 N_59 !latchenb N_56 N_60 latchenb N_61 N_5 splitterOutput phi N_58 N_57 
+b22 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_6 N_62 !latchenb N_59 N_63 latchenb N_64 N_5 splitterOutput phi N_61 N_60 
+b21 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_7 N_65 !latchenb N_62 N_66 latchenb N_67 N_5 splitterOutput phi N_64 N_63 
+b20 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_8 N_68 !latchenb N_65 N_69 latchenb N_70 N_5 splitterOutput phi N_67 N_66 
+b19 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBuffers_pd_1 nBias pBias pd splitterOutput BiasBufferNBias BiasBufferPBias 
+Gnd VDD biasBuffers_pd  
XbiasBit_9 N_2 !latchenb N_68 N_7 latchenb N_6 N_5 splitterOutput phi N_70 N_69 
+b18 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasSplitterOctaveTerminate_1 N_71 BiasGenNBias Gnd VDD biasSplitterOctaveTerminate 
XbiasBit_20 N_35 !latchenb N_32 N_36 latchenb N_37 N_5 splitterOutput phi N_34 N_33 
+b7 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_21 N_38 !latchenb N_35 N_39 latchenb N_40 N_5 splitterOutput phi N_37 N_36 
+b6 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_22 N_41 !latchenb N_38 N_42 latchenb N_43 N_5 splitterOutput phi N_40 N_39 
+b5 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_23 N_44 !latchenb N_41 N_45 latchenb N_46 N_5 splitterOutput phi N_43 N_42 
+b4 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_24 N_47 !latchenb N_44 N_48 latchenb N_49 N_5 splitterOutput phi N_46 N_45 
+b3 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_25 N_50 !latchenb N_47 N_51 latchenb N_52 N_5 splitterOutput phi N_49 N_48 
+b2 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_26 N_53 !latchenb N_50 N_54 latchenb N_55 N_5 splitterOutput phi N_52 N_51 
+b1 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_27 !d !latchenb N_53 d latchenb N_71 N_5 splitterOutput phi N_55 N_54 b0 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
.ends

.subckt biasProgrammable_lowcurrent !d !latchenb !q d latchenb nBias pBias pd phi 
+q shiftsourceN shiftsourceP BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD 
+dGnd dVDD pMirrorCopy  
XbiasBuffers_lowCurrent_1 nBias pBias pd shiftsourceN shiftsourceP splitterOutput 
+BiasBufferNBias BiasBufferPBias Gnd VDD biasBuffers_lowCurrent  
XbiasBit_10 N_1 !latchenb N_2 N_3 latchenb N_4 N_5 splitterOutput phi N_6 N_7 b17 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_11 N_8 !latchenb N_1 N_9 latchenb N_10 N_5 splitterOutput phi N_4 N_3 b16 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_12 N_11 !latchenb N_8 N_12 latchenb N_13 N_5 splitterOutput phi N_10 N_9 
+b15 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_13 N_14 !latchenb N_11 N_15 latchenb N_16 N_5 splitterOutput phi N_13 N_12 
+b14 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_14 N_17 !latchenb N_14 N_18 latchenb N_19 N_5 splitterOutput phi N_16 N_15 
+b13 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_15 N_20 !latchenb N_17 N_21 latchenb N_22 N_5 splitterOutput phi N_19 N_18 
+b12 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
MmasterCopy Im pMirrorCopy VDD VDD MODP L=18.2u W=15.3u M=1 
+AD='15.3u*2u' PD='15.3u+2*2u' AS='15.3u*2u' PS='15.3u+2*2u' 
+NRD='1.25u/15.3u' NRS='1.25u/15.3u'
XbiasBit_16 N_23 !latchenb N_20 N_24 latchenb N_25 N_5 splitterOutput phi N_22 N_21 
+b11 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_17 N_26 !latchenb N_23 N_27 latchenb N_28 N_5 splitterOutput phi N_25 N_24 
+b10 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_18 N_29 !latchenb N_26 N_30 latchenb N_31 N_5 splitterOutput phi N_28 N_27 
+b9 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_19 N_32 !latchenb N_29 N_33 latchenb N_34 N_5 splitterOutput phi N_31 N_30 
+b8 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_4 N_56 !latchenb !q N_57 latchenb N_58 N_5 splitterOutput phi Im q b23 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_5 N_59 !latchenb N_56 N_60 latchenb N_61 N_5 splitterOutput phi N_58 N_57 
+b22 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_6 N_62 !latchenb N_59 N_63 latchenb N_64 N_5 splitterOutput phi N_61 N_60 
+b21 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_7 N_65 !latchenb N_62 N_66 latchenb N_67 N_5 splitterOutput phi N_64 N_63 
+b20 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_8 N_68 !latchenb N_65 N_69 latchenb N_70 N_5 splitterOutput phi N_67 N_66 
+b19 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_9 N_2 !latchenb N_68 N_7 latchenb N_6 N_5 splitterOutput phi N_70 N_69 
+b18 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasSplitterOctaveTerminate_1 N_71 BiasGenNBias Gnd VDD biasSplitterOctaveTerminate 
XbiasBit_20 N_35 !latchenb N_32 N_36 latchenb N_37 N_5 splitterOutput phi N_34 N_33 
+b7 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_21 N_38 !latchenb N_35 N_39 latchenb N_40 N_5 splitterOutput phi N_37 N_36 
+b6 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_22 N_41 !latchenb N_38 N_42 latchenb N_43 N_5 splitterOutput phi N_40 N_39 
+b5 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_23 N_44 !latchenb N_41 N_45 latchenb N_46 N_5 splitterOutput phi N_43 N_42 
+b4 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_24 N_47 !latchenb N_44 N_48 latchenb N_49 N_5 splitterOutput phi N_46 N_45 
+b3 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_25 N_50 !latchenb N_47 N_51 latchenb N_52 N_5 splitterOutput phi N_49 N_48 
+b2 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_26 N_53 !latchenb N_50 N_54 latchenb N_55 N_5 splitterOutput phi N_52 N_51 
+b1 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_27 !d !latchenb N_53 d latchenb N_71 N_5 splitterOutput phi N_55 N_54 b0 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
.ends

.subckt biasProgrammableCas !d !latchenb !q d latchenb nBias pBias pd phi q BiasBufferNBias 
+BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy  
XbiasBit_30 N_15 !latchenb N_18 N_17 latchenb N_16 N_3 splitterOutput phi N_19 N_20 
+b5 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_31 N_18 !latchenb N_21 N_20 latchenb N_19 N_3 splitterOutput phi N_22 N_23 
+b6 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_32 N_21 !latchenb N_24 N_23 latchenb N_22 N_3 splitterOutput phi N_25 N_26 
+b7 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_33 N_24 !latchenb N_27 N_26 latchenb N_25 N_3 splitterOutput phi N_28 N_29 
+b8 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_34 N_27 !latchenb N_30 N_29 latchenb N_28 N_3 splitterOutput phi N_31 N_32 
+b9 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_35 N_30 !latchenb N_33 N_32 latchenb N_31 N_3 splitterOutput phi N_34 N_35 
+b10 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_36 N_33 !latchenb N_36 N_35 latchenb N_34 N_3 splitterOutput phi N_37 N_38 
+b11 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_37 N_36 !latchenb N_39 N_38 latchenb N_37 N_3 splitterOutput phi N_40 N_41 
+b12 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_38 N_39 !latchenb N_42 N_41 latchenb N_40 N_3 splitterOutput phi N_43 N_44 
+b13 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_39 N_42 !latchenb N_45 N_44 latchenb N_43 N_3 splitterOutput phi N_46 N_47 
+b14 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
MP3_1 Im pMirrorCopy VDD VDD MODP L=18.2u W=15.3u M=1 
+AD='15.3u*2u' PD='15.3u+2*2u' AS='15.3u*2u' PS='15.3u+2*2u' 
+NRD='1.25u/15.3u' NRS='1.25u/15.3u'
XbiasBit_1 !d !latchenb N_1 d latchenb N_2 N_3 splitterOutput phi N_4 N_5 b0 BiasGenNBias 
+Gnd VDD dGnd dVDD biasBit  
XbiasBit_2 N_1 !latchenb N_6 N_5 latchenb N_4 N_3 splitterOutput phi N_7 N_8 b1 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_3 N_6 !latchenb N_9 N_8 latchenb N_7 N_3 splitterOutput phi N_12 N_11 b2 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasSplitterOctaveTerminate_2 N_2 BiasGenNBias Gnd VDD biasSplitterOctaveTerminate 
XbiasBit_40 N_45 !latchenb N_48 N_47 latchenb N_46 N_3 splitterOutput phi N_49 N_50 
+b15 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_41 N_48 !latchenb N_51 N_50 latchenb N_49 N_3 splitterOutput phi N_52 N_53 
+b16 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_42 N_51 !latchenb N_54 N_53 latchenb N_52 N_3 splitterOutput phi N_55 N_56 
+b17 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_43 N_54 !latchenb N_57 N_56 latchenb N_55 N_3 splitterOutput phi N_58 N_59 
+b18 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_44 N_57 !latchenb N_60 N_59 latchenb N_58 N_3 splitterOutput phi N_61 N_62 
+b19 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBufferCas_1 nBias pBias pd splitterOutput BiasBufferNBias BiasBufferPBias Gnd 
+VDD biasBufferCas  
XbiasBit_45 N_60 !latchenb N_63 N_62 latchenb N_61 N_3 splitterOutput phi N_64 N_65 
+b20 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_46 N_63 !latchenb N_66 N_65 latchenb N_64 N_3 splitterOutput phi N_67 N_68 
+b21 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_47 N_66 !latchenb N_69 N_68 latchenb N_67 N_3 splitterOutput phi N_70 N_71 
+b22 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_48 N_69 !latchenb !q N_71 latchenb N_70 N_3 splitterOutput phi Im q b23 
+BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_28 N_9 !latchenb N_10 N_11 latchenb N_12 N_3 splitterOutput phi N_13 N_14 
+b3 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
XbiasBit_29 N_10 !latchenb N_15 N_14 latchenb N_13 N_3 splitterOutput phi N_16 N_17 
+b4 BiasGenNBias Gnd VDD dGnd dVDD biasBit  
.ends


********* Simulation Settings - Parameters and SPICE Options *********

XbiasProgrammable_10 N_18 !latch N_19 N_20 latch N_21 biasVotabiasp powerDown phi 
+N_22 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XbiasProgrammable_11 N_23 !latch N_24 N_25 latch biasVpdw N_26 powerDown phi N_27 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_12 N_28 !latch N_23 N_29 latch N_30 biasVthr powerDown phi N_25 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_13 N_19 !latch N_28 N_22 latch biasVcurlim N_31 powerDown phi 
+N_29 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XbiasProgrammable_14 N_32 !latch N_10 N_33 latch bias18 N_34 powerDown phi N_11 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_15 N_35 !latch N_32 N_36 latch biasFollowbias N_37 powerDown phi 
+N_33 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XshiftVgenP_1 shiftsourceP BiasBufferNBias Gnd VDD shiftVgenP  
XbiasProgrammable_16 N_38 !latch N_35 N_39 latch N_40 biasVprbuff powerDown phi 
+N_36 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XbiasProgrammable_17 N_41 !latch N_38 N_42 latch N_43 biasVconfleak powerDown phi 
+N_39 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XshiftVgenN_1 shiftsourceN BiasBufferPBias Gnd VDD shiftVgenN  
XbiasProgrammable_lowcurrent2_1 N_1 !latch N_13 N_2 latch biasVelleak N_64 powerDown 
+phi N_15 shiftsourceN shiftsourceP BiasBufferNBias BiasBufferPBias BiasGenNBias 
+Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable_lowcurrent  
XbiasProgrammable_1 N_13 !latch N_14 N_15 latch biasVlmcfb N_16 powerDown phi N_17 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_2 N_44 !latch N_45 N_46 latch biasVwiden N_47 powerDown phi N_48 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_3 N_14 !latch N_49 N_17 latch biasVprfb N_50 powerDown phi N_51 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasBuffersSplitter_1 nin !latch N_1 bit0 bit1 bit2 bit3 in latch phi N_2 BiasBufferNBias 
+BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasBuffersSplitter 
XbiasProgrammable_4 N_49 !latch N_52 N_51 latch biasVrefminbias N_53 powerDown phi 
+N_54 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XbiasProgrammable_5 N_52 !latch N_44 N_54 latch N_55 biasVADCbias powerDown phi 
+N_46 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XbiasProgrammable_6 N_45 !latch N_56 N_48 latch N_57 biasVwidep powerDown phi N_58 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_7 N_24 !latch N_41 N_27 latch biasVleak N_59 powerDown phi N_42 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_8 N_56 !latch N_60 N_58 latch N_61 biasVprbias powerDown phi N_62 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammable 
XbiasProgrammable_9 N_60 !latch N_18 N_62 latch N_63 biasVprlmcbias powerDown phi 
+N_20 BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy 
+biasProgrammable  
XbiasProgrammableCas_1 N_3 !latch N_4 N_5 latch N_6 biasVthresh1 powerDown phi N_7 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammableCas 
XbiasProgrammableCas_2 N_4 !latch N_8 N_7 latch N_9 biasVthresh2 powerDown phi out 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammableCas 
XbiasProgrammableCas_3 N_10 !latch N_3 N_11 latch biasVcas N_12 powerDown phi N_5 
+BiasBufferNBias BiasBufferPBias BiasGenNBias Gnd VDD dGnd dVDD pMirrorCopy biasProgrammableCas 
Xmasterbias_1 nDrain nGate pDrain pGate powerDown rinternal rx BiasGenNBias BiasGenPBias 
+Gnd VDD pMirrorCopy masterbias  

********* Simulation Settings - Analysis section *********

********* Simulation Settings - Additional SPICE commands *********


