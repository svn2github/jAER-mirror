
#Begin clock constraint
define_clock -name {clockgen|CLKOP_inferred_clock} {n:clockgen|CLKOP_inferred_clock} -period 7.777 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 3.889 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|IfClockxCI} {p:USBAER_top_level|IfClockxCI} -period 807.713 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 403.857 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|PC1xSIO} {p:USBAER_top_level|PC1xSIO} -period 1.478 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 0.739 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {USBAER_top_level|PC2xSIO} {p:USBAER_top_level|PC2xSIO} -period 10000000.000 -clockgroup Autoconstr_clkgroup_3 -rise 0.000 -fall 5000000.000 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {ADCStateMachine|StateColxDP_derived_clock[11]} {n:ADCStateMachine|StateColxDP_derived_clock[11]} -period 16154.267 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 8077.134 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {ADCStateMachine|StateRowxDP_derived_clock[5]} {n:ADCStateMachine|StateRowxDP_derived_clock[5]} -period 16154.267 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 8077.134 -route 0.000 
#End clock constraint
