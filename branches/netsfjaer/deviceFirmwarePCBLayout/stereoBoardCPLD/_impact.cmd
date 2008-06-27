loadProjectFile -file "C:\Users\raphael\jAER\deviceFirmwarePCBLayout\stereoBoardCPLD/stereoBoardCPLD.ipf"
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Program -p 1 -e -v -defaultVersion 0 
saveProjectFile -file "C:/Users/raphael/jAER/deviceFirmwarePCBLayout/stereoBoardCPLD/stereoBoardCPLD.ipf"
setMode -bs
deleteDevice -position 1
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
