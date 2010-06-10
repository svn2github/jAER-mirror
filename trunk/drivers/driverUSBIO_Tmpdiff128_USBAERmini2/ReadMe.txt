this folder contains a customized thesycon driver for the 
following cypressFX2/silabs C8051F3XX devices:

TmpDiff128 retina, VID 0547, PID 8700
USBAERmini2, VID 0547, PID 8801
TCVS320 retina, VIC 0547, PID 8702
USBAERmapper, VID 0547, PID 8900
Cypress Blank, VID 04B4, PID 8613   // used for blank CypressFX2 - firmeware is downloaded to RAM, which then allows writing the firmware to the EEPROM
DVS128, VID 152a PID 8400
SimpleAESequencer VID 152a PID 8410
CochleaAMS1b, VID 152a PID 8405

32 and 64 bit drivers are in separate folders to facilitate driver code signing.
Drivers are signed using the "iniLabs GmbH" certificate purchased from GlobalSign CA.


to make your devices work with this driver:

run the thesycon cleanup wizard and remove all the drivers 
it finds matching VID 0547 and PID 8801 (USBAERmini2) or 
8700 (TmpDiff128)

replug the device. windows hardware installation wizard will 
show up and ask you for the driver. choose advanced driver 
installation and navigate to /CAVIAR/wp5/USBAER/INI-AE-
Biasgen/driverUSBIO

if there are problems please see the jAER project 
http://jaer.wiki.sourceforge.net.

If you don't want to see the New Hardware Found dialog every 
time you plug in an unprogrammed device into a new port, 
install the registry key 
ignoreRetinaSerialNumRegistryKey.reg (double click and 
confirm).
