
#Begin clock constraint
define_clock -name {PLL_80_60|OutClock_CO_inferred_clock} {n:PLL_80_60|OutClock_CO_inferred_clock} -period 23.252 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 11.626 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {PLL_80_30|OutClock_CO_inferred_clock} {n:PLL_80_30|OutClock_CO_inferred_clock} -period 4.645 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 2.322 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {TopLevel|USBClock_CI} {p:TopLevel|USBClock_CI} -period 4.613 -clockgroup Autoconstr_clkgroup_2 -rise 0.000 -fall 2.306 -route 0.000 
#End clock constraint
