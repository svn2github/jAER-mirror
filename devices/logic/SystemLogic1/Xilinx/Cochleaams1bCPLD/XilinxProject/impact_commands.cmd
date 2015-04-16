setMode -bs
setCable -port xsvf -file "Cochleaams1bCPLD.xsvf"
addDevice -p 1 -file "usbaer_top_level.jed"
Program -p 1 -e -v 
exit