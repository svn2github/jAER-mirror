@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using .bix file format because the download definitely works with it from jAER
@echo on
C:\Cypress\USB\CY3684_EZ-USB_FX2LP_DVK\1.0\Bin\Hex2bix.exe -i -V 0x152A -P 0x841C -M 0x4000 -F 0xC2 -C 0x01 -o SeeBetterLogic_DVS128.iic SeeBetterLogic_DVS128.hex
C:\Cypress\USB\CY3684_EZ-USB_FX2LP_DVK\1.0\Bin\Hex2bix.exe -b -V 0x152A -P 0x841C -M 0x4000 -o SeeBetterLogic_DVS128.bix SeeBetterLogic_DVS128.hex

@echo on

pause
