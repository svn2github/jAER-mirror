this folder contains a customized thesycon driver for the 
following cypressFX2/silabs C8051F3XX devices:

see drivers/readme.txt for global jaer VID/PID assignment table

TmpDiff128 retina, 		VID 0547, PID 8700
USBAERmini2, 			VID 0547, PID 8801
TCVS320 retina, 		VID 0547, PID 8702
USBAERmapper, 			VID 0547, PID 8900

Cypress Blank, 			VID 04B4, PID 8613   // used for blank CypressFX2 - firmeware is downloaded to RAM, which then allows writing the firmware to the EEPROM

DVS128, 				VID 152a PID 8400
DVS320, 				VID 152a PID 8401
CochleaAMS1b, 			VID 152a PID 8405
CochleaAMS1c, 			VID 152a PID 8406
cDVSTest, 				VID 152a PID 840a
SeeBetter, 				VID 152a PID 840b
ApsDvsSensor,				VID 152a PID 840d
SimpleAESequencer 		VID 152a PID 8410
DVS128_PAER 			VID 152a PID 8411

32 and 64 bit drivers are in separate folders to facilitate driver code signing.
Drivers are signed using the "iniLabs GmbH" certificate purchased from GlobalSign CA.

The VID is generally Thesycon and jAER has purchased 30 PIDs for its use.


to make your devices work with this driver:

run the thesycon cleanup wizard and remove all the drivers 
it finds matching VID 0547 and PID 8801 (USBAERmini2) or 
8700 (TmpDiff128)

replug the device. windows hardware installation wizard will 
show up and ask you for the driver. choose advanced driver 
installation and navigate to <jaer root>\drivers\windows\driverDVS_USBAERmini2 .
These drivers are signed for Windows 32 bit and 64 bit.

If there are problems please see the jAER project 
http://jaer.wiki.sourceforge.net.

If you don't want to see the New Hardware Found dialog every 
time you plug in an unprogrammed device into a new port, 
install the registry key 
ignoreRetinaSerialNumRegistryKey.reg (double click and 
confirm).
