* simulates biasgenerator
.param period=30ms nbiases=12 nbits=24 rt=10ns rx=100k
.tran/powerup 'period/3.1415926535' 'period*nbits*nbiases' start=0
.acmodel {*}
.options accurate=1 gmin=1e-13 gmindc=1e-13 deftables=0 mosparasitics=1 numnt=500
.include ..\setup\mod\ams_C35.md
.include biasgen.sp
.param vdd=3.3
.model RPOLYH r
vdd Vdd Gnd vdd
vdvdd DVdd Vdd 0
vdgnd DGnd gnd 0
$rx rx gnd 'rx'
vrx rinternal gnd 0
vngate ngate gnd 0
vpgate pgate vdd 0
VpowerDown powerDown gnd 0
Vphi phi gnd PULSE (0 vdd 0 'rt' 'rt' 'period/2' 'period')
Vlatch latch gnd PULSE (0 vdd 'period/4' 'rt' 'rt' 'period/100' 'period')
Vnlatch !latch gnd PULSE (vdd 0 'period/4' 'rt' 'rt' 'period/100' 'period')
Vin in gnd PULSE (0 vdd '(nbits+1)*period' 'rt' 'rt' '(nbits+1)*period' '2*(nbits+1)*period')
Vnin nin gnd PULSE (vdd 0 '(nbits+1)*period' 'rt' 'rt' '(nbits+1)*period' '2*(nbits+1)*period')
