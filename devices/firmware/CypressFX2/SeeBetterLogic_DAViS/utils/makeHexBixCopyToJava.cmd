@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using .bix file format because the download definitely works with it from jAER
@echo on
C:\Cypress\USB\CY3684_EZ-USB_FX2LP_DVK\1.0\Bin\Hex2bix.exe -i -V 0x152A -P 0x841B -M 14592 -F 0xC2 -o SeeBetterLogic_DAViS.iic SeeBetterLogic_DAViS.hex
C:\Cypress\USB\CY3684_EZ-USB_FX2LP_DVK\1.0\Bin\Hex2bix.exe -b -V 0x152A -P 0x841B -R -M 14592 -o SeeBetterLogic_DAViS.bix SeeBetterLogic_DAViS.hex

@echo on

pause
