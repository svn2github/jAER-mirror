rem ******************** make hex and bix files
hex2bix -i -M 16000 -f 0xC2 -o USBAERmini2.iic USBAERmini2.hex

rem ******************** copy bix firmware download file to java package folder for integration into jar file

copy USBAERmini2.hex ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERmini2_JTAG.hex
copy USBAERmini2.iic ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERmini2_JTAG.iic
pause