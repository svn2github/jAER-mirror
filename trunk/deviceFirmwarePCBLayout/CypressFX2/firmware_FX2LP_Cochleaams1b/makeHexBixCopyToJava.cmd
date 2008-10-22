rem @echo off
rem ******************** make binary iic download file from hex project output and copy results to src folder for device class
@echo on
hex2bix -i -M 16384 -f 0xC2 -o firmwareFX2_Cochleaams1b.iic firmwareFX2_Cochleaams1b.hex
hex2bix  -R -M 16384 -f 0xC2 -v 0x152A -p 0x8400 -o firmwareFX2_Cochleaams1b.bix firmwareFX2_Cochleaams1b.hex
copy firmwareFX2_Cochleaams1b.hex ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\firmwareFX2_Cochleaams1b.hex
copy firmwareFX2_Cochleaams1b.iic ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\firmwareFX2_Cochleaams1b.iic
copy firmwareFX2_Cochleaams1b.bix ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\firmwareFX2_Cochleaams1b.bix
pause
