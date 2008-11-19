rem @echo off
rem ******************** make binary iic download file from hex project output and copy results to src folder for device class
@echo on
hex2bix -i -M 16384 -F 0xC2 -o firmwareFX2_Cochleaams1b.iic firmwareFX2_Cochleaams1b.hex
hex2bix -b -R -M 16384 -o firmwareFX2_Cochleaams1b.bix firmwareFX2_Cochleaams1b.hex
copy firmwareFX2_Cochleaams1b.hex ..\..\..\host\java\src\sf\net\jaer\hardwareinterface\usb\cypressfx2\firmwareFX2_Cochleaams1b.hex
copy firmwareFX2_Cochleaams1b.iic ..\..\..\host\java\src\sf\net\jaer\hardwareinterface\usb\cypressfx2\firmwareFX2_Cochleaams1b.iic
copy firmwareFX2_Cochleaams1b.bix ..\..\..\host\java\src\sf\net\jaer\hardwareinterface\usb\cypressfx2\firmwareFX2_Cochleaams1b.bix

