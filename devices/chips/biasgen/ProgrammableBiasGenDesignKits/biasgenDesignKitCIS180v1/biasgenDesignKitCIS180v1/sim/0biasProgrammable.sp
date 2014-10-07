$ simulation settings for testing biasProgrammable
.options accurate=1 gmin=1e-15 gmindc=1e-15 pivtol=1e-15 deftables=0 mosparasitics=1 numnt=500
$.gridsize mos 256 256 128
.param vdd=1.8 period=1us nbits=32 rt=10ns nLoads=3
$.tran/Powerup 'period/3.1415926535' 'period*nbits*nLoads'
.include ourModels.md
vdd AVdd18 Gnd vdd
vdvdd DVdd18 AVdd18 0
vdgnd DGnd gnd 0
vpd biasPowerDown gnd 0
vnb BiasGenNBias gnd .6 $ for splitter
im biasMasterCopy gnd 10uA
MmasterCopyInput biasMasterCopy biasMasterCopy AVdd18 AVdd18 P_18_CIS_MM L=18.2u W=15.3u M=1 
+AD='15.3u*2u' PD='15.3u+2*2u' AS='15.3u*2u' PS='15.3u+2*2u' 
Vphi biasClock gnd PULSE (0 vdd 0 'rt' 'rt' 'period/2' 'period')
Venb biasLatch gnd dc 0 $ BIT ({ 31(1)  0  } pw=period rt=1n ft=1n on=vdd off=0)
Vbit d gnd dc 0 BIT  ({ 32(1) (4(1) 2(0) 1(1) 3(0) 10(0) 1 11(0)) } pw=period rt=1n ft=1n on=vdd off=0)


