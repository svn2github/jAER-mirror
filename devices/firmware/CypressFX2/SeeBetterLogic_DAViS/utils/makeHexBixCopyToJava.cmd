@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using .bix file format because the download definitely works with it from jAER
@echo on
hex2bix -i -M 14592 -F 0xC2 -o ../SeeBetterFX2.iic ../SeeBetterFX2.hex
hex2bix -b -R -M 14592 -o ../SeeBetterFX2.bix ../SeeBetterFX2.hex

@echo on

pause
