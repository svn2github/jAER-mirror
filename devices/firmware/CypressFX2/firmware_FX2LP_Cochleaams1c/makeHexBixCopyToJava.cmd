rem @echo off
rem ******************** make binary iic download file from hex project output and copy results to src folder for device class
@echo on
hex2bix -i -M 16384 -F 0xC2 -o firmwareFX2_Cochleaams1c.iic firmwareFX2_Cochleaams1c.hex
hex2bix -b -R -M 16384 -o firmwareFX2_Cochleaams1c.bix firmwareFX2_Cochleaams1c.hex
copy firmwareFX2_Cochleaams1c.hex ..\..\..\host\java\src\net\sf\jaer\hardwareinterface\usb\cypressfx2\firmwareFX2_Cochleaams1c.hex
copy firmwareFX2_Cochleaams1c.iic ..\..\..\host\java\src\net\sf\jaer\hardwareinterface\usb\cypressfx2\firmwareFX2_Cochleaams1c.iic
copy firmwareFX2_Cochleaams1c.bix ..\..\..\host\java\src\net\sf\jaer\hardwareinterface\usb\cypressfx2\firmwareFX2_Cochleaams1c.bix

