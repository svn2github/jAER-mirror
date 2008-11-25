rem ******************** make hex and bix files
hex2bix -i -f 0xC2 -o USBAERmini2.iic USBAERmini2.hex

rem ******************** copy bix firmware download file to java package folder for integration into jar file

copy USBAERmini2.hex ..\..\..\host\java\src\net\sf\jaer\hardwareinterface\usb\cypressfx2\TMPdiffStereo.hex
copy USBAERmini2.iic ..\..\..\host\java\src\net\sf\jaer\hardwareinterface\usb\cypressfx2\TMPdiffStereo.iic
pause