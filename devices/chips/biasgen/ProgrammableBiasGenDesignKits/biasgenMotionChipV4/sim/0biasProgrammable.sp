* simulates biasgenerator only
* $Id: 0biasgen.sp,v 1.2 2004/06/14 11:49:38 tobi Exp $

.param period=30ms nbits=24 rt=10ns

*.tran/powerup 1ms 0.9 start=0 $method=bdf
.tran/powerup 'period/3.1415926535' 'period*nbits*3' start=0


* Waveform probing commands
.acmodel {*}
.options accurate=1 gmin=1e-13 gmindc=1e-13 deftables=0 mosparasitics=1 numnt=500
*.gridsize mos 256 256 128

*include model files$
.include ..\setup\mod\ams_C35.md

*include spice file of your circuit$
.include biasProgrammable.sp

.param vdd=3.3

*power$
vdd Vdd Gnd vdd
vdvdd DVdd Vdd 0
vdgnd DGnd gnd 0
vb BiasGenNBias gnd .8

*input

im Vdd nb 1uA
Vphi phi gnd PULSE (0 vdd 0 'rt' 'rt' 'period/2' 'period')
Venb enb gnd PULSE (0 vdd 'period/4' 'rt' 'rt' 'period/100' 'period')
Vbit d gnd PULSE (0 vdd '(nbits+1)*period' 'rt' 'rt' '(nbits+1)*period' '2*(nbits+1)*period')

.print tran d out