rem ******************** make hex and bix files
hex2bix -i -f 0xC2 -o USBAERTCVS320.iic USBAERTCVS320.hex

rem ******************** copy bix firmware download file to java package folder for integration into jar file

copy USBAERTCVS320.hex ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERTCVS320.hex
copy USBAERTCVS320.iic ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERTCVS320.iic
pause