setMode -bs
setCable -port xsvf -file "USBAERmini2.xsvf"
addDevice -p 1 -file "usbaer_top_level.jed"
Program -p 1 -e -v 
exit