rem This script makes the hex and bix files from the output of the Keil uVision compile of the firmware.
rem It copies the resulting hex and binary files to the right place in the java source tree so that it gets
rem archived and can be loaded by the java firmware loader class CypressFX2EEPPOM.


rem ******************** make iic and bix files from hex project output
c:\cypress\usb\bin\hex2bix -i -f 0xC2 -o USBAER_FX2.iic USBAER_FX2.hex
c:\cypress\usb\bin\hex2bix -b -R -M 8000 -o USBAER_FX2.bix USBAER_FX2.hex

rem ******************** copy bix and hex firmware download file to java package folder for integration into jar file
copy USBAER_FX2.bix ..\..\..\host\java\src\sf\net\jaer\hardwareinterface\usb\cypressfx2\USBAER_FX2LP_Retina.bix
copy USBAER_FX2.hex ..\..\..\host\java\src\sf\net\jaer\hardwareinterface\usb\cypressfx2\USBAER_FX2LP_Retina.hex

rem don't pollute these other folders now - system32/drivers copy could be used for USBIO capability of loading Cypress firmware
rem on device plugin.
rem ******************** copy hex firmware download file to driver installation dir
rem copy USBAER_FX2.hex ..\..\..\host\driverUSBIO\USBAER_FX2.hex
rem copy USBAER_FX2.hex %systemroot%\system32\drivers\USBAER_FX2.hex

rem ************** check if firmware code size is bigger than download size!!!!!!!!!  ***************