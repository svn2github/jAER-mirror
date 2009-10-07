$ additional commands for biasgen simulation
.param vdd=1.8 period=1us nbits=32 rt=10ns nLoads=3
.include ourModels.md
vdd AVdd18 Gnd vdd
vdvdd DVdd18 AVdd18 0
vdgnd DGnd gnd 0
vpd biasPowerDown gnd 0
vrint rInternal gnd 0
vngate nGate 0 0
vndrain nDrain 0 0
vpgate pGate AVdd18 0
vpdrain pDrain AVdd18 0
Vphi biasClock gnd PULSE (0 vdd 0 'rt' 'rt' 'period/2' 'period')
Venb biasLatch gnd dc 0 $ BIT ({ 31(1)  0  } pw=period rt=1n ft=1n on=vdd off=0)
Vbit biasBitIn gnd dc 0 BIT  ({ 32(0) 32(1) } pw=period rt=1n ft=1n on=vdd off=0)


