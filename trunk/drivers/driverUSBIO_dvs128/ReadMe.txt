this folder contains a customized thesycon driver for the following cypressFX2 devices:
DVS128 retina, VID 152A, PID 8400
Cypress Blank, VID 04B4, PID 8613
 
to make your devices work with the new driver:
run the thesycon cleanup wizard and remove all the drivers it finds matching VID 0547 and PID 8801 (USBAERmini2) or 8700 (TmpDiff128)

replug the device. windows hardware installation wizard will show up and ask you for the driver. choose advanced driver installation and navigate to /CAVIAR/wp5/USBAER/INI-AE-Biasgen/driverUSBIO

if there are problems please see the jAER project http://jaer.sourceforge.net