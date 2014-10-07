* SPICE export from S-Edit 12.51 Wed Jul 25 22:23:23 2007
* Design:  biasgen-scmos-subm
* Cell:    biasSplitterOctave
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
.subckt biasSplitterOctave left out right BiasGenNBias Gnd Vdd  
Mreadout out out Gnd Gnd nmos L=6 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
Mtransverse1  N_1 BiasGenNBias right Vdd pmos L=12 W=24 AD='(24*3)+36' PD='24+6+6' 
+AS='(24*3)+36' PS='24+6+6' M=1
Mpass  right BiasGenNBias left Vdd pmos L=12 W=24 AD='(24*3)+36' PD='24+6+6' AS='(24*3)+36' 
+PS='24+6+6' M=1
Mtransverse2  out BiasGenNBias N_1 Vdd pmos L=12 W=24 AD='(24*3)+36' PD='24+6+6' 
+AS='(24*3)+36' PS='24+6+6' M=1
.ends



