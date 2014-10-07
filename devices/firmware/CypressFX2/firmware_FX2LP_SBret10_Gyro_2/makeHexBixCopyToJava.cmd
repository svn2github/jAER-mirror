@echo off
rem ******************** make binary I2C download file from hex project output
rem we are still using .bix file format because the download definitely works with it from jAER
@echo on
Hex2bix.exe -i -V 0x152A -P 0x840D -M 0x4000 -F 0xC2 -C 0x01 -o SBret10.iic SBret10.hex
Hex2bix.exe -b -V 0x152A -P 0x840D -M 0x4000 -o SBret10.bix SBret10.hex

@echo on

pause
