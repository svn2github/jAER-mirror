* test biasgen circuit
* This is part of biasgen, a compiler of reference currents. (C) 2003 T. Delbruck
* $Id: 0biasgen.sp,v 1.2 2004/05/31 04:37:33 tobi Exp $
* See bottom of file for log of CVS commits.

* don't forget to set rx and remember that this simulation assumes an external 
* compensation capacitor is hooked up to BiasGenNBias

* here set 
* rx to value given by compiler in biasgen-log.txt. 
* vdd to power supply voltage 
* ccomp to value of compenstation on BiasgenNBias
.param rx=1.3e6 vdd=5 ccomp=100pF


* don't forget to scale the lambda to your process dimensions! e.g. "scale=0.8u" for 1.6u process.
.options scale=0.8u gmin=1e-14 gmindc=1e-14 reltol=1e-6 abstol=1e-14 deftables=0 mosparasitics=1
$+ poweruplen=3m numnd=1200 numnt=6

$.gridsize mos 256 256 128


* include your transistor models for nmos1 and pmos1 here
.include ml49_15.md

.acmodel {*}		$ .acmodel doesn't work for powerup .tran simulations

* the exported schematic from schematic "biasgen-scmos-subm.sdb" cell "biasgen"
.include biasgen-lvs.sp
.include biassource.sp

* the compiled print statements written by the biasgen l-edit macro
.include biasgen-print.sp

* power supply
*vdd Vdd Gnd vdd
* vdd stays up, then drops to vdd/2, then up to 2*vdd
vdd vdd gnd dc vdd  $ PWL ((0 vdd 10m vdd 20m 'vdd/2' 30m 'vdd*2')

* external resistor
rx rx gnd rx

* the assumed external parasitic capacitance on rx node
* the large this is, the more unstable
cx rx gnd 10p

* external compensation on nbias node -- otherwise could oscillate
ccomp BiasGenNBias gnd ccomp

* tests powerDown capability by powering down and then back up
vpower powerDown gnd PULSE (0 vdd 1ms 100u 100u 2ms 100m)

* to startup DC operating point correctly
.nodeset BiasGenNBias=0.7 BiasGenNCasc=1.8 $ Xmasterbias.pMirrorGate='vdd-1' Xmasterbias.kickgate='vdd/2'

.print tran v(powerDown) v(vdd)

* do transient, operating point, and dc analysis
.tran/powerup 1m 30m 
.op
.dc lin param vdd 1.5 7 .1

.temp 0 70

* $Log: 0biasgen.sp,v $
* Revision 1.2  2004/05/31 04:37:33  tobi
* updated to include two temperatures and biasgen from tmpdiff10.
*
* Revision 1.1  2004/05/16 15:43:46  tobi
* split processes into subm sub-deep, and ams035
* moved simulations into separate dir
*
* Revision 1.4  2003/09/21 18:38:47  tobi
* added power control simulation
*
* Revision 1.3  2003/08/09 15:39:15  tobi
* added license to schematic and to spice testbenches
*
* Revision 1.2  2003/07/23 14:59:22  tobi
* LVS now ok, updated docs quite a bit.
*
* Revision 1.1  2003/07/21 15:42:47  tobi
* almost working, working on spice now.
*