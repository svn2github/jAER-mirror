rem ******************** make hex and bix files
hex2bix -b -R -M 8000 -o USBAERmini2.bix USBAERmini2.hex
hex2bix -i -f 0xC2 -o USBAERmini2.iic USBAERmini2.hex

rem ******************** copy bix firmware download file to java package folder for integration into jar file

copy USBAERmini2.bix ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERmini2.bix
copy USBAERmini2.hex ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERmini2.hex
copy USBAERmini2.iic ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\USBAERmini2.iic