rem @echo off
rem ******************** make binary iic download file from hex project output and copy results to src folder for device class
@echo on
hex2bix  -R -f 0xC2 -v 0x152A -p 0x8400 -o firmwareFX2_RetinaCPLD.bix firmwareFX2_RetinaCPLD.hex
hex2bix -i -M 16384 -f 0xC2 -o firmwareFX2_RetinaCPLD.iic firmwareFX2_RetinaCPLD.hex
copy firmwareFX2_RetinaCPLD.hex ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\firmwareFX2_RetinaCPLD_JTAG.hex
copy firmwareFX2_RetinaCPLD.bix ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\firmwareFX2_RetinaCPLD_JTAG.bix
copy firmwareFX2_RetinaCPLD.iic ..\..\..\host\java\src\ch\unizh\ini\caviar\hardwareinterface\usb\firmwareFX2_RetinaCPLD_JTAG.iic
pause
