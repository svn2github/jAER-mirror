@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using .bix file format because the download definitely works with it from jAER
@echo on
hex2bix -i -M 14592 -F 0xC2 -o cDVSTest.iic cDVSTest.hex
hex2bix -b -R -M 14592 -o cDVSTest.bix cDVSTest.hex

@echo on

pause