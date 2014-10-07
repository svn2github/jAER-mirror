* SPICE export from S-Edit 12.51 Wed Jul 25 22:23:29 2007
* Design:  biasgen-scmos-subm
* Cell:    biasSplitterOctaveTerminate
* View:    view_1
* Export as: Subcircuit definition
* Netlist port order: default
* Exclude .model : yes
* Exclude .end: yes
* Expand paths: yes
* Root path: C:\Documents and Settings\tobi\My Documents\~jAER-sourceForge\biasgen\FixedBiasGenDesignKit\biasgen-scmos-subm
* Exclude global pins on subcircuits: no
* Export control property name: SPICE
* Wrap lines: yes (to 80 characters)

*************** Subcircuits *****************
.subckt biasSplitterOctaveTerminate left out BiasGenNBias Gnd Vdd  
Mreadout out out Gnd Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
MP3_8  N_1 BiasGenNBias left Vdd pmos L=12 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
Mterm  out BiasGenNBias N_1 Vdd pmos L=12 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
.ends



