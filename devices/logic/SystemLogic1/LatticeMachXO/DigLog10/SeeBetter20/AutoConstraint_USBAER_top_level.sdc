
#Begin clock constraint
define_clock -name {clockgen|CLKOP_inferred_clock} {n:clockgen|CLKOP_inferred_clock} -period 8.172 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 4.086 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|IfClockxCI} {p:USBAER_top_level|IfClockxCI} -period 10.867 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 5.434 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|PC1xSIO} {p:USBAER_top_level|PC1xSIO} -period 1.478 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 0.739 -route 0.000 
#End clock constraint
