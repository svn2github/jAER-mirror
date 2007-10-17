setPreference -pref AutoSignature:FALSE
setPreference -pref KeepSVF:FALSE
setPreference -pref ConcurrentMode:FALSE
setPreference -pref UseHighz:FALSE
setPreference -pref svfUseTime:FALSE
setMode -bs
setMode -bs
setCable -port auto
Identify
identifyMPM
assignFile -p 1 -file "D:/VHDL/USBAER/USBmini_stereo/USBAER_top_level.jed"
Program -p 1 -e -defaultVersion 0 
