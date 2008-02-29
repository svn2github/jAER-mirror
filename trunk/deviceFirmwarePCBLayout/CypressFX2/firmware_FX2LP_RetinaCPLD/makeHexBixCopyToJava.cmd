@echo off
rem ******************** make binary I2C download file from hex project output
@echo on
hex2bix  -R -i -f 0xC2 -v 0x5047 -p 0x8700 -o firmwareFX2_RetinaCPLD.iic firmwareFX2_RetinaCPLD.hex
pause
