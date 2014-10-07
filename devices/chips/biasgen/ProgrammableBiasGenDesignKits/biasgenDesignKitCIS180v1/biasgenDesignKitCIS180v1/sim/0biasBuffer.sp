$ simulate biasbuffer circuit with bit patterns for configuration input
.options accurate=1 relitol=1e-6 gmin=1e-18 gmindc=1e-18 pivtol=1e-18 deftables=0 mosparasitics=1 numnt=500
.gridsize mos 256 256 128
.param vdd=1.8 ibias=10n ibb=3u
vdd AVdd18 gnd vdd
$vdvdd DVdd18 AVdd18 0
$vdgnd DGnd gnd 0
ibufbias bufBias gnd ibb 
iin splitterOutput gnd ibias pwl (0 0 1m ibias)
vbiasgennbias BiasGenNBias gnd .6
.vector b {b3 b2 b1 b0}
$ b0=enable, b1=n, b2=normalType, b3=normalCurrent
$vb b gnd bus ( {0h 1h 2h 3h 4h 5h 6h 7h 8h 9h ah bh ch dh eh fh} ) pw=1m on=vdd off=0
vb3 b3 gnd vdd
vb2 b2 gnd vdd
vb1 b1 gnd npselect
vb0 b0 gnd enabled
vnbout nBiasCurrent avdd18 0
vpbout pBiasCurrent gnd 0
vkick kickIn gnd bit ( {1 0} ) pw=1m on=100mV off=0 delay=0.5ms
.print tran bias b0 b1
.print dc i(vnbout)
.print dc i2(vpbout)

.param npselect=vdd enabled=vdd

.alter pbias
.param npselect=0

.alter disabled
.param enabled=0

