@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using .bix file format because the download definitely works with it from jAER
@echo on
hex2bix -i -M 16384 -F 0xC2 -o USBAERDVS320.iic USBAERDVS320.hex
hex2bix -b -R -M 16384 -o USBAERDVS320.bix USBAERDVS320.hex

@echo on
rem **** copying .iic (i2c) and .hex format firmware download files to java package folder for integration into jar file
copy USBAERDVS320.hex ..\..\..\host\java\src\ch\unizh\ini\hardware\dvs320\USBAERDVS320.hex
copy USBAERDVS320.iic ..\..\..\host\java\src\ch\unizh\ini\hardware\dvs320\UUSBAERDVS320.iic
copy USBAERDVS320.bix ..\..\..\host\java\src\ch\unizh\ini\hardware\dvs320\UUSBAERDVS320.bix
pause