rem ******************** make hex and bix files
hex2bix -i -f 0xC2 -v 0x5047 -p 0x8702 -o USBAERTCVS320.iic USBAERTCVS320.hex

rem **** copying .iic (i2c) and .hex format firmware download files to java package folder for integration into jar file

copy USBAERTCVS320.hex ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERTCVS320.hex
copy USBAERTCVS320.iic ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERTCVS320.iic
pause