
#Begin clock constraint
define_clock -name {clockgen|CLKOP_inferred_clock} {n:clockgen|CLKOP_inferred_clock} -period 3.711 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 1.856 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|IfClockxCI} {p:USBAER_top_level|IfClockxCI} -period 4.853 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 2.426 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|PC1xSIO} {p:USBAER_top_level|PC1xSIO} -period 1.000 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 0.500 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|PC2xSIO} {p:USBAER_top_level|PC2xSIO} -period 10000000.000 -clockgroup Autoconstr_clkgroup_3 -rise 0.000 -fall 5000000.000 -route 0.000 
#End clock constraint
