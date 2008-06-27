@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using deprecated .bix file format because the download definitely works with it from jAER
@echo on
rem hex2bix  -R -i -f 0xC2 -v 0x5047 -p 0x8702 -o USBAERTCVS320.iic USBAERTCVS320.hex
hex2bix -b -R -M 8000 -o USBAERTCVS320.bix USBAERTCVS320.hex

@echo on
rem **** copying .iic (i2c) and .hex format firmware download files to java package folder for integration into jar file
copy USBAERTCVS320.hex ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERTCVS320.hex
copy USBAERTCVS320.bix ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERTCVS320.bix
pause