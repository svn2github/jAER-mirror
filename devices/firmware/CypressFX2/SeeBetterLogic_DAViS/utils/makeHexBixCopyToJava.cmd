@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using .bix file format because the download definitely works with it from jAER
@echo on
C:\Cypress\USB\CY3684_EZ-USB_FX2LP_DVK\1.0\Bin\Hex2bix.exe -i -M 14592 -F 0xC2 -o SeeBetterFX2.iic SeeBetterFX2.hex
C:\Cypress\USB\CY3684_EZ-USB_FX2LP_DVK\1.0\Bin\Hex2bix.exe -b -R -M 14592 -o SeeBetterFX2.bix SeeBetterFX2.hex

@echo on

pause
