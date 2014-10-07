* simulates masterbias
.param vdd=3.3 period=30ms nbits=24 rt=10ns
.tran/powerup 'period/3.1415926535' 'period*nbits*3' start=0
.acmodel {*}
.options accurate=1 gmin=1e-13 gmindc=1e-13 deftables=0 mosparasitics=1 numnt=500
.include ..\setup\mod\ams_C35.md
.include masterbias.sp
.param vdd=3.3
vdd Vdd Gnd vdd
.model RPOLYH r
vrx rinternal gnd 0
VpowerDown powerDown gnd 0
vngate ngate BiasGenNBias 0
vndrain ndrain vdd 0
vpgate pgate BiasGenPBias 0
vpdrain pdrain gnd 0
.dc lin param vdd 5 1 -.1
.print dc is(Mnbias) i(vndrain) i(vpdrain)