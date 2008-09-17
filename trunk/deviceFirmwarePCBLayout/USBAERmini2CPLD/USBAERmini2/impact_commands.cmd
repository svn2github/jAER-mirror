setMode -bs
setCable -port xsvf -file "usbaer_top_level.xsvf"
addDevice -p 1 -file "usbaer_top_level.jed"
Program -p 1 -e -v 
exit